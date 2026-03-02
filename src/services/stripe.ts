import Stripe from 'stripe';
import * as admin from 'firebase-admin';
import { trackPurchase, trackInitiateCheckout } from './meta-conversions';
import { sendWelcomeEmail } from './email';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16',
});

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

type PlanType = 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';

/**
 * Detect plan type from Stripe price interval
 */
function detectPlanFromPrice(price: Stripe.Price, metadata?: Stripe.Metadata | null): PlanType {
  // Use metadata if available (from API checkout)
  if (metadata?.plan) {
    return metadata.plan as PlanType;
  }

  // Detect from price interval (for Payment Links)
  const interval = price.recurring?.interval;
  const intervalCount = price.recurring?.interval_count || 1;

  if (interval === 'day') {
    return 'daily';
  } else if (interval === 'week') {
    return 'weekly';
  } else if (interval === 'month') {
    if (intervalCount === 3) {
      return 'quarterly';
    }
    return 'monthly';
  } else if (interval === 'year') {
    return 'yearly';
  }

  return 'monthly'; // default
}

interface CreateCheckoutSessionParams {
  priceId: string;
  plan: 'monthly' | 'quarterly' | 'yearly';
  userId: string;
  userEmail: string;
}

interface CreateCheckoutRedirectParams {
  priceId: string;
  plan: PlanType;
  email: string;
  name?: string;
  successUrl?: string;
  cancelUrl?: string;
}

interface CheckoutRedirectResult {
  url: string;
  sessionId: string;
  customerId: string;
}

/**
 * Create Stripe Checkout Session for redirect flow (public, no auth required)
 * IMMEDIATE CHARGE - No trial period
 * Used for funnel checkout with lead capture before redirect
 */
export async function createCheckoutRedirect(
  params: CreateCheckoutRedirectParams
): Promise<CheckoutRedirectResult> {
  const { priceId, plan, email, name, successUrl, cancelUrl } = params;

  const normalizedEmail = email.toLowerCase().trim();

  // Get or create customer
  let customer: Stripe.Customer;
  const existingCustomers = await stripe.customers.list({
    email: normalizedEmail,
    limit: 1,
  });

  if (existingCustomers.data.length > 0) {
    customer = existingCustomers.data[0];

    // Check if customer already has active subscription
    const existingSubscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'active',
      limit: 1,
    });

    if (existingSubscriptions.data.length > 0) {
      console.log('⚠️ Cliente já tem subscription ativa:', normalizedEmail);
      throw new Error('Este email já possui uma assinatura ativa. Faça login para acessar.');
    }

    // Also check for trialing subscriptions
    const trialingSubscriptions = await stripe.subscriptions.list({
      customer: customer.id,
      status: 'trialing',
      limit: 1,
    });

    if (trialingSubscriptions.data.length > 0) {
      console.log('⚠️ Cliente já tem trial ativo:', normalizedEmail);
      throw new Error('Este email já possui um período de teste ativo. Faça login para acessar.');
    }

    // Update name if provided and customer doesn't have one
    if (name && !customer.name) {
      await stripe.customers.update(customer.id, { name });
    }
  } else {
    // Create new customer
    customer = await stripe.customers.create({
      email: normalizedEmail,
      name: name || undefined,
      metadata: { source: 'funnel_checkout_redirect' },
    });
  }

  // Get price details for tracking
  const price = await stripe.prices.retrieve(priceId);
  const amount = price.unit_amount || 0;

  const frontendUrl = process.env.FUNNEL_URL || 'https://funis-desenrola.web.app';
  const appUrl = process.env.FRONTEND_URL || 'https://app.desenrolaai.site';

  // Create checkout session - IMMEDIATE CHARGE (no trial)
  const session = await stripe.checkout.sessions.create({
    customer: customer.id,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    // Redirect to app success page after payment
    success_url: successUrl || `${appUrl}/success?session_id={CHECKOUT_SESSION_ID}&email=${encodeURIComponent(normalizedEmail)}`,
    cancel_url: cancelUrl || `${frontendUrl}/checkout?cancelled=true`,
    metadata: {
      plan,
      email: normalizedEmail,
      name: name || '',
      source: 'funnel_checkout_redirect',
    },
    subscription_data: {
      metadata: {
        plan,
        source: 'funnel_checkout_redirect',
      },
      // NO trial_period_days - immediate charge
    },
    allow_promotion_codes: true,
    locale: 'pt-BR',
    // Pre-fill customer email
    customer_update: {
      address: 'auto',
      name: 'auto',
    },
  });

  console.log('💳 Stripe Checkout redirect session created:', {
    sessionId: session.id,
    customerId: customer.id,
    plan,
    priceId,
    amount: amount / 100,
    email: normalizedEmail,
  });

  // Track InitiateCheckout on Meta Conversions API
  trackInitiateCheckout({
    email: normalizedEmail,
    value: amount / 100,
    currency: price.currency || 'brl',
    eventId: `ic_redirect_${session.id}`,
    plan,
  }).catch(err => console.error('Meta InitiateCheckout tracking error:', err));

  return {
    url: session.url!,
    sessionId: session.id,
    customerId: customer.id,
  };
}

interface CreateEmbeddedCheckoutParams {
  priceId: string;
  plan: PlanType;
  email: string;
  name?: string;
  paymentMethodId?: string; // Pre-validated payment method from frontend
}

interface EmbeddedCheckoutResult {
  clientSecret?: string;
  subscriptionId: string;
  customerId: string;
  amount: number;
  currency: string;
  success?: boolean; // True if payment method was already attached
}

/**
 * Create embedded checkout (subscription with validated payment method)
 * REQUIRES paymentMethodId - card must be validated on frontend first
 * Uses PRE-AUTHORIZATION to validate card has sufficient funds before starting trial
 */
export async function createEmbeddedCheckout(
  params: CreateEmbeddedCheckoutParams
): Promise<EmbeddedCheckoutResult> {
  const { priceId, plan, email, name, paymentMethodId } = params;

  // SECURITY: Require paymentMethodId - never create subscription without validated card
  if (!paymentMethodId) {
    throw new Error('Payment method is required. Please fill in your card details.');
  }

  // ═══════════════════════════════════════════════════════════════════
  // PASSO 1: Validar o PaymentMethod ANTES de criar qualquer coisa
  // ═══════════════════════════════════════════════════════════════════
  console.log('🔍 Validando payment method antes de criar customer...');

  // Verificar se o PaymentMethod existe e é válido
  let paymentMethod: Stripe.PaymentMethod;
  try {
    paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
    if (!paymentMethod || !paymentMethod.card) {
      throw new Error('Cartão inválido. Por favor, tente novamente.');
    }
    console.log('✅ PaymentMethod válido:', paymentMethod.id, paymentMethod.card.brand, paymentMethod.card.last4);
  } catch (error: any) {
    console.error('❌ PaymentMethod inválido:', error.message);
    throw new Error('Dados do cartão inválidos. Por favor, verifique e tente novamente.');
  }

  // Get price details (antes de criar customer)
  const price = await stripe.prices.retrieve(priceId);
  const amount = price.unit_amount || 0;

  // ═══════════════════════════════════════════════════════════════════
  // PASSO 2: Verificar se já existe customer com subscription ativa
  // (sem criar novo customer ainda)
  // ═══════════════════════════════════════════════════════════════════
  const existingCustomers = await stripe.customers.list({
    email,
    limit: 1,
  });

  if (existingCustomers.data.length > 0) {
    const existingCustomer = existingCustomers.data[0];

    // Check if customer already has active subscription
    const existingSubscriptions = await stripe.subscriptions.list({
      customer: existingCustomer.id,
      status: 'active',
      limit: 1,
    });

    if (existingSubscriptions.data.length > 0) {
      console.log('⚠️ Cliente já tem subscription ativa:', email);
      throw new Error('Este email já possui uma assinatura ativa. Faça login para acessar.');
    }

    // Also check for trialing subscriptions
    const trialingSubscriptions = await stripe.subscriptions.list({
      customer: existingCustomer.id,
      status: 'trialing',
      limit: 1,
    });

    if (trialingSubscriptions.data.length > 0) {
      console.log('⚠️ Cliente já tem trial ativo:', email);
      throw new Error('Este email já possui um período de teste ativo. Faça login para acessar.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PASSO 3: Fazer PRÉ-AUTORIZAÇÃO sem customer (usando apenas o PM)
  // Isso valida que o cartão tem saldo ANTES de criar o customer
  // ═══════════════════════════════════════════════════════════════════
  console.log('🔒 Criando pré-autorização para validar saldo do cartão...');

  let paymentIntent: Stripe.PaymentIntent;
  try {
    paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: price.currency || 'brl',
      payment_method: paymentMethodId,
      capture_method: 'manual', // PRÉ-AUTORIZAÇÃO - não cobra, só reserva
      confirm: true,
      metadata: {
        type: 'pre_authorization',
        plan,
        priceId,
        email,
      },
    });
  } catch (error: any) {
    console.error('❌ Pré-autorização falhou:', error.message);
    // Erros específicos de cartão - NÃO criamos customer se falhar aqui
    if (error.code === 'card_declined' || error.decline_code === 'insufficient_funds') {
      throw new Error('Cartão sem saldo suficiente. Por favor, tente outro cartão.');
    }
    if (error.code === 'card_declined') {
      throw new Error('Cartão recusado. Verifique os dados ou tente outro cartão.');
    }
    throw new Error(error.message || 'Erro ao validar cartão. Tente novamente.');
  }

  // Verificar se a pré-autorização foi aprovada
  if (paymentIntent.status !== 'requires_capture') {
    console.error('❌ Pré-autorização não aprovada, status:', paymentIntent.status);
    try {
      await stripe.paymentIntents.cancel(paymentIntent.id);
    } catch (e) {
      // Ignorar erro no cancelamento
    }
    throw new Error('Cartão sem saldo suficiente. Por favor, tente outro cartão.');
  }

  console.log('✅ Pré-autorização aprovada! Cartão tem saldo. PaymentIntent:', paymentIntent.id);

  // ═══════════════════════════════════════════════════════════════════
  // PASSO 4: AGORA sim, criar ou usar customer existente
  // Só chegamos aqui se o cartão foi validado com sucesso
  // ═══════════════════════════════════════════════════════════════════
  console.log('👤 Cartão validado! Criando/atualizando customer...');

  let customer: Stripe.Customer;
  if (existingCustomers.data.length > 0) {
    customer = existingCustomers.data[0];
  } else {
    customer = await stripe.customers.create({
      email,
      name: name || undefined,
      metadata: { source: 'embedded_checkout' },
    });
  }

  console.log('💳 Attaching payment method to customer:', customer.id);

  // Attach payment method to customer
  await stripe.paymentMethods.attach(paymentMethodId, {
    customer: customer.id,
  });

  // Set as default payment method
  await stripe.customers.update(customer.id, {
    invoice_settings: {
      default_payment_method: paymentMethodId,
    },
  });

  // ═══════════════════════════════════════════════════════════════════
  // CRIAR SUBSCRIPTION: Agora que sabemos que o cartão tem saldo
  // ═══════════════════════════════════════════════════════════════════
  const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: priceId }],
    // Sem trial - cobrança imediata
    default_payment_method: paymentMethodId,
    metadata: {
      plan,
      source: 'embedded_checkout',
      preAuthPaymentIntentId: paymentIntent.id,
    },
  });

  // ═══════════════════════════════════════════════════════════════════
  // CANCELAR PRÉ-AUTORIZAÇÃO: Liberar o valor reservado no cartão
  // O objetivo era só validar que o cartão tem saldo
  // A cobrança real será feita pela subscription após o trial
  // ═══════════════════════════════════════════════════════════════════
  console.log('🔓 Liberando pré-autorização (valor reservado)...');
  try {
    await stripe.paymentIntents.cancel(paymentIntent.id);
    console.log('✅ Pré-autorização cancelada, valor liberado no cartão');
  } catch (cancelError) {
    console.warn('⚠️ Não foi possível cancelar pré-autorização:', cancelError);
    // Não é crítico - a autorização expira automaticamente em 7 dias
  }

  console.log('✅ Subscription criada com cartão validado por pré-autorização:', {
    subscriptionId: subscription.id,
    customerId: customer.id,
    plan,
    amount: amount / 100,
  });

  return {
    success: true,
    subscriptionId: subscription.id,
    customerId: customer.id,
    amount: amount / 100,
    currency: price.currency || 'brl',
  };
}

/**
 * Create Stripe Checkout Session
 */
export async function createCheckoutSession(
  params: CreateCheckoutSessionParams
): Promise<Stripe.Checkout.Session> {
  const { priceId, plan, userId, userEmail } = params;

  // Get or create Stripe customer
  let customer: Stripe.Customer | undefined;

  // Try to find existing customer by email
  const existingCustomers = await stripe.customers.list({
    email: userEmail,
    limit: 1,
  });

  if (existingCustomers.data.length > 0) {
    customer = existingCustomers.data[0];
  } else {
    // Create new customer
    customer = await stripe.customers.create({
      email: userEmail,
      metadata: {
        userId,
      },
    });
  }

  // Get price details for tracking
  const price = await stripe.prices.retrieve(priceId);
  const amount = price.unit_amount || 0;

  // Create checkout session
  const session = await stripe.checkout.sessions.create({
    customer: customer.id,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    success_url: `${process.env.FRONTEND_URL || 'http://localhost:5000'}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.FRONTEND_URL || 'http://localhost:5000'}/subscription/cancelled`,
    metadata: {
      userId,
      plan,
    },
    subscription_data: {
      metadata: {
        userId,
        plan,
      },
    },
    allow_promotion_codes: true, // Allow discount codes
    billing_address_collection: 'required',
  });

  // Track InitiateCheckout on Meta Conversions API (server-side)
  trackInitiateCheckout({
    email: userEmail,
    value: amount / 100, // Convert from cents to BRL
    currency: price.currency || 'brl',
    eventId: `ic_${session.id}`,
    plan,
  }).catch(err => console.error('Meta InitiateCheckout tracking error:', err));

  return session;
}

/**
 * Create Stripe Customer Portal Session
 * Allows users to manage their subscription
 */
export async function createCustomerPortalSession(
  customerId: string,
  returnUrl: string
): Promise<Stripe.BillingPortal.Session> {
  const portalConfig = process.env.STRIPE_PORTAL_CONFIG_ID;

  const sessionParams: Stripe.BillingPortal.SessionCreateParams = {
    customer: customerId,
    return_url: returnUrl,
  };

  // Only add configuration if it's set
  if (portalConfig) {
    sessionParams.configuration = portalConfig;
  }

  const session = await stripe.billingPortal.sessions.create(sessionParams);

  return session;
}

/**
 * Cancel subscription
 */
export async function cancelSubscription(
  subscriptionId: string
): Promise<Stripe.Subscription> {
  const subscription = await stripe.subscriptions.cancel(subscriptionId);
  return subscription;
}

/**
 * Get subscription details
 */
export async function getSubscription(
  subscriptionId: string
): Promise<Stripe.Subscription> {
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  return subscription;
}

// ═══════════════════════════════════════════════════════════════════
// WEBHOOK HANDLERS
// ═══════════════════════════════════════════════════════════════════

/**
 * Verify and construct Stripe webhook event
 */
export function constructWebhookEvent(
  payload: Buffer,
  signature: string
): Stripe.Event {
  return stripe.webhooks.constructEvent(payload, signature, webhookSecret);
}

/**
 * Handle checkout.session.completed event
 */
export async function handleCheckoutCompleted(
  session: Stripe.Checkout.Session
): Promise<void> {
  console.log('✅ Checkout completed:', session.id);

  const customerEmail = session.customer_email || session.customer_details?.email;
  const customerId = session.customer as string;
  const subscriptionId = session.subscription as string;

  if (!customerEmail || !subscriptionId) {
    console.error('❌ Missing customer email or subscription ID');
    return;
  }

  // Get subscription details
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const price = subscription.items.data[0].price;
  const priceId = price.id;
  const amount = price.unit_amount || 0;
  const currency = price.currency;

  // Determine plan from price interval (works for Payment Links too)
  const plan = detectPlanFromPrice(price, session.metadata);
  console.log(`📋 Detected plan: ${plan} (interval: ${price.recurring?.interval}, count: ${price.recurring?.interval_count})`);

  const db = admin.firestore();

  // Find user by email
  const usersSnapshot = await db
    .collection('users')
    .where('email', '==', customerEmail)
    .limit(1)
    .get();

  let userId: string;

  let isNewUser = false;

  if (usersSnapshot.empty) {
    // Create user in Firebase Auth if doesn't exist
    console.log('👤 Creating new user for email:', customerEmail);
    isNewUser = true;

    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(customerEmail);
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        userRecord = await admin.auth().createUser({
          email: customerEmail,
          displayName: session.customer_details?.name || 'Usuário',
          emailVerified: true,
        });
      } else {
        throw error;
      }
    }

    userId = userRecord.uid;

    // Create user document
    await db.collection('users').doc(userId).set({
      email: customerEmail,
      name: session.customer_details?.name || 'Usuário',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      needsPasswordSetup: true,
      subscription: {
        status: 'active',
        plan,
        stripeCustomerId: customerId,
        stripeSubscriptionId: subscriptionId,
        stripePriceId: priceId,
        amount: amount / 100,
        currency,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(subscription.current_period_end * 1000)
        ),
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    });

    // Generate password reset link and send email
    try {
      const resetLink = await admin.auth().generatePasswordResetLink(customerEmail, {
        url: `${process.env.FRONTEND_URL || 'https://desenrola-ia.web.app'}/login`,
      });
      console.log('🔑 Password reset link generated for:', customerEmail);

      // TODO: Send email with resetLink using your email service
      // For now, user can request it from the success page
    } catch (error) {
      console.error('❌ Error generating password reset link:', error);
    }
  } else {
    userId = usersSnapshot.docs[0].id;

    // Update existing user subscription
    await db.collection('users').doc(userId).update({
      'subscription.status': 'active',
      'subscription.plan': plan,
      'subscription.stripeCustomerId': customerId,
      'subscription.stripeSubscriptionId': subscriptionId,
      'subscription.stripePriceId': priceId,
      'subscription.amount': amount / 100,
      'subscription.currency': currency,
      'subscription.expiresAt': admin.firestore.Timestamp.fromDate(
        new Date(subscription.current_period_end * 1000)
      ),
      'subscription.startedAt': admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log(`✅ Subscription activated for ${customerEmail}:`, {
    userId,
    plan,
    subscriptionId,
    expiresAt: new Date(subscription.current_period_end * 1000),
  });

  // Track purchase on Meta Conversions API
  await trackPurchase({
    email: customerEmail,
    value: amount / 100,
    currency: currency.toUpperCase(),
    eventId: `purchase_${session.id}`,
    plan,
  });

  // Send welcome email with account setup link
  if (isNewUser) {
    const customerName = session.customer_details?.name || '';
    sendWelcomeEmail({
      to: customerEmail,
      name: customerName,
      plan,
    }).catch(err => console.error('❌ Erro ao enviar email de boas-vindas:', err));
  }
}

/**
 * Handle customer.subscription.updated event
 * Also handles embedded checkout activation (when status changes to 'active')
 */
export async function handleSubscriptionUpdated(
  subscription: Stripe.Subscription
): Promise<void> {
  console.log('🔄 Subscription updated:', subscription.id, 'status:', subscription.status);

  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) {
    console.error('❌ Customer not found');
    return;
  }

  const email = (customer as Stripe.Customer).email;
  const customerName = (customer as Stripe.Customer).name;

  if (!email) {
    console.error('❌ Customer email not found');
    return;
  }

  // Skip temporary/placeholder emails from incomplete checkouts
  if (email === 'pending@checkout.temp' || email.endsWith('@checkout.temp')) {
    console.log('⏭️ Skipping temporary email:', email);
    return;
  }

  const db = admin.firestore();
  const status = subscription.status;

  // Validate current_period_end is a valid timestamp
  const periodEnd = subscription.current_period_end;
  if (!periodEnd || typeof periodEnd !== 'number' || !Number.isInteger(periodEnd)) {
    console.error('❌ Invalid current_period_end:', periodEnd);
    return;
  }
  const expiresAt = admin.firestore.Timestamp.fromDate(new Date(periodEnd * 1000));

  // For embedded checkout: create user if subscription becomes active and user doesn't exist
  if (status === 'active') {
    const usersSnapshot = await db
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    const price = subscription.items.data[0].price;
    const priceId = price.id;
    const amount = price.unit_amount || 0;
    const currency = price.currency;
    const plan = detectPlanFromPrice(price, subscription.metadata);

    if (usersSnapshot.empty) {
      // User doesn't exist - create them (embedded checkout flow)
      console.log('👤 Creating new user from subscription.updated for:', email);

      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(email);
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          userRecord = await admin.auth().createUser({
            email: email,
            displayName: customerName || 'Usuário',
            emailVerified: true,
          });
        } else {
          throw error;
        }
      }

      const userId = userRecord.uid;

      // Create user document with active subscription
      await db.collection('users').doc(userId).set({
        email: email,
        name: customerName || 'Usuário',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        needsPasswordSetup: true,
        subscription: {
          status: 'active',
          plan,
          stripeCustomerId: customerId,
          stripeSubscriptionId: subscription.id,
          stripePriceId: priceId,
          amount: amount / 100,
          currency,
          expiresAt,
          startedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });

      console.log(`✅ User created and subscription activated for ${email}:`, {
        userId,
        plan,
        subscriptionId: subscription.id,
        expiresAt: new Date(periodEnd * 1000),
      });

      // Track purchase on Meta Conversions API
      trackPurchase({
        email: email,
        value: amount / 100,
        currency: currency.toUpperCase(),
        eventId: `purchase_sub_${subscription.id}`,
        plan,
      }).catch(err => console.error('Meta Purchase tracking error:', err));

      // Send welcome email with account setup link
      sendWelcomeEmail({
        to: email,
        name: customerName || undefined,
        plan,
      }).catch(err => console.error('❌ Erro ao enviar email de boas-vindas:', err));

    } else {
      // User exists - update their subscription
      const userId = usersSnapshot.docs[0].id;

      await db.collection('users').doc(userId).update({
        'subscription.status': 'active',
        'subscription.plan': plan,
        'subscription.stripeCustomerId': customerId,
        'subscription.stripeSubscriptionId': subscription.id,
        'subscription.stripePriceId': priceId,
        'subscription.amount': amount / 100,
        'subscription.currency': currency,
        'subscription.expiresAt': expiresAt,
      });

      console.log(`✅ Subscription updated for user ${userId} (${email})`);
    }
  } else if (status === 'canceled' || status === 'unpaid') {
    const usersSnapshot = await db
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      const userId = usersSnapshot.docs[0].id;
      await db.collection('users').doc(userId).update({
        'subscription.status': 'cancelled',
        'subscription.cancelledAt': admin.firestore.FieldValue.serverTimestamp(),
        'subscription.cancelReason': `Subscription ${status}`,
      });
    }
  }
}

/**
 * Handle customer.subscription.deleted event
 */
export async function handleSubscriptionDeleted(
  subscription: Stripe.Subscription
): Promise<void> {
  console.log('❌ Subscription deleted:', subscription.id);

  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  const db = admin.firestore();
  const usersSnapshot = await db
    .collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();

  if (usersSnapshot.empty) return;

  const userId = usersSnapshot.docs[0].id;

  await db.collection('users').doc(userId).update({
    'subscription.status': 'cancelled',
    'subscription.cancelledAt': admin.firestore.FieldValue.serverTimestamp(),
    'subscription.cancelReason': 'Subscription cancelled by user',
  });

  console.log(`🔴 Subscription cancelled for user ${userId}`);
}

/**
 * Handle invoice.paid event (renewal)
 */
export async function handleInvoicePaid(
  invoice: Stripe.Invoice
): Promise<void> {
  console.log('💰 Invoice paid:', invoice.id);

  const subscriptionId = invoice.subscription as string;
  if (!subscriptionId) return;

  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  const db = admin.firestore();
  const usersSnapshot = await db
    .collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();

  if (usersSnapshot.empty) return;

  const userId = usersSnapshot.docs[0].id;
  const price = subscription.items.data[0].price;
  const priceId = price.id;
  const amount = price.unit_amount || 0;
  const currency = price.currency;
  const plan = detectPlanFromPrice(price, subscription.metadata);

  await db.collection('users').doc(userId).update({
    'subscription.status': 'active',
    'subscription.plan': plan,
    'subscription.stripePriceId': priceId,
    'subscription.amount': amount / 100,
    'subscription.currency': currency,
    'subscription.expiresAt': admin.firestore.Timestamp.fromDate(
      new Date(subscription.current_period_end * 1000)
    ),
  });

  console.log(`✅ Subscription renewed for user ${userId} (plan: ${plan})`);
}

/**
 * Handle invoice.payment_failed event
 */
export async function handlePaymentFailed(
  invoice: Stripe.Invoice
): Promise<void> {
  console.log('⚠️ Payment failed:', invoice.id);

  const subscriptionId = invoice.subscription as string;
  if (!subscriptionId) return;

  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  console.log(`⚠️ Payment failed for customer ${email}, Stripe will retry`);
  // Don't cancel immediately - Stripe will retry
}

// ═══════════════════════════════════════════════════════════════════
// ADMIN: WEBHOOK HEALTH & SYNC
// ═══════════════════════════════════════════════════════════════════

/**
 * Check webhook health - lists recent events and their delivery status
 */
export async function getWebhookHealth(): Promise<{
  endpoint: { id: string; url: string; status: string } | null;
  recentEvents: Array<{
    id: string;
    type: string;
    created: string;
    pending_webhooks: number;
  }>;
  summary: { total: number; types: Record<string, number> };
}> {
  // Find webhook endpoint
  const endpoints = await stripe.webhookEndpoints.list({ limit: 10 });
  const railwayEndpoint = endpoints.data.find(ep =>
    ep.url.includes('railway.app') || ep.url.includes('dating-app')
  );

  // List recent events (last 24h)
  const oneDayAgo = Math.floor(Date.now() / 1000) - 86400;
  const events = await stripe.events.list({
    created: { gte: oneDayAgo },
    limit: 50,
  });

  const typeCounts: Record<string, number> = {};
  const recentEvents = events.data.map(event => {
    typeCounts[event.type] = (typeCounts[event.type] || 0) + 1;
    return {
      id: event.id,
      type: event.type,
      created: new Date(event.created * 1000).toISOString(),
      pending_webhooks: event.pending_webhooks,
    };
  });

  return {
    endpoint: railwayEndpoint
      ? { id: railwayEndpoint.id, url: railwayEndpoint.url, status: railwayEndpoint.status }
      : null,
    recentEvents,
    summary: {
      total: events.data.length,
      types: typeCounts,
    },
  };
}

interface SyncResult {
  checked: number;
  created: number;
  updated: number;
  errors: string[];
  details: Array<{
    email: string;
    action: string;
    stripeStatus: string;
    firebaseStatus: string;
  }>;
}

/**
 * Sync subscriptions between Stripe and Firebase
 * Compares all active/trialing/past_due subscriptions in Stripe with Firebase
 * and fixes divergences
 */
export async function syncSubscriptions(dryRun: boolean = true): Promise<SyncResult> {
  const db = admin.firestore();
  const result: SyncResult = {
    checked: 0,
    created: 0,
    updated: 0,
    errors: [],
    details: [],
  };

  // Fetch all active, trialing, and past_due subscriptions from Stripe
  const statuses: Stripe.SubscriptionListParams['status'][] = ['active', 'trialing', 'past_due'];

  for (const status of statuses) {
    let hasMore = true;
    let startingAfter: string | undefined;

    while (hasMore) {
      const params: Stripe.SubscriptionListParams = {
        status,
        limit: 100,
        expand: ['data.customer'],
      };
      if (startingAfter) params.starting_after = startingAfter;

      const subscriptions = await stripe.subscriptions.list(params);

      for (const sub of subscriptions.data) {
        result.checked++;

        const customer = sub.customer as Stripe.Customer | Stripe.DeletedCustomer;
        if (!customer || ('deleted' in customer && customer.deleted) || !('email' in customer) || !customer.email) {
          result.errors.push(`Subscription ${sub.id}: customer sem email`);
          continue;
        }

        const email = customer.email;
        const price = sub.items.data[0]?.price;
        if (!price) {
          result.errors.push(`Subscription ${sub.id}: sem price`);
          continue;
        }

        const plan = detectPlanFromPrice(price, sub.metadata);
        const amount = price.unit_amount || 0;
        const currency = price.currency;
        const expiresAt = admin.firestore.Timestamp.fromDate(
          new Date(sub.current_period_end * 1000)
        );

        // Find user in Firebase
        const usersSnapshot = await db
          .collection('users')
          .where('email', '==', email)
          .limit(1)
          .get();

        if (usersSnapshot.empty) {
          // User exists in Stripe but not in Firebase - create
          result.details.push({
            email,
            action: dryRun ? 'WOULD_CREATE' : 'CREATED',
            stripeStatus: sub.status,
            firebaseStatus: 'not_found',
          });

          if (!dryRun) {
            try {
              let userRecord;
              try {
                userRecord = await admin.auth().getUserByEmail(email);
              } catch (error: any) {
                if (error.code === 'auth/user-not-found') {
                  userRecord = await admin.auth().createUser({
                    email,
                    displayName: customer.name || 'Usuário',
                    emailVerified: true,
                  });
                } else {
                  throw error;
                }
              }

              await db.collection('users').doc(userRecord.uid).set({
                email,
                name: customer.name || 'Usuário',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                needsPasswordSetup: true,
                subscription: {
                  status: 'active',
                  plan,
                  stripeCustomerId: customer.id,
                  stripeSubscriptionId: sub.id,
                  stripePriceId: price.id,
                  amount: amount / 100,
                  currency,
                  expiresAt,
                  startedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
              });
              result.created++;
            } catch (err: any) {
              result.errors.push(`Create ${email}: ${err.message}`);
            }
          } else {
            result.created++;
          }
        } else {
          // User exists - check if subscription status matches
          const userData = usersSnapshot.docs[0].data();
          const firebaseStatus = userData.subscription?.status || 'none';
          const firebaseSubId = userData.subscription?.stripeSubscriptionId;

          const stripeActive = sub.status === 'active' || sub.status === 'trialing';
          const firebaseActive = firebaseStatus === 'active';

          if (stripeActive && !firebaseActive) {
            // Stripe active but Firebase not active - fix Firebase
            result.details.push({
              email,
              action: dryRun ? 'WOULD_UPDATE' : 'UPDATED',
              stripeStatus: sub.status,
              firebaseStatus,
            });

            if (!dryRun) {
              try {
                await db.collection('users').doc(usersSnapshot.docs[0].id).update({
                  'subscription.status': 'active',
                  'subscription.plan': plan,
                  'subscription.stripeCustomerId': customer.id,
                  'subscription.stripeSubscriptionId': sub.id,
                  'subscription.stripePriceId': price.id,
                  'subscription.amount': amount / 100,
                  'subscription.currency': currency,
                  'subscription.expiresAt': expiresAt,
                });
                result.updated++;
              } catch (err: any) {
                result.errors.push(`Update ${email}: ${err.message}`);
              }
            } else {
              result.updated++;
            }
          }
          // If both match, no action needed
        }
      }

      hasMore = subscriptions.has_more;
      if (subscriptions.data.length > 0) {
        startingAfter = subscriptions.data[subscriptions.data.length - 1].id;
      }
    }
  }

  // Also check: Firebase users with 'active' status but no active Stripe subscription
  const activeFirebaseUsers = await db
    .collection('users')
    .where('subscription.status', '==', 'active')
    .get();

  for (const doc of activeFirebaseUsers.docs) {
    const userData = doc.data();
    const subId = userData.subscription?.stripeSubscriptionId;

    if (!subId) continue;

    try {
      const stripeSub = await stripe.subscriptions.retrieve(subId);
      if (stripeSub.status === 'canceled' || stripeSub.status === 'unpaid') {
        result.details.push({
          email: userData.email,
          action: dryRun ? 'WOULD_DEACTIVATE' : 'DEACTIVATED',
          stripeStatus: stripeSub.status,
          firebaseStatus: 'active',
        });

        if (!dryRun) {
          try {
            await db.collection('users').doc(doc.id).update({
              'subscription.status': 'cancelled',
              'subscription.cancelledAt': admin.firestore.FieldValue.serverTimestamp(),
              'subscription.cancelReason': `Sync: Stripe status is ${stripeSub.status}`,
            });
            result.updated++;
          } catch (err: any) {
            result.errors.push(`Deactivate ${userData.email}: ${err.message}`);
          }
        } else {
          result.updated++;
        }
      }
    } catch (err: any) {
      // Subscription might not exist anymore
      if (err.statusCode === 404) {
        result.details.push({
          email: userData.email,
          action: dryRun ? 'WOULD_DEACTIVATE' : 'DEACTIVATED',
          stripeStatus: 'not_found',
          firebaseStatus: 'active',
        });

        if (!dryRun) {
          try {
            await db.collection('users').doc(doc.id).update({
              'subscription.status': 'cancelled',
              'subscription.cancelledAt': admin.firestore.FieldValue.serverTimestamp(),
              'subscription.cancelReason': 'Sync: Subscription not found in Stripe',
            });
            result.updated++;
          } catch (updateErr: any) {
            result.errors.push(`Deactivate ${userData.email}: ${updateErr.message}`);
          }
        } else {
          result.updated++;
        }
      }
    }
  }

  return result;
}

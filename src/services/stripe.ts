import Stripe from 'stripe';
import * as admin from 'firebase-admin';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16',
});

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

interface CreateCheckoutSessionParams {
  priceId: string;
  plan: 'monthly' | 'yearly';
  userId: string;
  userEmail: string;
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
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  });

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
  const priceId = subscription.items.data[0].price.id;
  const amount = subscription.items.data[0].price.unit_amount || 0;
  const currency = subscription.items.data[0].price.currency;

  // Determine plan from metadata
  const plan = session.metadata?.plan as 'monthly' | 'yearly' || 'monthly';

  const db = admin.firestore();

  // Find user by email
  const usersSnapshot = await db
    .collection('users')
    .where('email', '==', customerEmail)
    .limit(1)
    .get();

  let userId: string;

  if (usersSnapshot.empty) {
    // Create user in Firebase Auth if doesn't exist
    console.log('👤 Creating new user for email:', customerEmail);

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
}

/**
 * Handle customer.subscription.updated event
 */
export async function handleSubscriptionUpdated(
  subscription: Stripe.Subscription
): Promise<void> {
  console.log('🔄 Subscription updated:', subscription.id);

  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) {
    console.error('❌ Customer not found');
    return;
  }

  const email = (customer as Stripe.Customer).email;
  if (!email) {
    console.error('❌ Customer email not found');
    return;
  }

  const db = admin.firestore();
  const usersSnapshot = await db
    .collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();

  if (usersSnapshot.empty) {
    console.error('❌ User not found for email:', email);
    return;
  }

  const userId = usersSnapshot.docs[0].id;
  const status = subscription.status;

  if (status === 'active') {
    const priceId = subscription.items.data[0].price.id;
    const amount = subscription.items.data[0].price.unit_amount || 0;
    const currency = subscription.items.data[0].price.currency;
    const plan = subscription.metadata?.plan as 'monthly' | 'yearly' || 'monthly';

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
  } else if (status === 'canceled' || status === 'unpaid') {
    await db.collection('users').doc(userId).update({
      'subscription.status': 'cancelled',
      'subscription.cancelledAt': admin.firestore.FieldValue.serverTimestamp(),
      'subscription.cancelReason': `Subscription ${status}`,
    });
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
  const priceId = subscription.items.data[0].price.id;
  const amount = subscription.items.data[0].price.unit_amount || 0;
  const currency = subscription.items.data[0].price.currency;
  const plan = subscription.metadata?.plan as 'monthly' | 'yearly' || 'monthly';

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

  console.log(`✅ Subscription renewed for user ${userId}`);
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

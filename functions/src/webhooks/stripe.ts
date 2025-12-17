import { Request, Response } from 'express';
import Stripe from 'stripe';
import { UserManager } from '../services/user-manager';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Get Stripe config from Firebase Functions config or environment variables
// Use: firebase functions:config:set stripe.secret_key="sk_..." stripe.webhook_secret="whsec_..."
const getStripeConfig = () => {
  // Try Firebase Functions config first
  try {
    const config = functions.config();
    if (config.stripe?.secret_key && config.stripe?.webhook_secret) {
      return {
        secretKey: config.stripe.secret_key,
        webhookSecret: config.stripe.webhook_secret,
      };
    }
  } catch (e) {
    // Config not available (local development)
  }

  // Fallback to environment variables
  return {
    secretKey: process.env.STRIPE_SECRET_KEY || '',
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',
  };
};

const stripeConfig = getStripeConfig();

const stripe = new Stripe(stripeConfig.secretKey, {
  apiVersion: '2023-10-16',
});

const endpointSecret = stripeConfig.webhookSecret;

/**
 * Stripe Webhook Handler
 *
 * Este endpoint recebe notificações da Stripe sobre:
 * - checkout.session.completed: Checkout finalizado (nova assinatura)
 * - customer.subscription.updated: Assinatura atualizada
 * - customer.subscription.deleted: Assinatura cancelada
 * - invoice.paid: Fatura paga (renovação)
 * - invoice.payment_failed: Falha no pagamento
 */
export async function handleStripeWebhook(req: Request, res: Response) {
  const sig = req.headers['stripe-signature'];

  if (!sig) {
    console.error('❌ Missing stripe-signature header');
    return res.status(400).send('Missing signature');
  }

  let event: Stripe.Event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      endpointSecret
    );
  } catch (err: any) {
    console.error('❌ Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('📨 Stripe webhook received:', event.type);

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      case 'invoice.paid':
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice);
        break;

      default:
        console.log(`⚠️ Unhandled event type: ${event.type}`);
    }

    return res.json({ received: true });

  } catch (error: any) {
    console.error('❌ Error processing webhook:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
}

/**
 * Handle checkout completed - new subscription created
 */
async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
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

  // Determine plan based on price ID or metadata
  const plan = determinePlan(priceId, session.metadata);

  // Get or create user
  let user = await UserManager.getUserByEmail(customerEmail);

  if (!user) {
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

    user = await UserManager.createUser(
      userRecord.uid,
      customerEmail,
      session.customer_details?.name || 'Usuário'
    );
  }

  // Activate subscription
  const currentPeriodEnd = new Date(subscription.current_period_end * 1000);

  await UserManager.activateSubscription(
    user.id,
    plan,
    subscriptionId,
    customerId,
    priceId,
    amount / 100, // Convert from cents
    currency,
    currentPeriodEnd
  );

  console.log(`✅ Subscription activated for ${customerEmail}:`, {
    plan,
    subscriptionId,
    expiresAt: currentPeriodEnd,
  });
}

/**
 * Handle subscription updated
 */
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
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

  const user = await UserManager.getUserByEmail(email);
  if (!user) {
    console.error('❌ User not found for email:', email);
    return;
  }

  const currentPeriodEnd = new Date(subscription.current_period_end * 1000);
  const status = subscription.status;

  // Update subscription status
  if (status === 'active') {
    const priceId = subscription.items.data[0].price.id;
    const amount = subscription.items.data[0].price.unit_amount || 0;
    const currency = subscription.items.data[0].price.currency;
    const plan = determinePlan(priceId, subscription.metadata);

    await UserManager.activateSubscription(
      user.id,
      plan,
      subscription.id,
      customerId,
      priceId,
      amount / 100,
      currency,
      currentPeriodEnd
    );
  } else if (status === 'canceled' || status === 'unpaid') {
    await UserManager.cancelSubscription(
      user.id,
      `Subscription ${status}`
    );
  }
}

/**
 * Handle subscription deleted/canceled
 */
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  console.log('❌ Subscription deleted:', subscription.id);

  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  const user = await UserManager.getUserByEmail(email);
  if (!user) return;

  await UserManager.cancelSubscription(
    user.id,
    'Subscription cancelled by user'
  );

  console.log(`🔴 Subscription cancelled for user ${user.id}`);
}

/**
 * Handle invoice paid - subscription renewal
 */
async function handleInvoicePaid(invoice: Stripe.Invoice) {
  console.log('💰 Invoice paid:', invoice.id);

  const subscriptionId = invoice.subscription as string;
  if (!subscriptionId) return;

  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  const user = await UserManager.getUserByEmail(email);
  if (!user) return;

  // Update expiration date
  const currentPeriodEnd = new Date(subscription.current_period_end * 1000);
  const priceId = subscription.items.data[0].price.id;
  const amount = subscription.items.data[0].price.unit_amount || 0;
  const currency = subscription.items.data[0].price.currency;
  const plan = determinePlan(priceId, subscription.metadata);

  await UserManager.activateSubscription(
    user.id,
    plan,
    subscriptionId,
    customerId,
    priceId,
    amount / 100,
    currency,
    currentPeriodEnd
  );

  console.log(`✅ Subscription renewed for user ${user.id} until ${currentPeriodEnd}`);
}

/**
 * Handle payment failed
 */
async function handlePaymentFailed(invoice: Stripe.Invoice) {
  console.log('⚠️ Payment failed:', invoice.id);

  const subscriptionId = invoice.subscription as string;
  if (!subscriptionId) return;

  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;
  const customer = await stripe.customers.retrieve(customerId);

  if (!customer || customer.deleted) return;

  const email = (customer as Stripe.Customer).email;
  if (!email) return;

  const user = await UserManager.getUserByEmail(email);
  if (!user) return;

  // Don't cancel immediately - Stripe will retry
  // Just log for now
  console.log(`⚠️ Payment failed for user ${user.id}, Stripe will retry`);

  // You can send an email notification here
}

/**
 * Determine plan type from price ID or metadata
 */
function determinePlan(
  priceId: string,
  metadata?: Stripe.Metadata | null
): 'monthly' | 'yearly' {
  // Check metadata first
  if (metadata?.plan === 'yearly') return 'yearly';
  if (metadata?.plan === 'monthly') return 'monthly';

  // Fallback: check if price ID contains 'year' or 'month'
  // You should configure this based on your actual Stripe price IDs
  if (priceId.includes('year') || priceId.includes('annual')) {
    return 'yearly';
  }

  return 'monthly';
}

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCheckoutSession = createCheckoutSession;
exports.createCustomerPortalSession = createCustomerPortalSession;
exports.cancelSubscription = cancelSubscription;
exports.getSubscription = getSubscription;
exports.constructWebhookEvent = constructWebhookEvent;
exports.handleCheckoutCompleted = handleCheckoutCompleted;
exports.handleSubscriptionUpdated = handleSubscriptionUpdated;
exports.handleSubscriptionDeleted = handleSubscriptionDeleted;
exports.handleInvoicePaid = handleInvoicePaid;
exports.handlePaymentFailed = handlePaymentFailed;

const Stripe = require("stripe");
const { supabase } = require("../config/supabase");
const { trackPurchase } = require("./meta-conversions");
const { sendWelcomeEmail } = require("./email-service");
const firebaseSync = require("./firebase-sync");

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", { apiVersion: "2023-10-16" });
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

async function createCheckoutSession(params) {
  const { priceId, plan, userId, userEmail } = params;

  let customer;
  const existingCustomers = await stripe.customers.list({ email: userEmail, limit: 1 });
  if (existingCustomers.data.length > 0) {
    customer = existingCustomers.data[0];
  } else {
    customer = await stripe.customers.create({ email: userEmail, metadata: { userId } });
  }

  const session = await stripe.checkout.sessions.create({
    customer: customer.id,
    mode: "subscription",
    payment_method_types: ["card"],
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${process.env.FRONTEND_URL || "http://localhost:5000"}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.FRONTEND_URL || "http://localhost:5000"}/subscription/cancelled`,
    metadata: { userId, plan },
    subscription_data: { metadata: { userId, plan } },
  });

  return session;
}

async function createCustomerPortalSession(customerId) {
  const portalConfigId = process.env.STRIPE_PORTAL_CONFIG_ID;
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: `${process.env.FRONTEND_URL || "http://localhost:5000"}/subscription`,
    ...(portalConfigId ? { configuration: portalConfigId } : {}),
  });
  return session;
}

async function cancelSubscription(subscriptionId) {
  return stripe.subscriptions.cancel(subscriptionId);
}

async function getSubscription(subscriptionId) {
  return stripe.subscriptions.retrieve(subscriptionId);
}

function constructWebhookEvent(rawBody, signature) {
  return stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
}

async function findUserByEmail(email) {
  const { data } = await supabase.from("users").select("*").eq("email", email).single();
  return data;
}

async function findUserByFirebaseUid(firebaseUid) {
  const { data } = await supabase.from("users").select("*").eq("firebase_uid", firebaseUid).single();
  return data;
}

async function handleCheckoutCompleted(session) {
  const subscription = await stripe.subscriptions.retrieve(session.subscription);
  const email = session.customer_details?.email || session.customer_email;
  const plan = session.metadata?.plan || "monthly";
  const userId = session.metadata?.userId;

  if (!email) {
    console.error("No email found in checkout session");
    return;
  }

  const expiresAt = new Date(subscription.current_period_end * 1000).toISOString();
  const now = new Date().toISOString();

  // Find user by firebase UID or email
  let user = userId ? await findUserByFirebaseUid(userId) : null;
  if (!user) user = await findUserByEmail(email);

  if (user) {
    await supabase
      .from("users")
      .update({
        subscription_status: "active",
        subscription_plan: plan,
        subscription_provider: "stripe",
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription,
        stripe_price_id: subscription.items.data[0]?.price?.id || null,
        subscription_amount: (subscription.items.data[0]?.price?.unit_amount || 0) / 100,
        subscription_currency: subscription.currency || "brl",
        subscription_expires_at: expiresAt,
        subscription_started_at: now,
        updated_at: now,
      })
      .eq("id", user.id);
  } else {
    // Create user via Supabase Auth
    const { data: authData } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { display_name: session.customer_details?.name || "Usuário", source: "stripe_checkout" },
    });

    const supaUid = authData?.user?.id;
    if (supaUid) {
      await supabase.from("users").upsert({
        id: supaUid,
        firebase_uid: userId || null,
        email,
        display_name: session.customer_details?.name || "Usuário",
        subscription_status: "active",
        subscription_plan: plan,
        subscription_provider: "stripe",
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription,
        stripe_price_id: subscription.items.data[0]?.price?.id || null,
        subscription_amount: (subscription.items.data[0]?.price?.unit_amount || 0) / 100,
        subscription_currency: subscription.currency || "brl",
        subscription_expires_at: expiresAt,
        subscription_started_at: now,
      });

      if (userId) {
        await supabase.from("user_id_mapping").upsert({
          firebase_uid: userId,
          supabase_uid: supaUid,
          email,
        });
      }
    }
  }

  // Dual-write subscription to Firebase (non-blocking)
  const syncUid = user ? user.id : null;
  if (syncUid) {
    firebaseSync.syncSubscription(syncUid, {
      status: "active",
      plan,
      provider: "stripe",
      stripeCustomerId: session.customer,
      stripeSubscriptionId: session.subscription,
      stripePriceId: subscription.items.data[0]?.price?.id || null,
      amount: (subscription.items.data[0]?.price?.unit_amount || 0) / 100,
      currency: subscription.currency || "brl",
      expiresAt: expiresAt,
      startedAt: now,
    });
  }

  // Track purchase (non-blocking)
  try { await trackPurchase(email, plan, subscription.currency, (subscription.items.data[0]?.price?.unit_amount || 0) / 100); } catch (e) { console.error("Track purchase error:", e.message); }
  try { await sendWelcomeEmail(email, session.customer_details?.name || ""); } catch (e) { console.error("Welcome email error:", e.message); }
}

async function handleSubscriptionUpdated(subscription) {
  const customer = await stripe.customers.retrieve(subscription.customer);
  const email = customer.email;
  if (!email) return;

  const user = await findUserByEmail(email);
  if (!user) return;

  const expiresAt = new Date(subscription.current_period_end * 1000).toISOString();

  await supabase
    .from("users")
    .update({
      subscription_status: subscription.status === "active" ? "active" : subscription.status,
      stripe_price_id: subscription.items.data[0]?.price?.id || null,
      subscription_amount: (subscription.items.data[0]?.price?.unit_amount || 0) / 100,
      subscription_currency: subscription.currency || "brl",
      subscription_expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  // Dual-write to Firebase (non-blocking)
  firebaseSync.syncSubscription(user.id, {
    status: subscription.status === "active" ? "active" : subscription.status,
    stripePriceId: subscription.items.data[0]?.price?.id || null,
    amount: (subscription.items.data[0]?.price?.unit_amount || 0) / 100,
    currency: subscription.currency || "brl",
    expiresAt: expiresAt,
  });
}

async function handleSubscriptionDeleted(subscription) {
  const customer = await stripe.customers.retrieve(subscription.customer);
  const email = customer.email;
  if (!email) return;

  const user = await findUserByEmail(email);
  if (!user) return;

  await supabase
    .from("users")
    .update({
      subscription_status: "cancelled",
      subscription_cancelled_at: new Date().toISOString(),
      subscription_cancel_reason: "Subscription cancelled",
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  // Dual-write to Firebase (non-blocking)
  firebaseSync.syncSubscription(user.id, {
    status: "cancelled",
    cancelledAt: new Date().toISOString(),
    cancelReason: "Subscription cancelled",
  });
}

async function handleInvoicePaid(invoice) {
  const email = invoice.customer_email;
  if (!email) return;

  const user = await findUserByEmail(email);
  if (!user || !invoice.subscription) return;

  const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
  const expiresAt = new Date(subscription.current_period_end * 1000).toISOString();

  await supabase
    .from("users")
    .update({
      subscription_status: "active",
      subscription_expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  // Dual-write to Firebase (non-blocking)
  firebaseSync.syncSubscription(user.id, {
    status: "active",
    expiresAt: expiresAt,
  });
}

async function handlePaymentFailed(invoice) {
  const email = invoice.customer_email;
  if (!email) return;

  console.log(`Payment failed for ${email}`);
}

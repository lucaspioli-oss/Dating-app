"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
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
const stripe_1 = __importDefault(require("stripe"));
const { supabaseAdmin } = require("../config/supabase");

const stripe = new stripe_1.default(process.env.STRIPE_SECRET_KEY || '', {
    apiVersion: '2023-10-16',
});
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

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
        mode: 'subscription',
        payment_method_types: ['card'],
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: `${process.env.FRONTEND_URL || 'http://localhost:5000'}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${process.env.FRONTEND_URL || 'http://localhost:5000'}/subscription/cancelled`,
        metadata: { userId, plan },
        subscription_data: { metadata: { userId, plan } },
        allow_promotion_codes: true,
        billing_address_collection: 'required',
    });
    return session;
}

async function createCustomerPortalSession(customerId, returnUrl) {
    return await stripe.billingPortal.sessions.create({ customer: customerId, return_url: returnUrl });
}

async function cancelSubscription(subscriptionId) {
    return await stripe.subscriptions.cancel(subscriptionId);
}

async function getSubscription(subscriptionId) {
    return await stripe.subscriptions.retrieve(subscriptionId);
}

function constructWebhookEvent(payload, signature) {
    return stripe.webhooks.constructEvent(payload, signature, webhookSecret);
}

async function handleCheckoutCompleted(session) {
    console.log('Checkout completed:', session.id);
    const customerEmail = session.customer_email || session.customer_details?.email;
    const customerId = session.customer;
    const subscriptionId = session.subscription;
    if (!customerEmail || !subscriptionId) {
        console.error('Missing customer email or subscription ID');
        return;
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const priceId = subscription.items.data[0].price.id;
    const amount = subscription.items.data[0].price.unit_amount || 0;
    const currency = subscription.items.data[0].price.currency;
    const plan = session.metadata?.plan || 'monthly';

    // Find user by email
    const { data: existingUser } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', customerEmail)
        .limit(1)
        .single();

    if (existingUser) {
        // Update existing user subscription
        await supabaseAdmin
            .from('users')
            .update({
                subscription_status: 'active',
                subscription_plan: plan,
                stripe_customer_id: customerId,
                stripe_subscription_id: subscriptionId,
                stripe_price_id: priceId,
                subscription_amount: amount / 100,
                subscription_currency: currency,
                subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
                subscription_started_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
            })
            .eq('id', existingUser.id);
    } else {
        // Create user via Supabase Auth
        let userId;
        const { data: authData } = await supabaseAdmin.auth.admin.listUsers();
        const existingAuthUser = authData?.users?.find(u => u.email === customerEmail);

        if (existingAuthUser) {
            userId = existingAuthUser.id;
        } else {
            const { data: newAuthUser, error: authErr } = await supabaseAdmin.auth.admin.createUser({
                email: customerEmail,
                email_confirm: true,
                user_metadata: { full_name: session.customer_details?.name || 'Usuario' },
            });
            if (authErr) {
                console.error('Error creating auth user:', authErr);
                return;
            }
            userId = newAuthUser.user.id;
        }

        await supabaseAdmin
            .from('users')
            .upsert({
                id: userId,
                email: customerEmail,
                display_name: session.customer_details?.name || 'Usuario',
                subscription_status: 'active',
                subscription_plan: plan,
                stripe_customer_id: customerId,
                stripe_subscription_id: subscriptionId,
                stripe_price_id: priceId,
                subscription_amount: amount / 100,
                subscription_currency: currency,
                subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
                subscription_started_at: new Date().toISOString(),
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
            });
    }

    console.log(`Subscription activated for ${customerEmail}: plan=${plan}`);
}

async function handleSubscriptionUpdated(subscription) {
    console.log('Subscription updated:', subscription.id);
    const customerId = subscription.customer;
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer || customer.deleted) return;
    const email = customer.email;
    if (!email) return;

    const { data: user } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', email)
        .limit(1)
        .single();

    if (!user) return;

    const status = subscription.status;
    if (status === 'active') {
        const priceId = subscription.items.data[0].price.id;
        const amount = subscription.items.data[0].price.unit_amount || 0;
        const currency = subscription.items.data[0].price.currency;
        const plan = subscription.metadata?.plan || 'monthly';

        await supabaseAdmin
            .from('users')
            .update({
                subscription_status: 'active',
                subscription_plan: plan,
                stripe_price_id: priceId,
                subscription_amount: amount / 100,
                subscription_currency: currency,
                subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
                updated_at: new Date().toISOString(),
            })
            .eq('id', user.id);
    } else if (status === 'canceled' || status === 'unpaid') {
        await supabaseAdmin
            .from('users')
            .update({
                subscription_status: 'cancelled',
                subscription_cancelled_at: new Date().toISOString(),
                subscription_cancel_reason: `Subscription ${status}`,
                updated_at: new Date().toISOString(),
            })
            .eq('id', user.id);
    }
}

async function handleSubscriptionDeleted(subscription) {
    console.log('Subscription deleted:', subscription.id);
    const customerId = subscription.customer;
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer || customer.deleted) return;
    const email = customer.email;
    if (!email) return;

    const { data: user } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', email)
        .limit(1)
        .single();

    if (!user) return;

    await supabaseAdmin
        .from('users')
        .update({
            subscription_status: 'cancelled',
            subscription_cancelled_at: new Date().toISOString(),
            subscription_cancel_reason: 'Subscription cancelled by user',
            updated_at: new Date().toISOString(),
        })
        .eq('id', user.id);
}

async function handleInvoicePaid(invoice) {
    console.log('Invoice paid:', invoice.id);
    const subscriptionId = invoice.subscription;
    if (!subscriptionId) return;

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const customerId = subscription.customer;
    const customer = await stripe.customers.retrieve(customerId);
    if (!customer || customer.deleted) return;
    const email = customer.email;
    if (!email) return;

    const { data: user } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', email)
        .limit(1)
        .single();

    if (!user) return;

    const priceId = subscription.items.data[0].price.id;
    const amount = subscription.items.data[0].price.unit_amount || 0;
    const currency = subscription.items.data[0].price.currency;
    const plan = subscription.metadata?.plan || 'monthly';

    await supabaseAdmin
        .from('users')
        .update({
            subscription_status: 'active',
            subscription_plan: plan,
            stripe_price_id: priceId,
            subscription_amount: amount / 100,
            subscription_currency: currency,
            subscription_expires_at: new Date(subscription.current_period_end * 1000).toISOString(),
            updated_at: new Date().toISOString(),
        })
        .eq('id', user.id);
}

async function handlePaymentFailed(invoice) {
    console.log('Payment failed:', invoice.id);
    // Don't cancel immediately - Stripe will retry
}

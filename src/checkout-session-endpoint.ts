// This will be added to index.ts
// Stripe Embedded Checkout Session - embeds full Stripe checkout in iframe
fastify.post('/create-checkout-session', async (request, reply) => {
  try {
    const { priceId, plan } = request.body as {
      priceId: string;
      plan: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';
    };

    if (!priceId || !plan) {
      return reply.code(400).send({
        error: 'Missing required fields',
        message: 'priceId and plan are required',
      });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
      apiVersion: '2023-10-16',
    });

    const frontendUrl = process.env.FRONTEND_URL || 'https://desenrola-ia.web.app';

    const session = await stripe.checkout.sessions.create({
      ui_mode: 'embedded',
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      return_url: \`\${frontendUrl}/subscription/success?session_id={CHECKOUT_SESSION_ID}\`,
      metadata: { plan, source: 'embedded_checkout_session' },
      subscription_data: { metadata: { plan, source: 'embedded_checkout_session' } },
      allow_promotion_codes: true,
    });

    console.log('Checkout session created:', { sessionId: session.id, plan, priceId });

    return reply.code(200).send({
      clientSecret: session.client_secret,
      sessionId: session.id,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Failed to create checkout session',
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

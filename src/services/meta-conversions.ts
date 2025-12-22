import crypto from 'crypto';

const PIXEL_ID = process.env.META_PIXEL_ID || '';
const ACCESS_TOKEN = process.env.META_ACCESS_TOKEN || '';

interface PurchaseEventData {
  email: string;
  value: number;
  currency: string;
  eventId: string;
  plan?: string;
  ip?: string;
  userAgent?: string;
}

/**
 * Hash data using SHA256 (required by Meta)
 */
function hashData(data: string): string {
  return crypto
    .createHash('sha256')
    .update(data.toLowerCase().trim())
    .digest('hex');
}

/**
 * Send Purchase event to Meta Conversions API
 */
export async function trackPurchase(data: PurchaseEventData): Promise<void> {
  if (!PIXEL_ID || !ACCESS_TOKEN) {
    console.warn('⚠️ Meta Pixel not configured, skipping conversion tracking');
    return;
  }

  try {
    const payload = {
      data: [
        {
          event_name: 'Purchase',
          event_time: Math.floor(Date.now() / 1000),
          event_id: data.eventId,
          event_source_url: 'https://desenrola-ia.web.app/checkout',
          action_source: 'website',
          user_data: {
            em: [hashData(data.email)],
            ...(data.ip && { client_ip_address: data.ip }),
            ...(data.userAgent && { client_user_agent: data.userAgent }),
          },
          custom_data: {
            currency: data.currency.toUpperCase(),
            value: data.value,
            content_name: `Desenrola IA - ${data.plan || 'Subscription'}`,
            content_category: 'subscription',
          },
        },
      ],
      access_token: ACCESS_TOKEN,
    };

    const response = await fetch(
      `https://graph.facebook.com/v18.0/${PIXEL_ID}/events`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      }
    );

    const result = await response.json() as { events_received?: number; error?: unknown };

    if (response.ok) {
      console.log('✅ Meta Conversion tracked:', {
        eventId: data.eventId,
        email: data.email.substring(0, 3) + '***',
        value: data.value,
        eventsReceived: result.events_received,
      });
    } else {
      console.error('❌ Meta Conversion error:', result);
    }
  } catch (error) {
    console.error('❌ Meta Conversion API error:', error);
  }
}

/**
 * Track InitiateCheckout event
 */
export async function trackInitiateCheckout(data: {
  email: string;
  value: number;
  currency: string;
  eventId: string;
  plan?: string;
}): Promise<void> {
  if (!PIXEL_ID || !ACCESS_TOKEN) return;

  try {
    const payload = {
      data: [
        {
          event_name: 'InitiateCheckout',
          event_time: Math.floor(Date.now() / 1000),
          event_id: data.eventId,
          event_source_url: 'https://desenrola-ia.web.app/pricing',
          action_source: 'website',
          user_data: {
            em: [hashData(data.email)],
          },
          custom_data: {
            currency: data.currency.toUpperCase(),
            value: data.value,
            content_name: `Desenrola IA - ${data.plan || 'Subscription'}`,
          },
        },
      ],
      access_token: ACCESS_TOKEN,
    };

    await fetch(`https://graph.facebook.com/v18.0/${PIXEL_ID}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    console.log('✅ Meta InitiateCheckout tracked');
  } catch (error) {
    console.error('❌ Meta InitiateCheckout error:', error);
  }
}

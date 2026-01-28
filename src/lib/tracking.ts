// Tracking utility for GTM dataLayer events + Facebook Pixel

declare global {
  interface Window {
    dataLayer: Record<string, any>[];
    fbq?: (...args: any[]) => void;
  }
}

// Flag to prevent duplicate Facebook Lead events
let fbLeadFired = false;

// Push event to dataLayer (GTM)
export function trackEvent(eventName: string, params?: Record<string, any>) {
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push({
    event: eventName,
    ...params
  });
}

// ViewContent - page views
export function trackViewContent(contentName: string) {
  // GTM
  trackEvent('view_content', { content_name: contentName });

  // Facebook Pixel
  if (window.fbq) {
    window.fbq('track', 'ViewContent', { content_name: contentName });
  }
}

// Lead - quiz completed (GTM only, Facebook Lead fires on lead_capture)
export function trackLead(quizResult?: string) {
  // GTM only - Facebook Lead event is fired in trackLeadCapture to avoid duplicates
  trackEvent('quiz_complete', { quiz_result: quizResult });
}

// InitiateCheckout - checkout started
export function trackInitiateCheckout(plan?: string, value?: string) {
  const numValue = value ? parseFloat(value.replace(',', '.')) : 0;

  // GTM
  trackEvent('initiate_checkout', { plan, value });

  // Facebook Pixel
  if (window.fbq) {
    window.fbq('track', 'InitiateCheckout', {
      content_name: plan,
      value: numValue,
      currency: 'BRL'
    });
  }
}

// Purchase - completed purchase
export function trackPurchase(value: number, currency: string = 'BRL', transactionId?: string) {
  // GTM
  trackEvent('purchase', {
    value,
    currency,
    transaction_id: transactionId
  });

  // Facebook Pixel
  if (window.fbq) {
    window.fbq('track', 'Purchase', {
      value,
      currency
    });
  }
}

// Scroll depth (GTM only - custom event)
export function trackScrollDepth(percent: number, pageName: string) {
  trackEvent('scroll_depth', {
    scroll_percent: percent,
    page_name: pageName
  });
}

// Time on page (GTM only - custom event)
export function trackTimeOnPage(seconds: number, pageName: string) {
  trackEvent('time_on_page', {
    time_seconds: seconds,
    page_name: pageName
  });
}

// Lead Capture - name + email captured
export function trackLeadCapture(name: string, email: string, source: string) {
  // GTM - always fires (can handle deduplication)
  trackEvent('lead_capture', {
    lead_name: name,
    lead_email: email,
    lead_source: source
  });

  // Facebook Pixel - Lead event (only once per session to avoid alerts)
  if (window.fbq && !fbLeadFired) {
    fbLeadFired = true;
    window.fbq('track', 'Lead', {
      content_name: source
    });
  }

  // Enviar direto para Google Sheets (pode receber múltiplas vezes se email mudar)
  try {
    const webhookUrl = 'https://script.google.com/macros/s/AKfycbzHbTs4JohfF1pCIDYGRlof3xiigvfMoOqI7oJGpI1nsb4PfYjVdKL42upcHD0AB6lvQA/exec';
    const params = `?name=${encodeURIComponent(name)}&email=${encodeURIComponent(email)}&source=${encodeURIComponent(source)}`;
    const img = new Image();
    img.src = webhookUrl + params;
  } catch (e) {
    // Silently fail
  }
}

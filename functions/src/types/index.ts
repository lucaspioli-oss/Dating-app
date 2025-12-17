export interface User {
  id: string;
  email: string;
  displayName: string;
  createdAt: Date;
  subscription: {
    status: 'active' | 'cancelled' | 'expired' | 'inactive';
    plan: 'monthly' | 'yearly' | 'none';
    expiresAt?: Date;
    stripeSubscriptionId?: string;
    stripeCustomerId?: string;
  };
  profile?: {
    name: string;
    age: number;
    interests: string[];
    dislikes: string[];
    humorStyle: string;
    relationshipGoal: string;
  };
  stats: {
    totalConversations: number;
    totalMessages: number;
    aiSuggestionsUsed: number;
  };
}

export interface Subscription {
  id: string;
  userId: string;
  status: 'active' | 'cancelled' | 'expired' | 'inactive';
  plan: 'monthly' | 'yearly' | 'none';
  startDate: Date;
  expiresAt: Date;
  stripeSubscriptionId?: string;
  stripeCustomerId?: string;
  stripePriceId?: string;
  productId: string;
  price: number;
  currency: string;
  cancelledAt?: Date;
  cancelReason?: string;
  nextBillingDate?: Date;
}

// Stripe webhook events we handle
export type StripeWebhookEvent =
  | 'checkout.session.completed'
  | 'customer.subscription.updated'
  | 'customer.subscription.deleted'
  | 'invoice.paid'
  | 'invoice.payment_failed';

export interface StripeMetadata {
  userId?: string;
  plan?: 'monthly' | 'yearly';
}

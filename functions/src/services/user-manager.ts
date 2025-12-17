import * as admin from 'firebase-admin';
import { User, Subscription } from '../types';

const db = admin.firestore();

export class UserManager {
  /**
   * Creates a new user document in Firestore without subscription
   */
  static async createUser(
    uid: string,
    email: string,
    displayName: string
  ): Promise<User> {
    const now = new Date();

    const user: User = {
      id: uid,
      email,
      displayName,
      createdAt: now,
      subscription: {
        status: 'inactive',
        plan: 'none',
      },
      stats: {
        totalConversations: 0,
        totalMessages: 0,
        aiSuggestionsUsed: 0,
      },
    };

    await db.collection('users').doc(uid).set(user);

    // Create analytics document
    await db.collection('analytics').doc(uid).set({
      userId: uid,
      signupDate: now,
      lastActive: now,
      conversationQualityHistory: [],
    });

    return user;
  }

  /**
   * Gets user by email (for webhook processing)
   */
  static async getUserByEmail(email: string): Promise<User | null> {
    const snapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return null;
    }

    return snapshot.docs[0].data() as User;
  }

  /**
   * Gets user by ID
   */
  static async getUser(uid: string): Promise<User | null> {
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as User;
  }

  /**
   * Activates subscription after successful Stripe payment
   */
  static async activateSubscription(
    userId: string,
    plan: 'monthly' | 'yearly',
    stripeSubscriptionId: string,
    stripeCustomerId: string,
    stripePriceId: string,
    price: number,
    currency: string,
    currentPeriodEnd: Date
  ): Promise<void> {
    const now = new Date();

    const subscription: Subscription = {
      id: `sub_${Date.now()}`,
      userId,
      status: 'active',
      plan,
      startDate: now,
      expiresAt: currentPeriodEnd,
      stripeSubscriptionId,
      stripeCustomerId,
      stripePriceId,
      productId: 'flirt-ai',
      price,
      currency,
      nextBillingDate: currentPeriodEnd,
    };

    // Update user document
    await db.collection('users').doc(userId).update({
      'subscription.status': 'active',
      'subscription.plan': plan,
      'subscription.expiresAt': currentPeriodEnd,
      'subscription.stripeSubscriptionId': stripeSubscriptionId,
      'subscription.stripeCustomerId': stripeCustomerId,
      'subscription.stripePriceId': stripePriceId,
    });

    // Create subscription document
    await db.collection('subscriptions').add(subscription);

    console.log(`✅ Subscription activated for user ${userId}, expires at ${currentPeriodEnd}`);
  }

  /**
   * Cancels subscription
   */
  static async cancelSubscription(
    userId: string,
    reason: string = 'Cancelled by Stripe webhook'
  ): Promise<void> {
    const now = new Date();

    await db.collection('users').doc(userId).update({
      'subscription.status': 'cancelled',
      'subscription.cancelledAt': now,
      'subscription.cancelReason': reason,
    });

    // Update subscription documents
    const subscriptionsSnapshot = await db.collection('subscriptions')
      .where('userId', '==', userId)
      .where('status', '==', 'active')
      .get();

    const batch = db.batch();
    subscriptionsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'cancelled',
        cancelledAt: now,
        cancelReason: reason,
      });
    });
    await batch.commit();

    console.log(`❌ Subscription cancelled for user ${userId}: ${reason}`);
  }

  /**
   * Checks if subscription is expired and updates status
   */
  static async checkExpiredSubscriptions(): Promise<void> {
    const now = new Date();
    const expiredSnapshot = await db.collection('users')
      .where('subscription.status', '==', 'active')
      .where('subscription.expiresAt', '<', now)
      .get();

    const batch = db.batch();
    expiredSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        'subscription.status': 'expired',
      });
    });

    await batch.commit();
    console.log(`🕐 Marked ${expiredSnapshot.size} subscriptions as expired`);
  }

  /**
   * Updates user stats
   */
  static async updateStats(
    userId: string,
    stats: Partial<User['stats']>
  ): Promise<void> {
    const updates: any = {};
    if (stats.totalConversations !== undefined) {
      updates['stats.totalConversations'] = admin.firestore.FieldValue.increment(stats.totalConversations);
    }
    if (stats.totalMessages !== undefined) {
      updates['stats.totalMessages'] = admin.firestore.FieldValue.increment(stats.totalMessages);
    }
    if (stats.aiSuggestionsUsed !== undefined) {
      updates['stats.aiSuggestionsUsed'] = admin.firestore.FieldValue.increment(stats.aiSuggestionsUsed);
    }

    await db.collection('users').doc(userId).update(updates);
  }
}

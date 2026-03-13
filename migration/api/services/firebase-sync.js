"use strict";
/**
 * Firebase Dual-Write Service
 *
 * Writes to Firestore as secondary store while app still reads from Firebase.
 * All operations are non-blocking (fire-and-forget with error logging).
 *
 * REMOVE THIS FILE when Flutter app is fully migrated to Supabase.
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin if not already
if (!admin.apps.length) {
  const rawKey = process.env.FIREBASE_PRIVATE_KEY;
  let privateKey = rawKey;
  if (rawKey?.includes("\\n")) {
    privateKey = rawKey.replace(/\\n/g, "\n");
  }
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: privateKey,
    }),
  });
  admin.firestore().settings({ ignoreUndefinedProperties: true });
}

const db = admin.firestore();

// Helper to get Firebase UID from Supabase UUID
const { supabase } = require("../config/supabase");

async function getFirebaseUid(supabaseUid) {
  const { data } = await supabase
    .from("user_id_mapping")
    .select("firebase_uid")
    .eq("supabase_uid", supabaseUid)
    .single();
  return data?.firebase_uid || null;
}

// Cache for UID lookups
const uidCache = new Map();
async function resolveFirebaseUid(supabaseUid) {
  if (uidCache.has(supabaseUid)) return uidCache.get(supabaseUid);
  const fbUid = await getFirebaseUid(supabaseUid);
  if (fbUid) uidCache.set(supabaseUid, fbUid);
  return fbUid;
}

/**
 * Sync conversation creation to Firestore
 */
async function syncConversationCreate(conversation) {
  try {
    const fbUid = await resolveFirebaseUid(conversation.user_id);
    if (!fbUid) return;

    const firestoreData = {
      userId: fbUid,
      profileId: conversation.profile_id || null,
      platform: conversation.platform,
      avatar: conversation.avatar || {},
      messages: conversation.messages || [],
      currentTone: conversation.current_tone || "casual",
      status: conversation.status || "active",
      collectiveAvatarId: conversation.collective_avatar_id || null,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(conversation.created_at)),
      lastMessageAt: admin.firestore.Timestamp.fromDate(new Date(conversation.last_message_at || conversation.created_at)),
    };

    await db.collection("conversations").doc(conversation.id).set(firestoreData);
    console.log(`[Firebase-Sync] Conversation ${conversation.id} created`);
  } catch (e) {
    console.warn("[Firebase-Sync] Conv create failed (non-fatal):", e.message);
  }
}

/**
 * Sync message append to Firestore
 */
async function syncMessageAppend(conversationId, message) {
  try {
    await db.collection("conversations").doc(conversationId).update({
      messages: admin.firestore.FieldValue.arrayUnion(message),
      lastMessageAt: admin.firestore.Timestamp.now(),
    });
    console.log(`[Firebase-Sync] Message appended to ${conversationId}`);
  } catch (e) {
    console.warn("[Firebase-Sync] Message append failed (non-fatal):", e.message);
  }
}

/**
 * Sync multiple messages append to Firestore
 */
async function syncMessagesAppend(conversationId, messages) {
  try {
    await db.collection("conversations").doc(conversationId).update({
      messages: admin.firestore.FieldValue.arrayUnion(...messages),
      lastMessageAt: admin.firestore.Timestamp.now(),
    });
    console.log(`[Firebase-Sync] ${messages.length} messages appended to ${conversationId}`);
  } catch (e) {
    console.warn("[Firebase-Sync] Messages append failed (non-fatal):", e.message);
  }
}

/**
 * Sync avatar analytics increment to Firestore
 */
async function syncAvatarAnalyticsIncrement(conversationId, field) {
  try {
    await db.collection("conversations").doc(conversationId).update({
      [`avatar.analytics.${field}`]: admin.firestore.FieldValue.increment(1),
      "avatar.analytics.totalMessages": admin.firestore.FieldValue.increment(1),
    });
  } catch (e) {
    console.warn("[Firebase-Sync] Analytics increment failed (non-fatal):", e.message);
  }
}

/**
 * Sync conversation tone update to Firestore
 */
async function syncToneUpdate(conversationId, tone) {
  try {
    await db.collection("conversations").doc(conversationId).update({ currentTone: tone });
  } catch (e) {
    console.warn("[Firebase-Sync] Tone update failed (non-fatal):", e.message);
  }
}

/**
 * Sync conversation deletion to Firestore
 */
async function syncConversationDelete(conversationId) {
  try {
    await db.collection("conversations").doc(conversationId).delete();
    console.log(`[Firebase-Sync] Conversation ${conversationId} deleted`);
  } catch (e) {
    console.warn("[Firebase-Sync] Conv delete failed (non-fatal):", e.message);
  }
}

/**
 * Sync profile activity update to Firestore
 */
async function syncProfileActivity(firebaseProfileId, content) {
  try {
    if (!firebaseProfileId) return;
    await db.collection("profiles").doc(firebaseProfileId).update({
      lastActivityAt: admin.firestore.Timestamp.now(),
      lastMessagePreview: (content || "").substring(0, 80),
      updatedAt: admin.firestore.Timestamp.now(),
    });
  } catch (e) {
    console.warn("[Firebase-Sync] Profile activity failed (non-fatal):", e.message);
  }
}

/**
 * Sync subscription update to Firestore
 */
async function syncSubscription(supabaseUid, subscriptionData) {
  try {
    const fbUid = await resolveFirebaseUid(supabaseUid);
    if (!fbUid) return;

    const firestoreUpdate = { subscription: {} };
    if (subscriptionData.status) firestoreUpdate.subscription.status = subscriptionData.status;
    if (subscriptionData.plan) firestoreUpdate.subscription.plan = subscriptionData.plan;
    if (subscriptionData.provider) firestoreUpdate.subscription.provider = subscriptionData.provider;
    if (subscriptionData.stripeCustomerId) firestoreUpdate.subscription.stripeCustomerId = subscriptionData.stripeCustomerId;
    if (subscriptionData.stripeSubscriptionId) firestoreUpdate.subscription.stripeSubscriptionId = subscriptionData.stripeSubscriptionId;
    if (subscriptionData.stripePriceId) firestoreUpdate.subscription.stripePriceId = subscriptionData.stripePriceId;
    if (subscriptionData.amount) firestoreUpdate.subscription.amount = subscriptionData.amount;
    if (subscriptionData.currency) firestoreUpdate.subscription.currency = subscriptionData.currency;
    if (subscriptionData.expiresAt) {
      firestoreUpdate.subscription.expiresAt = admin.firestore.Timestamp.fromDate(new Date(subscriptionData.expiresAt));
    }
    if (subscriptionData.startedAt) {
      firestoreUpdate.subscription.startedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    if (subscriptionData.cancelledAt) {
      firestoreUpdate.subscription.cancelledAt = admin.firestore.FieldValue.serverTimestamp();
      firestoreUpdate.subscription.cancelReason = subscriptionData.cancelReason || "Subscription cancelled";
    }
    if (subscriptionData.appleProductId) firestoreUpdate.subscription.appleProductId = subscriptionData.appleProductId;
    if (subscriptionData.appleTransactionId) firestoreUpdate.subscription.appleTransactionId = subscriptionData.appleTransactionId;

    await db.collection("users").doc(fbUid).set(firestoreUpdate, { merge: true });
    console.log(`[Firebase-Sync] Subscription synced for ${fbUid}`);
  } catch (e) {
    console.warn("[Firebase-Sync] Subscription sync failed (non-fatal):", e.message);
  }
}

/**
 * Sync account deletion to Firestore
 */
async function syncAccountDelete(supabaseUid) {
  try {
    const fbUid = await resolveFirebaseUid(supabaseUid);
    if (!fbUid) return;

    const batch = db.batch();
    batch.delete(db.collection("users").doc(fbUid));
    batch.delete(db.collection("profiles").doc(fbUid));
    batch.delete(db.collection("analytics").doc(fbUid));

    const convs = await db.collection("conversations").where("userId", "==", fbUid).get();
    convs.docs.forEach((doc) => batch.delete(doc.ref));

    const subs = await db.collection("subscriptions").where("userId", "==", fbUid).get();
    subs.docs.forEach((doc) => batch.delete(doc.ref));

    const feedback = await db.collection("trainingFeedback").where("userId", "==", fbUid).get();
    feedback.docs.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
    await admin.auth().deleteUser(fbUid);
    console.log(`[Firebase-Sync] Account ${fbUid} deleted from Firebase`);
  } catch (e) {
    console.warn("[Firebase-Sync] Account delete failed (non-fatal):", e.message);
  }
}

/**
 * Sync expired subscriptions to Firestore
 */
async function syncExpiredSubscriptions(firebaseUids) {
  try {
    if (!firebaseUids || firebaseUids.length === 0) return;
    const batch = db.batch();
    for (const fbUid of firebaseUids) {
      batch.update(db.collection("users").doc(fbUid), {
        "subscription.status": "expired",
      });
    }
    await batch.commit();
    console.log(`[Firebase-Sync] Marked ${firebaseUids.length} subscriptions as expired`);
  } catch (e) {
    console.warn("[Firebase-Sync] Expired sync failed (non-fatal):", e.message);
  }
}

module.exports = {
  syncConversationCreate,
  syncMessageAppend,
  syncMessagesAppend,
  syncAvatarAnalyticsIncrement,
  syncToneUpdate,
  syncConversationDelete,
  syncProfileActivity,
  syncSubscription,
  syncAccountDelete,
  syncExpiredSubscriptions,
  resolveFirebaseUid,
};

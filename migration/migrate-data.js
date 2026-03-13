// Firebase → Supabase data migration script
// Run inside the Docker container where firebase-admin is available

const admin = require("firebase-admin");

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const rawKey = process.env.FIREBASE_PRIVATE_KEY || "";
const pk = rawKey.split("\\n").join("\n");
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: pk,
  }),
});
admin.firestore().settings({ ignoreUndefinedProperties: true });
const db = admin.firestore();

function headers() {
  return {
    "Content-Type": "application/json",
    apikey: SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
    Prefer: "resolution=merge-duplicates",
  };
}

async function supaPost(table, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const txt = await res.text();
    console.error(`  ❌ ${table}: ${res.status} ${txt}`);
    return false;
  }
  return true;
}

function tsToISO(ts) {
  if (!ts) return null;
  if (ts._seconds) return new Date(ts._seconds * 1000).toISOString();
  if (ts.toDate) return ts.toDate().toISOString();
  if (typeof ts === "string") return ts;
  if (ts instanceof Date) return ts.toISOString();
  return null;
}

// Build Firebase UID → Supabase UUID mapping
async function getUidMapping() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/user_id_mapping?select=firebase_uid,supabase_uid`, {
    headers: headers(),
  });
  const rows = await res.json();
  const map = {};
  for (const r of rows) map[r.firebase_uid] = r.supabase_uid;
  return map;
}

async function migrateUsers(uidMap) {
  console.log("\n=== Migrating users (update missing fields) ===");
  const snap = await db.collection("users").get();
  let updated = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const supaId = uidMap[doc.id];
    if (!supaId) {
      console.log(`  ⚠️ No Supabase mapping for Firebase UID ${doc.id} (${d.email})`);
      continue;
    }

    const sub = d.subscription || {};
    const patch = {
      display_name: d.displayName || "Usuário",
      is_admin: d.isAdmin === true,
      is_developer: d.isDeveloper === true,
      subscription_status: sub.status || "inactive",
      subscription_plan: sub.plan || "none",
      subscription_provider: sub.provider || (sub.stripeSubscriptionId ? "stripe" : null),
      stripe_subscription_id: sub.stripeSubscriptionId || null,
      stripe_customer_id: sub.stripeCustomerId || null,
      stripe_price_id: sub.stripePriceId || null,
      subscription_amount: sub.amount || null,
      subscription_currency: sub.currency || null,
      subscription_expires_at: tsToISO(sub.expiresAt),
      subscription_started_at: tsToISO(sub.startedAt),
      subscription_cancelled_at: tsToISO(sub.cancelledAt),
      subscription_cancel_reason: sub.cancelReason || null,
      apple_product_id: sub.appleProductId || null,
      apple_transaction_id: sub.appleTransactionId || null,
    };

    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/users?id=eq.${supaId}`,
      {
        method: "PATCH",
        headers: { ...headers(), Prefer: "return=minimal" },
        body: JSON.stringify(patch),
      }
    );
    if (res.ok) updated++;
    else console.error(`  ❌ user ${d.email}: ${await res.text()}`);
  }
  console.log(`  ✅ Updated ${updated}/${snap.size} users`);
}

async function migrateProfiles(uidMap) {
  console.log("\n=== Migrating profiles ===");
  const snap = await db.collection("profiles").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const supaUserId = uidMap[d.userId];
    if (!supaUserId) {
      console.log(`  ⚠️ No mapping for profile owner ${d.userId}`);
      continue;
    }

    const row = {
      firebase_id: doc.id,
      user_id: supaUserId,
      name: d.name || "Sem nome",
      platforms: d.platforms || {},
      face_image_base64: d.faceImageBase64 || null,
      last_activity_at: tsToISO(d.lastActivityAt),
      last_message_preview: d.lastMessagePreview || null,
      created_at: tsToISO(d.createdAt) || new Date().toISOString(),
      updated_at: tsToISO(d.updatedAt) || new Date().toISOString(),
    };

    if (await supaPost("profiles", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} profiles`);
}

async function migrateConversations(uidMap) {
  console.log("\n=== Migrating conversations ===");
  const snap = await db.collection("conversations").get();
  let ok = 0;

  // Get profile firebase_id → supabase id mapping
  const profRes = await fetch(
    `${SUPABASE_URL}/rest/v1/profiles?select=id,firebase_id`,
    { headers: headers() }
  );
  const profiles = await profRes.json();
  const profileMap = {};
  for (const p of profiles) if (p.firebase_id) profileMap[p.firebase_id] = p.id;

  for (const doc of snap.docs) {
    const d = doc.data();
    const supaUserId = uidMap[d.userId];
    if (!supaUserId) {
      console.log(`  ⚠️ No mapping for conv owner ${d.userId}`);
      continue;
    }

    // Convert messages timestamps
    const messages = (d.messages || []).map((m) => ({
      id: m.id,
      role: m.role,
      content: m.content,
      timestamp: tsToISO(m.timestamp) || new Date().toISOString(),
      wasAiSuggestion: m.wasAiSuggestion || false,
      tone: m.tone || null,
      source: m.source || null,
      objective: m.objective || null,
    }));

    const row = {
      id: doc.id, // preserve UUID
      firebase_id: doc.id,
      user_id: supaUserId,
      profile_id: d.profileId ? profileMap[d.profileId] || null : null,
      platform: d.platform || d.avatar?.platform || null,
      current_tone: d.currentTone || "casual",
      status: d.status || "active",
      avatar: d.avatar || {},
      messages: messages,
      collective_avatar_id: d.collectiveAvatarId || null,
      created_at: tsToISO(d.createdAt) || new Date().toISOString(),
      last_message_at: tsToISO(d.lastMessageAt) || new Date().toISOString(),
    };

    if (await supaPost("conversations", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} conversations`);
}

async function migrateCollectiveAvatars() {
  console.log("\n=== Migrating collective avatars ===");
  const snap = await db.collection("collectiveAvatars").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const row = {
      id: doc.id,
      normalized_name: d.normalizedName || null,
      platform: d.platform || null,
      profile_data: d.profileData || {},
      collective_insights: d.collectiveInsights || {},
      metrics: d.metrics || {},
      confidence_score: d.confidenceScore || 10,
      last_updated: tsToISO(d.lastUpdated) || new Date().toISOString(),
      last_analyzed_at: tsToISO(d.lastAnalyzedAt),
      created_at: tsToISO(d.createdAt) || new Date().toISOString(),
    };

    if (await supaPost("collective_avatars", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} collective avatars`);
}

async function migrateAnalytics(uidMap) {
  console.log("\n=== Migrating analytics ===");
  const snap = await db.collection("analytics").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const supaUserId = uidMap[doc.id] || uidMap[d.userId];
    if (!supaUserId) {
      console.log(`  ⚠️ No mapping for analytics ${doc.id}`);
      continue;
    }

    const row = {
      user_id: supaUserId,
      signup_date: tsToISO(d.signupDate),
      last_active: tsToISO(d.lastActive),
      conversation_quality_history: d.conversationQualityHistory || [],
    };

    if (await supaPost("analytics", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} analytics`);
}

async function migrateTagInsights() {
  console.log("\n=== Migrating tag insights ===");
  const snap = await db.collection("tagInsights").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const row = {
      id: doc.id,
      what_works: d.whatWorks || [],
      what_doesnt_work: d.whatDoesntWork || [],
      good_examples: d.goodExamples || [],
      bad_examples: d.badExamples || [],
      best_types: d.bestTypes || [],
    };

    if (await supaPost("tag_insights", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} tag insights`);
}

async function migrateMessageFeedback() {
  console.log("\n=== Migrating message feedback ===");
  const snap = await db.collection("messageFeedback").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const row = {
      id: doc.id,
      collective_avatar_id: d.collectiveAvatarId || null,
      message_type: d.messageType || null,
      tone: d.tone || null,
      message_sent: d.messageSent || null,
      got_response: d.gotResponse || null,
      response_time: d.responseTime || null,
      response_quality: d.responseQuality || null,
      created_at: tsToISO(d.timestamp) || new Date().toISOString(),
    };

    if (await supaPost("message_feedback", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} message feedback`);
}

async function migrateTrainingFeedback(uidMap) {
  console.log("\n=== Migrating training feedback ===");
  const snap = await db.collection("trainingFeedback").get();
  let ok = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const row = {
      id: doc.id,
      user_id: d.userId ? uidMap[d.userId] || null : null,
      category: d.category || null,
      subcategory: d.subcategory || null,
      instruction: d.instruction || null,
      examples: d.examples || [],
      tags: d.tags || [],
      priority: d.priority || "medium",
      is_active: d.isActive !== false,
      usage_count: d.usageCount || 0,
      created_at: tsToISO(d.createdAt) || new Date().toISOString(),
      updated_at: tsToISO(d.updatedAt) || new Date().toISOString(),
    };

    if (await supaPost("training_feedback", row)) ok++;
  }
  console.log(`  ✅ Migrated ${ok}/${snap.size} training feedback`);
}

async function main() {
  console.log("🚀 Starting Firebase → Supabase data migration\n");

  const uidMap = await getUidMapping();
  console.log(`📋 Found ${Object.keys(uidMap).length} UID mappings`);

  await migrateUsers(uidMap);
  await migrateProfiles(uidMap);
  await migrateConversations(uidMap);
  await migrateCollectiveAvatars();
  await migrateAnalytics(uidMap);
  await migrateTagInsights();
  await migrateMessageFeedback();
  await migrateTrainingFeedback(uidMap);

  console.log("\n✅ Migration complete!");
  process.exit(0);
}

main().catch((e) => {
  console.error("💥 Migration failed:", e);
  process.exit(1);
});

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAuth = verifyAuth;
exports.verifyAuthOnly = verifyAuthOnly;
exports.optionalAuth = optionalAuth;
exports.verifyRequestSignature = verifyRequestSignature;

const crypto = require("crypto");
const admin = require("firebase-admin");
const { supabase } = require("../config/supabase");

// Initialize Firebase Admin (ONLY for token verification during migration)
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
}

/**
 * Resolve Firebase UID to Supabase UUID
 */
async function resolveUserId(firebaseUid) {
  const { data, error } = await supabase
    .from("user_id_mapping")
    .select("supabase_uid")
    .eq("firebase_uid", firebaseUid)
    .single();
  return data?.supabase_uid || null;
}

/**
 * Middleware: verify Firebase token + check subscription via Supabase
 */
async function verifyAuth(request, reply) {
  try {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      reply.code(401).send({ error: "Unauthorized", message: "Missing or invalid authorization header" });
      return;
    }

    const token = authHeader.substring(7);
    const decodedToken = await admin.auth().verifyIdToken(token);
    const supabaseUid = await resolveUserId(decodedToken.uid);

    if (!supabaseUid) {
      reply.code(401).send({ error: "Unauthorized", message: "User not found" });
      return;
    }

    // Get user from Supabase
    let { data: userData, error } = await supabase
      .from("users")
      .select("*")
      .eq("id", supabaseUid)
      .single();

    if (!userData) {
      // Auto-create user
      const newUser = {
        id: supabaseUid,
        firebase_uid: decodedToken.uid,
        email: decodedToken.email || "",
        display_name: decodedToken.name || "Usuário",
        subscription_status: "inactive",
        subscription_plan: "none",
      };
      const { data: created } = await supabase.from("users").upsert(newUser).select().single();
      userData = created || newUser;
    }

    const isAdmin = userData.is_admin === true;
    const isDeveloper = userData.is_developer === true;
    const now = new Date();
    const expiresAt = userData.subscription_expires_at ? new Date(userData.subscription_expires_at) : null;

    const hasActiveSubscription =
      isAdmin ||
      isDeveloper ||
      (userData.subscription_status === "active" && (!expiresAt || now < expiresAt));

    request.user = {
      uid: supabaseUid,
      firebaseUid: decodedToken.uid,
      email: decodedToken.email,
      hasActiveSubscription,
      isAdmin,
      isDeveloper,
    };

    if (!hasActiveSubscription) {
      reply.code(403).send({
        error: "Subscription Required",
        message: "You need an active subscription to use this feature",
        subscriptionStatus: userData.subscription_status || "none",
        expiresAt: expiresAt?.toISOString(),
      });
      return;
    }
  } catch (error) {
    console.error("Auth verification failed:", error.code || error.message);
    reply.code(401).send({ error: "Unauthorized", message: error.message || "Invalid token" });
  }
}

/**
 * Auth only - verifies token but doesn't require subscription
 */
async function verifyAuthOnly(request, reply) {
  try {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      reply.code(401).send({ error: "Unauthorized", message: "Missing or invalid authorization header" });
      return;
    }

    const token = authHeader.substring(7);
    const decodedToken = await admin.auth().verifyIdToken(token);
    const supabaseUid = await resolveUserId(decodedToken.uid);

    request.user = {
      uid: supabaseUid || decodedToken.uid,
      firebaseUid: decodedToken.uid,
      email: decodedToken.email,
      hasActiveSubscription: false,
    };
  } catch (error) {
    console.error("Auth error:", error.code || error.message);
    reply.code(401).send({ error: "Unauthorized", message: error.message || "Invalid token" });
  }
}

/**
 * Optional auth - doesn't block if no token
 */
async function optionalAuth(request, reply) {
  const authHeader = request.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) return;

  try {
    const token = authHeader.substring(7);
    const decodedToken = await admin.auth().verifyIdToken(token);
    const supabaseUid = await resolveUserId(decodedToken.uid);

    if (supabaseUid) {
      const { data: userData } = await supabase.from("users").select("*").eq("id", supabaseUid).single();
      if (userData) {
        const isAdmin = userData.is_admin === true;
        const isDeveloper = userData.is_developer === true;
        const now = new Date();
        const expiresAt = userData.subscription_expires_at ? new Date(userData.subscription_expires_at) : null;
        const hasActiveSubscription =
          isAdmin || isDeveloper || (userData.subscription_status === "active" && (!expiresAt || now < expiresAt));

        request.user = {
          uid: supabaseUid,
          firebaseUid: decodedToken.uid,
          email: decodedToken.email,
          hasActiveSubscription,
          isAdmin,
          isDeveloper,
        };
      }
    }
  } catch (error) {
    // Invalid token, continue without user
  }
}

// ═══════════════════════════════════════════════════════════════════
// Ed25519 Request Signature Validation (unchanged)
// ═══════════════════════════════════════════════════════════════════
const ED25519_PUBLIC_KEY_BASE64 = process.env.ED25519_PUBLIC_KEY || "5r0J9lIrdi8yLSsCz+WO3K+pek0nvdtXv/NjkNsF28Q=";

const ed25519PublicKeyDer = Buffer.concat([
  Buffer.from("302a300506032b6570032100", "hex"),
  Buffer.from(ED25519_PUBLIC_KEY_BASE64, "base64"),
]);
const ed25519PublicKey = crypto.createPublicKey({ key: ed25519PublicKeyDer, format: "der", type: "spki" });

const usedNonces = new Map();
const NONCE_TTL_MS = 60 * 1000;
const TIMESTAMP_TOLERANCE_S = 30;

setInterval(() => {
  const now = Date.now();
  for (const [nonce, expiry] of usedNonces) {
    if (now > expiry) usedNonces.delete(nonce);
  }
}, NONCE_TTL_MS);

async function verifyRequestSignature(request, reply) {
  try {
    const signature = request.headers["x-signature"];
    const timestamp = request.headers["x-timestamp"];
    const nonce = request.headers["x-nonce"];

    if (!signature || !timestamp || !nonce) {
      reply.code(401).send({ error: "Signature Required", message: "Missing X-Signature, X-Timestamp, or X-Nonce header" });
      return;
    }

    const requestTimestamp = parseInt(timestamp, 10);
    if (isNaN(requestTimestamp)) {
      reply.code(401).send({ error: "Invalid Timestamp", message: "X-Timestamp must be a valid Unix timestamp" });
      return;
    }

    const timeDiff = Math.abs(Math.floor(Date.now() / 1000) - requestTimestamp);
    if (timeDiff > TIMESTAMP_TOLERANCE_S) {
      reply.code(401).send({ error: "Timestamp Expired", message: `Request timestamp is ${timeDiff}s from server time` });
      return;
    }

    if (usedNonces.has(nonce)) {
      reply.code(401).send({ error: "Nonce Reused", message: "This nonce has already been used" });
      return;
    }
    usedNonces.set(nonce, Date.now() + NONCE_TTL_MS);

    let bodyString = "";
    if (request.rawBody) bodyString = request.rawBody.toString();
    else if (request.body) bodyString = JSON.stringify(request.body);

    const bodyHash = crypto.createHash("sha256").update(bodyString).digest("hex");
    const message = `${timestamp}|${nonce}|${bodyHash}`;

    const isValid = crypto.verify(null, Buffer.from(message), ed25519PublicKey, Buffer.from(signature, "base64"));
    if (!isValid) {
      reply.code(401).send({ error: "Invalid Signature", message: "Ed25519 signature verification failed" });
      return;
    }
  } catch (error) {
    console.error("Signature verification error:", error.message || error);
    reply.code(401).send({ error: "Signature Verification Failed", message: error.message || "Could not verify request signature" });
  }
}

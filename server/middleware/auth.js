"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAuth = verifyAuth;
exports.verifyAuthOnly = verifyAuthOnly;
exports.optionalAuth = optionalAuth;
exports.verifyRequestSignature = verifyRequestSignature;
const crypto = require("crypto");
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin (only if not already initialized)
if (!admin.apps.length) {
    const rawKey = process.env.FIREBASE_PRIVATE_KEY;
    let privateKey = rawKey;
    if (rawKey?.includes('\\n')) {
        privateKey = rawKey.replace(/\\n/g, '\n');
    }
    admin.initializeApp({
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: privateKey,
        }),
    });
    // Configurar Firestore para ignorar valores undefined
    admin.firestore().settings({
        ignoreUndefinedProperties: true,
    });
}
const db = admin.firestore();
/**
 * Middleware to verify Firebase Auth token
 */
async function verifyAuth(request, reply) {
    try {
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: 'Missing or invalid authorization header',
            });
            return;
        }
        const token = authHeader.substring(7); // Remove 'Bearer '
        // Verify Firebase token
        const decodedToken = await admin.auth().verifyIdToken(token);
        // Check subscription status
        let userDoc = await db.collection('users').doc(decodedToken.uid).get();
        if (!userDoc.exists) {
            // Auto-create user document on first authenticated request
            const newUser = {
                id: decodedToken.uid,
                email: decodedToken.email || '',
                displayName: decodedToken.name || 'Usuário',
                createdAt: new Date(),
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
            await db.collection('users').doc(decodedToken.uid).set(newUser);
            userDoc = await db.collection('users').doc(decodedToken.uid).get();
        }
        const userData = userDoc.data();
        const subscription = userData?.subscription;
        // Check for admin/developer status (stored in Firestore, not in code)
        const isAdmin = userData?.isAdmin === true;
        const isDeveloper = userData?.isDeveloper === true;
        const now = new Date();
        const expiresAt = subscription?.expiresAt?.toDate();
        // Admins and developers always have access
        // Active subscription with valid expiration date
        const hasActiveSubscription = isAdmin ||
            isDeveloper ||
            (subscription?.status === 'active' &&
                (!expiresAt || now < expiresAt));
        // Attach user to request
        request.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            hasActiveSubscription,
            isAdmin,
            isDeveloper,
        };
        // If no active subscription (and not admin/developer), return error
        if (!hasActiveSubscription) {
            reply.code(403).send({
                error: 'Subscription Required',
                message: 'You need an active subscription to use this feature',
                subscriptionStatus: subscription?.status || 'none',
                expiresAt: expiresAt?.toISOString(),
            });
            return;
        }
    }
    catch (error) {
        console.error('Auth verification failed:', error.code || error.message);
        reply.code(401).send({
            error: 'Unauthorized',
            message: error.message || 'Invalid token',
        });
    }
}
/**
 * Auth only - verifies token but doesn't require subscription
 * Use this for endpoints like checkout where user needs to be logged in but may not have subscription
 */
async function verifyAuthOnly(request, reply) {
    try {
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: 'Missing or invalid authorization header',
            });
            return;
        }
        const token = authHeader.substring(7);
        // Verify Firebase token
        const decodedToken = await admin.auth().verifyIdToken(token);
        // Attach user to request (without checking subscription)
        request.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            hasActiveSubscription: false, // Will be checked separately if needed
        };
    }
    catch (error) {
        console.error('Auth error:', error.code || error.message);
        reply.code(401).send({
            error: 'Unauthorized',
            message: error.message || 'Invalid token',
        });
    }
}
/**
 * Optional auth - doesn't block if no token, but checks subscription if token exists
 */
async function optionalAuth(request, reply) {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        // No auth provided, continue without user
        return;
    }
    try {
        const token = authHeader.substring(7);
        const decodedToken = await admin.auth().verifyIdToken(token);
        const userDoc = await db.collection('users').doc(decodedToken.uid).get();
        if (userDoc.exists) {
            const userData = userDoc.data();
            const subscription = userData?.subscription;
            // Check for admin/developer status
            const isAdmin = userData?.isAdmin === true;
            const isDeveloper = userData?.isDeveloper === true;
            const now = new Date();
            const expiresAt = subscription?.expiresAt?.toDate();
            const hasActiveSubscription = isAdmin ||
                isDeveloper ||
                (subscription?.status === 'active' &&
                    (!expiresAt || now < expiresAt));
            request.user = {
                uid: decodedToken.uid,
                email: decodedToken.email,
                hasActiveSubscription,
                isAdmin,
                isDeveloper,
            };
        }
    }
    catch (error) {
        // Invalid token, continue without user
    }
}
// ═══════════════════════════════════════════════════════════════════
// Ed25519 Request Signature Validation
// ═══════════════════════════════════════════════════════════════════
const ED25519_PUBLIC_KEY_BASE64 = process.env.ED25519_PUBLIC_KEY || '5r0J9lIrdi8yLSsCz+WO3K+pek0nvdtXv/NjkNsF28Q=';
// Build the SPKI-wrapped Ed25519 public key once at module load
const ed25519PublicKeyDer = Buffer.concat([
    Buffer.from('302a300506032b6570032100', 'hex'), // SPKI header for Ed25519
    Buffer.from(ED25519_PUBLIC_KEY_BASE64, 'base64'),
]);
const ed25519PublicKey = crypto.createPublicKey({
    key: ed25519PublicKeyDer,
    format: 'der',
    type: 'spki',
});
// Nonce replay protection: in-memory Set with TTL cleanup
const usedNonces = new Map(); // nonce -> expiry timestamp (ms)
const NONCE_TTL_MS = 60 * 1000; // 60 seconds TTL for nonces
const TIMESTAMP_TOLERANCE_S = 30; // 30 seconds tolerance for timestamps
// Clean up expired nonces every 60 seconds
setInterval(() => {
    const now = Date.now();
    for (const [nonce, expiry] of usedNonces) {
        if (now > expiry) {
            usedNonces.delete(nonce);
        }
    }
}, NONCE_TTL_MS);
/**
 * Middleware to verify Ed25519 request signatures.
 *
 * Expects headers:
 *   X-Signature  - base64-encoded Ed25519 signature
 *   X-Timestamp  - Unix timestamp (seconds) when the request was signed
 *   X-Nonce      - unique random string to prevent replay attacks
 *
 * The signed message format is:  timestamp|nonce|sha256hex(requestBody)
 */
async function verifyRequestSignature(request, reply) {
    try {
        const signature = request.headers['x-signature'];
        const timestamp = request.headers['x-timestamp'];
        const nonce = request.headers['x-nonce'];
        // 1. Check required headers are present
        if (!signature || !timestamp || !nonce) {
            reply.code(401).send({
                error: 'Signature Required',
                message: 'Missing X-Signature, X-Timestamp, or X-Nonce header',
            });
            return;
        }
        // 2. Validate timestamp is within tolerance
        const requestTimestamp = parseInt(timestamp, 10);
        if (isNaN(requestTimestamp)) {
            reply.code(401).send({
                error: 'Invalid Timestamp',
                message: 'X-Timestamp must be a valid Unix timestamp in seconds',
            });
            return;
        }
        const serverTimestamp = Math.floor(Date.now() / 1000);
        const timeDiff = Math.abs(serverTimestamp - requestTimestamp);
        if (timeDiff > TIMESTAMP_TOLERANCE_S) {
            reply.code(401).send({
                error: 'Timestamp Expired',
                message: `Request timestamp is ${timeDiff}s from server time (max ${TIMESTAMP_TOLERANCE_S}s)`,
            });
            return;
        }
        // 3. Check nonce hasn't been used before (replay protection)
        if (usedNonces.has(nonce)) {
            reply.code(401).send({
                error: 'Nonce Reused',
                message: 'This nonce has already been used',
            });
            return;
        }
        // Record nonce with expiry
        usedNonces.set(nonce, Date.now() + NONCE_TTL_MS);
        // 4. Reconstruct the signed message: timestamp|nonce|sha256hex(body)
        // Use rawBody if available (from the content type parser), otherwise stringify body
        let bodyString = '';
        if (request.rawBody) {
            bodyString = request.rawBody.toString();
        } else if (request.body) {
            bodyString = JSON.stringify(request.body);
        }
        const bodyHash = crypto.createHash('sha256').update(bodyString).digest('hex');
        const message = `${timestamp}|${nonce}|${bodyHash}`;
        // 5. Verify Ed25519 signature
        const isValid = crypto.verify(
            null,
            Buffer.from(message),
            ed25519PublicKey,
            Buffer.from(signature, 'base64')
        );
        if (!isValid) {
            reply.code(401).send({
                error: 'Invalid Signature',
                message: 'Ed25519 signature verification failed',
            });
            return;
        }
        // Signature is valid, proceed
    }
    catch (error) {
        console.error('Signature verification error:', error.message || error);
        reply.code(401).send({
            error: 'Signature Verification Failed',
            message: error.message || 'Could not verify request signature',
        });
    }
}

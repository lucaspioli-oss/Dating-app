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
        const userDoc = await db.collection('users').doc(decodedToken.uid).get();
        if (!userDoc.exists) {
            reply.code(403).send({
                error: 'Forbidden',
                message: 'User not found',
            });
            return;
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

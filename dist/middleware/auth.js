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
    // Debug: verificar formato da chave
    console.log('=== Firebase Config Debug ===');
    console.log('PROJECT_ID:', process.env.FIREBASE_PROJECT_ID);
    console.log('CLIENT_EMAIL:', process.env.FIREBASE_CLIENT_EMAIL);
    console.log('PRIVATE_KEY exists:', !!rawKey);
    console.log('PRIVATE_KEY length:', rawKey?.length);
    console.log('PRIVATE_KEY starts with:', rawKey?.substring(0, 30));
    console.log('PRIVATE_KEY contains \\n:', rawKey?.includes('\\n'));
    console.log('PRIVATE_KEY contains real newline:', rawKey?.includes('\n') && !rawKey?.includes('\\n'));
    // Tentar diferentes formas de processar a chave
    let privateKey = rawKey;
    if (rawKey?.includes('\\n')) {
        privateKey = rawKey.replace(/\\n/g, '\n');
        console.log('Converted \\n to real newlines');
    }
    console.log('Final key starts with:', privateKey?.substring(0, 30));
    console.log('=============================');
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
    console.log('=== verifyAuth START ===');
    try {
        const authHeader = request.headers.authorization;
        console.log('1. Auth header exists:', !!authHeader);
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            console.log('1. FAIL - No auth header');
            reply.code(401).send({
                error: 'Unauthorized',
                message: 'Missing or invalid authorization header',
            });
            return;
        }
        const token = authHeader.substring(7); // Remove 'Bearer '
        console.log('2. Token length:', token.length);
        // Verify Firebase token
        console.log('3. Verifying token with Firebase Auth...');
        const decodedToken = await admin.auth().verifyIdToken(token);
        console.log('3. Token verified! UID:', decodedToken.uid, 'Email:', decodedToken.email);
        // Check subscription status
        console.log('4. Getting user doc from Firestore...');
        const userDoc = await db.collection('users').doc(decodedToken.uid).get();
        console.log('4. User doc exists:', userDoc.exists);
        if (!userDoc.exists) {
            console.log('4. FAIL - User doc not found');
            reply.code(403).send({
                error: 'Forbidden',
                message: 'User not found',
            });
            return;
        }
        const userData = userDoc.data();
        console.log('5. User data:', JSON.stringify(userData, null, 2));
        const subscription = userData?.subscription;
        // Check for admin/developer status (stored in Firestore, not in code)
        const isAdmin = userData?.isAdmin === true;
        const isDeveloper = userData?.isDeveloper === true;
        console.log('5. isAdmin:', isAdmin, 'isDeveloper:', isDeveloper);
        const now = new Date();
        const expiresAt = subscription?.expiresAt?.toDate();
        console.log('5. Subscription status:', subscription?.status, 'expiresAt:', expiresAt);
        // Admins and developers always have access
        // Active subscription with valid expiration date
        const hasActiveSubscription = isAdmin ||
            isDeveloper ||
            (subscription?.status === 'active' &&
                (!expiresAt || now < expiresAt));
        console.log('6. hasActiveSubscription:', hasActiveSubscription);
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
            console.log('6. FAIL - No active subscription');
            reply.code(403).send({
                error: 'Subscription Required',
                message: 'You need an active subscription to use this feature',
                subscriptionStatus: subscription?.status || 'none',
                expiresAt: expiresAt?.toISOString(),
            });
            return;
        }
        console.log('=== verifyAuth SUCCESS ===');
    }
    catch (error) {
        console.error('=== verifyAuth ERROR ===');
        console.error('Error name:', error.name);
        console.error('Error code:', error.code);
        console.error('Error message:', error.message);
        console.error('Full error:', error);
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
        console.error('Auth error:', error);
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
        console.warn('Optional auth failed:', error);
    }
}

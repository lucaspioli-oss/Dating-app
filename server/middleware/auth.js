"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyAuth = verifyAuth;
exports.verifyAuthOnly = verifyAuthOnly;
exports.optionalAuth = optionalAuth;
exports.verifyRequestSignature = verifyRequestSignature;
const crypto = require("crypto");
const { supabaseAdmin } = require("../config/supabase");

/**
 * Middleware to verify Supabase Auth token and check subscription
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
        const token = authHeader.substring(7);
        // Verify Supabase JWT token
        const { data: { user: authUser }, error: authError } = await supabaseAdmin.auth.getUser(token);
        if (authError || !authUser) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: authError?.message || 'Invalid token',
            });
            return;
        }
        // Check subscription status in users table
        let { data: userData, error: userError } = await supabaseAdmin
            .from('users')
            .select('*')
            .eq('id', authUser.id)
            .single();
        if (userError || !userData) {
            // Auto-create user document on first authenticated request
            const newUser = {
                id: authUser.id,
                email: authUser.email || '',
                display_name: authUser.user_metadata?.full_name || authUser.user_metadata?.name || 'Usuario',
                subscription_status: 'inactive',
                subscription_plan: 'none',
                is_admin: false,
                is_developer: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
            };
            const { data: created, error: createError } = await supabaseAdmin
                .from('users')
                .upsert(newUser)
                .select()
                .single();
            if (createError) {
                console.error('Failed to create user:', createError);
                reply.code(500).send({ error: 'Failed to create user' });
                return;
            }
            userData = created;
        }
        const isAdmin = userData?.is_admin === true;
        const isDeveloper = userData?.is_developer === true;
        const now = new Date();
        const expiresAt = userData?.subscription_expires_at ? new Date(userData.subscription_expires_at) : null;
        const hasActiveSubscription = isAdmin ||
            isDeveloper ||
            (userData?.subscription_status === 'active' &&
                (!expiresAt || now < expiresAt));
        // Attach user to request
        request.user = {
            uid: authUser.id,
            email: authUser.email,
            hasActiveSubscription,
            isAdmin,
            isDeveloper,
        };
        if (!hasActiveSubscription) {
            reply.code(403).send({
                error: 'Subscription Required',
                message: 'You need an active subscription to use this feature',
                subscriptionStatus: userData?.subscription_status || 'none',
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
        const { data: { user: authUser }, error: authError } = await supabaseAdmin.auth.getUser(token);
        if (authError || !authUser) {
            reply.code(401).send({
                error: 'Unauthorized',
                message: authError?.message || 'Invalid token',
            });
            return;
        }
        request.user = {
            uid: authUser.id,
            email: authUser.email,
            hasActiveSubscription: false,
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
 * Optional auth - doesn't block if no token
 */
async function optionalAuth(request, reply) {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return;
    }
    try {
        const token = authHeader.substring(7);
        const { data: { user: authUser }, error: authError } = await supabaseAdmin.auth.getUser(token);
        if (authError || !authUser) return;

        const { data: userData } = await supabaseAdmin
            .from('users')
            .select('*')
            .eq('id', authUser.id)
            .single();
        if (userData) {
            const isAdmin = userData.is_admin === true;
            const isDeveloper = userData.is_developer === true;
            const now = new Date();
            const expiresAt = userData.subscription_expires_at ? new Date(userData.subscription_expires_at) : null;
            const hasActiveSubscription = isAdmin ||
                isDeveloper ||
                (userData.subscription_status === 'active' &&
                    (!expiresAt || now < expiresAt));
            request.user = {
                uid: authUser.id,
                email: authUser.email,
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

// ===================================================================
// Ed25519 Request Signature Validation
// ===================================================================
const ED25519_PUBLIC_KEY_BASE64 = process.env.ED25519_PUBLIC_KEY || '5r0J9lIrdi8yLSsCz+WO3K+pek0nvdtXv/NjkNsF28Q=';
const ed25519PublicKeyDer = Buffer.concat([
    Buffer.from('302a300506032b6570032100', 'hex'),
    Buffer.from(ED25519_PUBLIC_KEY_BASE64, 'base64'),
]);
const ed25519PublicKey = crypto.createPublicKey({
    key: ed25519PublicKeyDer,
    format: 'der',
    type: 'spki',
});
const usedNonces = new Map();
const NONCE_TTL_MS = 60 * 1000;
const TIMESTAMP_TOLERANCE_S = 30;
setInterval(() => {
    const now = Date.now();
    for (const [nonce, expiry] of usedNonces) {
        if (now > expiry) {
            usedNonces.delete(nonce);
        }
    }
}, NONCE_TTL_MS);

async function verifyRequestSignature(request, reply) {
    try {
        const signature = request.headers['x-signature'];
        const timestamp = request.headers['x-timestamp'];
        const nonce = request.headers['x-nonce'];
        if (!signature || !timestamp || !nonce) {
            reply.code(401).send({
                error: 'Signature Required',
                message: 'Missing X-Signature, X-Timestamp, or X-Nonce header',
            });
            return;
        }
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
        if (usedNonces.has(nonce)) {
            reply.code(401).send({
                error: 'Nonce Reused',
                message: 'This nonce has already been used',
            });
            return;
        }
        usedNonces.set(nonce, Date.now() + NONCE_TTL_MS);
        let bodyString = '';
        if (request.rawBody) {
            bodyString = request.rawBody.toString();
        } else if (request.body) {
            bodyString = JSON.stringify(request.body);
        }
        const bodyHash = crypto.createHash('sha256').update(bodyString).digest('hex');
        const message = `${timestamp}|${nonce}|${bodyHash}`;
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
    }
    catch (error) {
        console.error('Signature verification error:', error.message || error);
        reply.code(401).send({
            error: 'Signature Verification Failed',
            message: error.message || 'Could not verify request signature',
        });
    }
}

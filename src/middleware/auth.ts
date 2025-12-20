import { FastifyRequest, FastifyReply } from 'fastify';
import * as admin from 'firebase-admin';

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
}

const db = admin.firestore();

export interface AuthenticatedRequest extends FastifyRequest {
  user?: {
    uid: string;
    email?: string;
    hasActiveSubscription: boolean;
    isAdmin?: boolean;
    isDeveloper?: boolean;
  };
}

/**
 * Middleware to verify Firebase Auth token
 */
export async function verifyAuth(
  request: AuthenticatedRequest,
  reply: FastifyReply
): Promise<void> {
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
    const hasActiveSubscription =
      isAdmin ||
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
  } catch (error: any) {
    console.error('Auth error:', error);
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
export async function verifyAuthOnly(
  request: AuthenticatedRequest,
  reply: FastifyReply
): Promise<void> {
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
  } catch (error: any) {
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
export async function optionalAuth(
  request: AuthenticatedRequest,
  reply: FastifyReply
): Promise<void> {
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

      const hasActiveSubscription =
        isAdmin ||
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
  } catch (error) {
    // Invalid token, continue without user
    console.warn('Optional auth failed:', error);
  }
}

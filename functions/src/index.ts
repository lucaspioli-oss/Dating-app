import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express, { Request, Response } from 'express';
import cors from 'cors';
import { handleStripeWebhook } from './webhooks/stripe';
import { UserManager } from './services/user-manager';

// Initialize Firebase Admin
admin.initializeApp();

// Express app para webhooks
const app = express();
app.use(cors({ origin: true }));

// IMPORTANT: For Stripe webhooks, use express.raw() to get the raw body
// Stripe needs the raw body to verify the webhook signature
app.use('/stripe', express.raw({ type: 'application/json' }));
app.use(express.json());

/**
 * Webhook da Stripe
 * URL: https://us-central1-<project-id>.cloudfunctions.net/stripeWebhook/stripe
 *
 * Configure esta URL no painel da Stripe:
 * 1. Acesse: Developers > Webhooks
 * 2. Clique "Add endpoint"
 * 3. Cole a URL acima
 * 4. Selecione os eventos:
 *    - checkout.session.completed
 *    - customer.subscription.updated
 *    - customer.subscription.deleted
 *    - invoice.paid
 *    - invoice.payment_failed
 */
app.post('/stripe', async (req: Request, res: Response) => {
  return handleStripeWebhook(req, res);
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export const stripeWebhook = functions.https.onRequest(app);

/**
 * Função agendada para verificar assinaturas expiradas
 * Roda todo dia às 3:00 AM (horário UTC)
 */
export const checkExpiredSubscriptions = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    console.log('🕐 Running scheduled subscription check...');
    await UserManager.checkExpiredSubscriptions();
    return null;
  });

/**
 * Trigger quando um novo usuário é criado no Firebase Auth
 * Cria automaticamente o documento do usuário no Firestore
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    console.log('👤 New user created:', user.email);

    // Verificar se o documento já existe (pode ter sido criado pelo webhook)
    const existingUser = await UserManager.getUser(user.uid);
    if (existingUser) {
      console.log('✅ User document already exists');
      return;
    }

    // Criar documento do usuário sem assinatura
    await UserManager.createUser(
      user.uid,
      user.email || '',
      user.displayName || 'Usuário'
    );

    console.log('✅ User document created (no subscription)');

  } catch (error) {
    console.error('❌ Error creating user document:', error);
    throw error;
  }
});

/**
 * Trigger quando um usuário é deletado no Firebase Auth
 * Remove todos os dados associados (GDPR compliance)
 */
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  try {
    console.log('🗑️ User deleted:', user.email);

    const db = admin.firestore();
    const batch = db.batch();

    // Deletar documento do usuário
    batch.delete(db.collection('users').doc(user.uid));

    // Deletar perfil
    const profileDoc = db.collection('profiles').doc(user.uid);
    batch.delete(profileDoc);

    // Deletar analytics
    batch.delete(db.collection('analytics').doc(user.uid));

    // Deletar conversas
    const conversationsSnapshot = await db.collection('conversations')
      .where('userId', '==', user.uid)
      .get();

    conversationsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Deletar assinaturas
    const subscriptionsSnapshot = await db.collection('subscriptions')
      .where('userId', '==', user.uid)
      .get();

    subscriptionsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log('✅ User data deleted successfully');

  } catch (error) {
    console.error('❌ Error deleting user data:', error);
    throw error;
  }
});

/**
 * Função HTTPS para verificar status da assinatura de um usuário
 * Usada pelo backend para validar acesso
 */
export const checkSubscription = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;

  try {
    const user = await UserManager.getUser(userId);

    if (!user) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const now = new Date();
    const expiresAt = user.subscription.expiresAt;
    const isActive = user.subscription.status === 'active' &&
                     (!expiresAt || expiresAt > now);

    return {
      isActive,
      status: user.subscription.status,
      plan: user.subscription.plan,
      expiresAt: expiresAt || null,
    };

  } catch (error: any) {
    console.error('Error checking subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

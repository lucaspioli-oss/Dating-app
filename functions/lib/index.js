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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkSubscription = exports.onUserDeleted = exports.onUserCreated = exports.checkExpiredSubscriptions = exports.stripeWebhook = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const stripe_1 = require("./webhooks/stripe");
const user_manager_1 = require("./services/user-manager");
// Initialize Firebase Admin
admin.initializeApp();
// Express app para webhooks
const app = (0, express_1.default)();
app.use((0, cors_1.default)({
    origin: [
        'https://desenrola-ia.web.app',
        'https://desenrola-ia.firebaseapp.com',
    ],
}));
// IMPORTANT: For Stripe webhooks, use express.raw() to get the raw body
// Stripe needs the raw body to verify the webhook signature
app.use('/stripe', express_1.default.raw({ type: 'application/json' }));
app.use(express_1.default.json());
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
app.post('/stripe', async (req, res) => {
    return (0, stripe_1.handleStripeWebhook)(req, res);
});
// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
exports.stripeWebhook = functions.https.onRequest(app);
/**
 * Função agendada para verificar assinaturas expiradas
 * Roda todo dia às 3:00 AM (horário UTC)
 */
exports.checkExpiredSubscriptions = functions.pubsub
    .schedule('0 3 * * *')
    .timeZone('America/Sao_Paulo')
    .onRun(async (context) => {
    console.log('🕐 Running scheduled subscription check...');
    await user_manager_1.UserManager.checkExpiredSubscriptions();
    return null;
});
/**
 * Trigger quando um novo usuário é criado no Firebase Auth
 * Cria automaticamente o documento do usuário no Firestore
 */
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    try {
        console.log('New user created');
        // Verificar se o documento já existe (pode ter sido criado pelo webhook)
        const existingUser = await user_manager_1.UserManager.getUser(user.uid);
        if (existingUser) {
            console.log('✅ User document already exists');
            return;
        }
        // Criar documento do usuário sem assinatura
        await user_manager_1.UserManager.createUser(user.uid, user.email || '', user.displayName || 'Usuário');
        console.log('✅ User document created (no subscription)');
    }
    catch (error) {
        console.error('❌ Error creating user document:', error);
        throw error;
    }
});
/**
 * Trigger quando um usuário é deletado no Firebase Auth
 * Remove todos os dados associados (GDPR compliance)
 */
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
    try {
        console.log('User deleted');
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
    }
    catch (error) {
        console.error('❌ Error deleting user data:', error);
        throw error;
    }
});
/**
 * Função HTTPS para verificar status da assinatura de um usuário
 * Usada pelo backend para validar acesso
 */
exports.checkSubscription = functions.https.onCall(async (data, context) => {
    // Verificar autenticação
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }
    const userId = context.auth.uid;
    try {
        const user = await user_manager_1.UserManager.getUser(userId);
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
    }
    catch (error) {
        console.error('Error checking subscription:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=index.js.map
// Script para adicionar usuário com acesso ao app
// Uso: node scripts/add-user.js <email> <nome>

const admin = require('firebase-admin');

// Inicializar Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: 'desenrola-ia',
      clientEmail: 'firebase-adminsdk-fbsvc@desenrola-ia.iam.gserviceaccount.com',
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n') || require('dotenv').config({ path: '../.env' }).parsed?.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

const db = admin.firestore();

async function addUser(email, displayName) {
  console.log(`\n🚀 Adicionando usuário: ${email}`);

  try {
    // 1. Verificar se já existe no Auth
    let userRecord;
    let isNew = false;

    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log(`✅ Usuário já existe no Auth: ${userRecord.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Criar novo usuário com senha temporária
        const tempPassword = 'Temp123456!';
        userRecord = await admin.auth().createUser({
          email: email,
          password: tempPassword,
          displayName: displayName,
          emailVerified: true,
        });
        console.log(`✅ Usuário criado no Auth: ${userRecord.uid}`);
        console.log(`⚠️  Senha temporária: ${tempPassword}`);
        isNew = true;
      } else {
        throw error;
      }
    }

    // 2. Verificar/criar documento no Firestore
    const userDoc = await db.collection('users').doc(userRecord.uid).get();

    if (userDoc.exists) {
      // Atualizar subscription para active
      await db.collection('users').doc(userRecord.uid).update({
        'subscription.status': 'active',
        'subscription.plan': 'yearly',
        'subscription.expiresAt': new Date('2026-12-31'),
        needsPasswordSetup: isNew,
      });
      console.log(`✅ Subscription atualizada para active`);
    } else {
      // Criar documento completo
      const now = new Date();
      await db.collection('users').doc(userRecord.uid).set({
        id: userRecord.uid,
        email: email,
        displayName: displayName,
        createdAt: now,
        subscription: {
          status: 'active',
          plan: 'yearly',
          expiresAt: new Date('2026-12-31'),
        },
        stats: {
          totalConversations: 0,
          totalMessages: 0,
          aiSuggestionsUsed: 0,
        },
        needsPasswordSetup: isNew,
      });
      console.log(`✅ Documento do usuário criado no Firestore`);
    }

    console.log(`\n✅ Usuário ${email} liberado com sucesso!`);
    console.log(`📧 Email: ${email}`);
    console.log(`👤 Nome: ${displayName}`);
    console.log(`📅 Expira: 31/12/2026`);
    if (isNew) {
      console.log(`\n⚠️  O usuário deve definir uma nova senha em:`);
      console.log(`   https://app.desenrolaai.site/success?email=${encodeURIComponent(email)}`);
    }

  } catch (error) {
    console.error(`❌ Erro:`, error.message);
    process.exit(1);
  }
}

// Executar
const email = process.argv[2] || 'thiago.speridiao@uol.com';
const name = process.argv[3] || 'Thiago Speridião';

addUser(email, name).then(() => process.exit(0));

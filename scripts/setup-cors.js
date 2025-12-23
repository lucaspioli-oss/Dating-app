/**
 * Script para configurar CORS no Firebase Storage
 * Execute: node scripts/setup-cors.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Carregar variáveis de ambiente do .env
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Inicializar Firebase Admin
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
  storageBucket: 'desenrola-ia.firebasestorage.app',
});

async function setupCors() {
  try {
    const bucket = admin.storage().bucket();

    const corsConfiguration = [
      {
        origin: ['https://desenrola-ia.web.app', 'https://desenrola-ia.firebaseapp.com'],
        method: ['GET', 'HEAD'],
        maxAgeSeconds: 3600,
      },
    ];

    await bucket.setCorsConfiguration(corsConfiguration);
    console.log('✅ CORS configurado com sucesso!');

    // Verificar configuração
    const [metadata] = await bucket.getMetadata();
    console.log('Configuração atual:', JSON.stringify(metadata.cors, null, 2));

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao configurar CORS:', error.message);
    process.exit(1);
  }
}

setupCors();

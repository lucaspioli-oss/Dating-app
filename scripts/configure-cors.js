/**
 * Script para configurar CORS no Firebase Storage
 * Execute: node scripts/configure-cors.js
 */

const { Storage } = require('@google-cloud/storage');

// Usa as credenciais do ambiente
const storage = new Storage({
  projectId: process.env.FIREBASE_PROJECT_ID || 'desenrola-ia',
});

const bucketName = 'desenrola-ia.firebasestorage.app';

async function configureCors() {
  const corsConfiguration = [
    {
      origin: ['https://desenrola-ia.web.app', 'https://desenrola-ia.firebaseapp.com', 'http://localhost:3000'],
      method: ['GET', 'HEAD'],
      maxAgeSeconds: 3600,
    },
  ];

  try {
    await storage.bucket(bucketName).setCorsConfiguration(corsConfiguration);
    console.log(`CORS configurado com sucesso para ${bucketName}`);

    // Verificar configuração
    const [metadata] = await storage.bucket(bucketName).getMetadata();
    console.log('Configuração atual:', JSON.stringify(metadata.cors, null, 2));
  } catch (error) {
    console.error('Erro ao configurar CORS:', error.message);
    console.log('\nTente executar via Cloud Shell:');
    console.log('1. Acesse: https://console.cloud.google.com/storage/browser/desenrola-ia.firebasestorage.app');
    console.log('2. Abra o Cloud Shell (ícone de terminal no topo)');
    console.log('3. Execute:');
    console.log(`   echo '[{"origin": ["*"], "method": ["GET", "HEAD"], "maxAgeSeconds": 3600}]' > cors.json`);
    console.log(`   gsutil cors set cors.json gs://desenrola-ia.firebasestorage.app`);
  }
}

configureCors();

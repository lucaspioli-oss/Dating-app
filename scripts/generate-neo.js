/**
 * Script para gerar variações do personagem NEO usando Leonardo AI
 * Uso: node scripts/generate-neo.js
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const API_KEY = process.env.LEONARDO_API_KEY;
const BASE_URL = 'https://cloud.leonardo.ai/api/rest/v1';

// Configurações conservadoras para economizar créditos
const CONFIG = {
  model: '6b645e3a-d64f-4341-a6d8-7a3690fbf042', // Leonardo Phoenix
  width: 768,
  height: 1024, // Formato retrato para TikTok
  num_images: 1, // 1 por vez para controlar melhor
};

// Prompt base otimizado para o NEO - V4 (Watch Dogs + óculos + capuz)
const BASE_PROMPT = `Cinematic portrait of a mysterious young man around 25 years old, Watch Dogs aesthetic, wearing sleek black tech sunglasses that completely hide his eyes, black hood pulled up low over forehead creating shadow on face with only glasses and lower face visible, light stubble on jaw, serious neutral expression, black techwear tactical jacket with high collar and hood, dark urban alley background at night slightly out of focus, wet streets with cyan and magenta neon reflections, volumetric fog, dramatic cinematic lighting from the side, natural skin texture, anonymous hacker vigilante vibe, raw photograph shot on Canon R5 85mm f1.4, shallow depth of field, moody atmospheric, 8k detailed`;

const NEGATIVE_PROMPT = `pretty boy, fashion model, perfect skin, bright lighting, daylight, studio, plain background, mask, face mask, cartoon, anime, drawing, painting, illustration, 3d render, cgi, artificial, plastic, airbrushed, deformed, ugly, bad anatomy, blurry, low quality, text, watermark, smiling, old, wrinkles, bald`;

// Variações de roupa/estilo para os 4 vídeos
const VARIATIONS = [
  { name: 'neo-v1-hoodie-black', extra: ', simple black hoodie, minimalist' },
  { name: 'neo-v2-jacket-tech', extra: ', techwear tactical jacket with subtle details' },
  { name: 'neo-v3-hoodie-dark-gray', extra: ', dark gray hoodie, slightly different angle' },
  { name: 'neo-v4-layered', extra: ', layered look with hoodie under jacket' },
];

async function checkCredits() {
  try {
    const response = await fetch(`${BASE_URL}/users/me`, {
      headers: { 'Authorization': `Bearer ${API_KEY}` }
    });
    const data = await response.json();

    if (data.user_details && data.user_details.length > 0) {
      const details = data.user_details[0];
      const apiCredits = details.apiCredit?.total || 0;
      const subscriptionTokens = details.subscriptionTokens || 0;
      console.log(`💰 Créditos API: ${apiCredits} | Tokens: ${subscriptionTokens}`);
      return apiCredits;
    }
  } catch (error) {
    console.log('⚠️ Não foi possível verificar créditos');
  }
  return 0;
}

async function generateImage(prompt, name) {
  console.log(`\n🎨 Gerando: ${name}...`);

  // Criar geração
  const response = await fetch(`${BASE_URL}/generations`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt: prompt,
      negative_prompt: NEGATIVE_PROMPT,
      modelId: CONFIG.model,
      width: CONFIG.width,
      height: CONFIG.height,
      num_images: CONFIG.num_images,
      guidance_scale: 7,
      alchemy: false,
      photoReal: false,
      presetStyle: 'CINEMATIC',
    }),
  });

  const data = await response.json();

  if (!data.sdGenerationJob) {
    console.error('❌ Erro na geração:', JSON.stringify(data, null, 2));
    return null;
  }

  const generationId = data.sdGenerationJob.generationId;
  console.log(`⏳ Geração iniciada: ${generationId}`);

  // Aguardar conclusão (polling)
  let attempts = 0;
  while (attempts < 30) {
    await sleep(2000);

    const statusResponse = await fetch(`${BASE_URL}/generations/${generationId}`, {
      headers: { 'Authorization': `Bearer ${API_KEY}` }
    });
    const statusData = await statusResponse.json();

    const generation = statusData.generations_by_pk;
    if (generation && generation.status === 'COMPLETE') {
      const images = generation.generated_images;
      if (images && images.length > 0) {
        console.log(`✅ Imagem gerada!`);
        return images[0].url;
      }
    }

    attempts++;
    process.stdout.write('.');
  }

  console.error('❌ Timeout aguardando geração');
  return null;
}

async function downloadImage(url, filename) {
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  const outputDir = path.join(__dirname, '../public/assets/images/neo-variations');

  // Criar diretório se não existir
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const outputPath = path.join(outputDir, filename);
  fs.writeFileSync(outputPath, Buffer.from(buffer));
  console.log(`💾 Salvo: ${outputPath}`);
  return outputPath;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('🚀 Gerador de Variações do NEO');
  console.log('================================\n');

  if (!API_KEY) {
    console.error('❌ API Key não encontrada. Configure o arquivo .env');
    process.exit(1);
  }

  // Verificar créditos
  await checkCredits();

  // Perguntar ao usuário
  const args = process.argv.slice(2);
  const mode = args[0] || 'test';

  if (mode === 'test') {
    // Modo teste: gera apenas 1 imagem para validar
    console.log('\n📋 MODO TESTE: Gerando 1 imagem para validação...\n');

    const prompt = BASE_PROMPT + VARIATIONS[0].extra;
    const imageUrl = await generateImage(prompt, 'teste');

    if (imageUrl) {
      await downloadImage(imageUrl, 'neo-teste.png');
      console.log('\n✅ Teste concluído! Verifique a imagem em:');
      console.log('   public/assets/images/neo-variations/neo-teste.png');
      console.log('\n👉 Se aprovou, rode: node scripts/generate-neo.js all');
    }
  } else if (mode === 'all') {
    // Gera todas as variações
    console.log('\n📋 MODO COMPLETO: Gerando 4 variações...\n');

    for (const variation of VARIATIONS) {
      const prompt = BASE_PROMPT + variation.extra;
      const imageUrl = await generateImage(prompt, variation.name);

      if (imageUrl) {
        await downloadImage(imageUrl, `${variation.name}.png`);
      }

      // Pausa entre gerações
      await sleep(1000);
    }

    console.log('\n✅ Todas as variações geradas!');
    console.log('   Verifique em: public/assets/images/neo-variations/');
  } else if (mode === 'custom') {
    // Modo customizado: usa prompt do argumento
    const customPrompt = args.slice(1).join(' ');
    if (!customPrompt) {
      console.log('Uso: node scripts/generate-neo.js custom "seu prompt aqui"');
      process.exit(1);
    }

    console.log(`\n📋 MODO CUSTOM: ${customPrompt}\n`);
    const imageUrl = await generateImage(customPrompt, 'custom');

    if (imageUrl) {
      const timestamp = Date.now();
      await downloadImage(imageUrl, `neo-custom-${timestamp}.png`);
    }
  }

  // Verificar créditos restantes
  console.log('\n');
  await checkCredits();
}

main().catch(console.error);

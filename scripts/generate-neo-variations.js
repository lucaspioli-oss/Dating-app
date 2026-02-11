/**
 * Script para gerar 3 variações sutis do NEO com ajustes:
 * - Óculos mais sólidos/opacos (não transparentes)
 * - Sem franja visível (cabelo completamente sob o capuz)
 * - Capuz mais baixo na testa
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

const CONFIG = {
  model: '6b645e3a-d64f-4341-a6d8-7a3690fbf042', // Leonardo Phoenix
  width: 768,
  height: 1024,
  num_images: 1,
};

// Prompt base CORRIGIDO - óculos opacos, sem franja, capuz mais baixo
const BASE_PROMPT = `Cinematic portrait of a mysterious young man around 25 years old, Watch Dogs aesthetic, wearing thick dark opaque black sunglasses with solid black lenses that completely hide his eyes with no transparency, black hood pulled very low deep over forehead covering all hair completely with no bangs or hair visible creating deep shadow on upper face, clean shaved short hair hidden under hood, light stubble on jaw, serious neutral expression, black techwear tactical jacket with high collar and hood, dark urban alley background at night slightly out of focus, wet streets with cyan and magenta neon reflections, volumetric fog, dramatic cinematic lighting from the side, natural skin texture, anonymous hacker vigilante vibe, raw photograph shot on Canon R5 85mm f1.4, shallow depth of field, moody atmospheric, 8k detailed`;

const NEGATIVE_PROMPT = `transparent glasses, see-through lenses, visible eyes through glasses, bangs, fringe, hair on forehead, visible hair, messy hair, pretty boy, fashion model, perfect skin, bright lighting, daylight, studio, plain background, mask, face mask, cartoon, anime, drawing, painting, illustration, 3d render, cgi, artificial, plastic, airbrushed, deformed, ugly, bad anatomy, blurry, low quality, text, watermark, smiling, old, wrinkles, bald`;

// 3 variações sutis mantendo a consistência
const VARIATIONS = [
  {
    name: 'neo-var1-classic',
    extra: ', classic rectangular black sunglasses, hood edge at eyebrow level',
    description: 'Óculos retangulares clássicos, capuz na altura das sobrancelhas'
  },
  {
    name: 'neo-var2-angular',
    extra: ', angular sharp-edged black tactical sunglasses, hood pulled extra low almost touching glasses',
    description: 'Óculos angulares táticos, capuz bem baixo quase tocando os óculos'
  },
  {
    name: 'neo-var3-wrapped',
    extra: ', sleek wraparound black sunglasses sport style, deep hood shadowing entire upper face',
    description: 'Óculos wrap-around esportivos, capuz criando sombra profunda'
  },
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
      console.log(`\n💰 Créditos API: ${apiCredits} | Tokens: ${subscriptionTokens}`);
      return apiCredits;
    }
  } catch (error) {
    console.log('⚠️ Não foi possível verificar créditos');
  }
  return 0;
}

async function generateImage(prompt, name) {
  console.log(`\n🎨 Gerando: ${name}...`);

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
  console.log(`⏳ ID: ${generationId}`);

  // Polling para aguardar conclusão
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
        console.log(`✅ Concluído!`);
        return images[0].url;
      }
    }

    attempts++;
    process.stdout.write('.');
  }

  console.error('❌ Timeout');
  return null;
}

async function downloadImage(url, filename) {
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  const outputDir = path.join(__dirname, '../public/assets/images/neo-variations');

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const outputPath = path.join(outputDir, filename);
  fs.writeFileSync(outputPath, Buffer.from(buffer));
  console.log(`💾 Salvo: ${filename}`);
  return outputPath;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('🎭 Gerador de Variações NEO - Avatar TikTok');
  console.log('==========================================');
  console.log('\nAjustes aplicados:');
  console.log('  ✓ Óculos sólidos/opacos (sem transparência)');
  console.log('  ✓ Sem franja visível (cabelo sob o capuz)');
  console.log('  ✓ Capuz mais baixo na testa\n');

  if (!API_KEY) {
    console.error('❌ API Key não encontrada no .env');
    process.exit(1);
  }

  await checkCredits();

  console.log('\n📋 Gerando 3 variações...\n');

  const results = [];

  for (const variation of VARIATIONS) {
    console.log(`\n--- ${variation.description} ---`);
    const prompt = BASE_PROMPT + variation.extra;
    const imageUrl = await generateImage(prompt, variation.name);

    if (imageUrl) {
      const savedPath = await downloadImage(imageUrl, `${variation.name}.png`);
      results.push({ name: variation.name, path: savedPath, success: true });
    } else {
      results.push({ name: variation.name, success: false });
    }

    // Pausa entre gerações
    await sleep(1500);
  }

  console.log('\n==========================================');
  console.log('📊 RESULTADO:');
  results.forEach(r => {
    console.log(`  ${r.success ? '✅' : '❌'} ${r.name}`);
  });

  console.log('\n📁 Imagens salvas em:');
  console.log('   public/assets/images/neo-variations/');

  await checkCredits();
}

main().catch(console.error);

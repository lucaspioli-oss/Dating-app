/**
 * Refinamento do NEO var2 - mais natural, mandíbula menos marcada
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
  model: '6b645e3a-d64f-4341-a6d8-7a3690fbf042',
  width: 768,
  height: 1024,
  num_images: 1,
};

// Prompt refinado - mais natural, mandíbula suave
const BASE_PROMPT = `Candid street photograph of an average looking young man around 25 years old, natural soft facial features with normal jawline not too angular or defined, wearing angular black tactical sunglasses with dark opaque lenses, black hood pulled very low almost touching the top of glasses covering all hair completely, light stubble, relaxed neutral expression, black techwear jacket with hood, dark urban alley at night, wet streets with subtle cyan and magenta neon reflections in background, natural imperfect skin with pores and subtle blemishes, NOT a model just a regular guy, authentic documentary style photograph, shot on Sony A7III 50mm f1.8, realistic lighting, no retouching, raw unedited look`;

const NEGATIVE_PROMPT = `chiseled jaw, strong jawline, angular face, defined cheekbones, model face, handsome, pretty boy, perfect skin, airbrushed, plastic, CGI, 3D render, illustration, painting, cartoon, anime, overprocessed, HDR, oversaturated, perfect lighting, studio lighting, visible hair, bangs, fringe, transparent glasses, see-through lenses, smiling, old, wrinkles, deformed, ugly, blurry, low quality, text, watermark`;

const VARIATIONS = [
  {
    name: 'neo-v2-natural-a',
    extra: ', slightly round face shape, soft features, everyday person',
    description: 'Rosto mais arredondado, features suaves'
  },
  {
    name: 'neo-v2-natural-b',
    extra: ', oval face shape, relaxed jaw muscles, approachable look',
    description: 'Rosto oval, mandíbula relaxada'
  },
  {
    name: 'neo-v2-natural-c',
    extra: ', medium face shape, subtle jawline, photojournalistic style',
    description: 'Rosto médio, estilo fotojornalístico'
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
      console.log(`💰 Créditos: ${apiCredits}`);
      return apiCredits;
    }
  } catch (error) {
    console.log('⚠️ Erro ao verificar créditos');
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
      guidance_scale: 6, // Menor para mais naturalidade
      alchemy: false,
      photoReal: false,
      presetStyle: 'CINEMATIC',
    }),
  });

  const data = await response.json();

  if (!data.sdGenerationJob) {
    console.error('❌ Erro:', JSON.stringify(data, null, 2));
    return null;
  }

  const generationId = data.sdGenerationJob.generationId;
  console.log(`⏳ ID: ${generationId}`);

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
  console.log('🎭 NEO v2 Refinado - Mais Natural');
  console.log('==================================');
  console.log('\nAjustes:');
  console.log('  ✓ Rosto mais natural/comum');
  console.log('  ✓ Mandíbula menos marcada');
  console.log('  ✓ Mantendo: capuz baixo + óculos táticos\n');

  if (!API_KEY) {
    console.error('❌ API Key não encontrada');
    process.exit(1);
  }

  await checkCredits();

  for (const variation of VARIATIONS) {
    console.log(`\n--- ${variation.description} ---`);
    const prompt = BASE_PROMPT + variation.extra;
    const imageUrl = await generateImage(prompt, variation.name);

    if (imageUrl) {
      await downloadImage(imageUrl, `${variation.name}.png`);
    }
    await sleep(1500);
  }

  console.log('\n==================================');
  console.log('✅ Variações refinadas geradas!');
  await checkCredits();
}

main().catch(console.error);

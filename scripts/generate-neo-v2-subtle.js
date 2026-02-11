/**
 * NEO var2-angular com ajuste SUTIL - mesma vibe, menos cara de IA
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

// Prompt ORIGINAL do var2 que funcionou + sutis imperfeições
const BASE_PROMPT = `Cinematic portrait of a mysterious young man around 25 years old, Watch Dogs aesthetic, wearing angular sharp-edged black tactical sunglasses with dark opaque lenses, black hood pulled very low almost touching glasses covering all hair completely, light stubble on jaw, serious neutral expression, black techwear tactical jacket with high collar and hood, dark urban alley background at night slightly out of focus, wet streets with cyan and magenta neon reflections, volumetric fog, dramatic cinematic lighting from the side, anonymous hacker vigilante vibe, raw photograph shot on Canon R5 85mm f1.4, shallow depth of field, moody atmospheric, 8k detailed`;

// Negative prompt com foco em evitar perfeição artificial
const NEGATIVE_PROMPT = `perfect symmetrical face, perfect skin, airbrushed skin, plastic skin, CGI, 3D render, illustration, painting, cartoon, anime, overly smooth skin, poreless skin, visible hair, bangs, fringe, transparent glasses, smiling, deformed, ugly, blurry, low quality, text, watermark, logo`;

// 3 variações sutis - mesma vibe, pequenas imperfeições naturais
const VARIATIONS = [
  {
    name: 'neo-final-a',
    extra: ', subtle skin texture with natural pores, very slight asymmetry in face, tiny imperfections',
  },
  {
    name: 'neo-final-b',
    extra: ', natural skin with micro details, authentic human imperfections, slightly uneven skin tone',
  },
  {
    name: 'neo-final-c',
    extra: ', real skin texture visible, minor natural blemishes, genuine human features',
  },
];

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
    console.error('❌ Erro:', JSON.stringify(data, null, 2));
    return null;
  }

  const generationId = data.sdGenerationJob.generationId;
  console.log(`⏳ ID: ${generationId}`);

  let attempts = 0;
  while (attempts < 30) {
    await new Promise(r => setTimeout(r, 2000));
    const statusResponse = await fetch(`${BASE_URL}/generations/${generationId}`, {
      headers: { 'Authorization': `Bearer ${API_KEY}` }
    });
    const statusData = await statusResponse.json();
    const generation = statusData.generations_by_pk;

    if (generation && generation.status === 'COMPLETE') {
      const images = generation.generated_images;
      if (images && images.length > 0) {
        console.log(`✅ OK!`);
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
  console.log(`💾 ${filename}`);
  return outputPath;
}

async function main() {
  console.log('🎭 NEO Final - Vibe var2 + Imperfeições Sutis');
  console.log('=============================================\n');

  if (!API_KEY) {
    console.error('❌ API Key não encontrada');
    process.exit(1);
  }

  for (const variation of VARIATIONS) {
    const prompt = BASE_PROMPT + variation.extra;
    const imageUrl = await generateImage(prompt, variation.name);

    if (imageUrl) {
      await downloadImage(imageUrl, `${variation.name}.png`);
    }
    await new Promise(r => setTimeout(r, 1500));
  }

  console.log('\n✅ Pronto!');
}

main().catch(console.error);

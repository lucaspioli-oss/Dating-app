/**
 * Gera Neo nos 6 cenários do roteiro TikTok
 * Mantendo consistência visual do avatar aprovado
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

// Descrição base do Neo (consistente em todas as cenas)
const NEO_BASE = `young man around 25 years old, wearing angular black tactical sunglasses with dark opaque lenses, black hood pulled low almost touching glasses covering all hair completely, light stubble, serious neutral expression, black techwear hoodie jacket, natural skin texture with pores`;

const NEGATIVE_PROMPT = `different person, different face, different glasses, visible hair, bangs, fringe, transparent glasses, smiling, old, cartoon, anime, illustration, 3d render, cgi, plastic, airbrushed, deformed, ugly, blurry, low quality, text, watermark, logo, multiple people`;

// 6 cenários do roteiro
const SCENES = [
  {
    name: 'neo-scene-01-podcast',
    description: 'Mic de podcast, fundo escuro',
    prompt: `${NEO_BASE}, sitting in front of podcast microphone, dark simple background with subtle bookshelf, ring light reflection in glasses, intimate podcast studio vibe, medium shot, slightly above eye level angle, moody low key lighting, shot on iPhone, TikTok vertical format`,
  },
  {
    name: 'neo-scene-02-rooftop',
    description: 'Rooftop com cidade',
    prompt: `${NEO_BASE}, standing on rooftop balcony, city skyline behind him at golden hour sunset, wind slightly moving clothes, urban landscape with buildings and lights, medium shot, natural lighting, cinematic but real vibe, shot on iPhone, TikTok style`,
  },
  {
    name: 'neo-scene-03-walking-street',
    description: 'Andando na rua à noite',
    prompt: `${NEO_BASE}, walking on busy urban street at night, neon shop lights and cars in background, confident stride, selfie angle from front, motion blur on background, street photography style, ambient city lights, shot on iPhone, TikTok vertical format`,
  },
  {
    name: 'neo-scene-04-cafe',
    description: 'Sentado no café',
    prompt: `${NEO_BASE}, sitting at cafe table, coffee cup on table, casual relaxed posture, blurred people in background, natural daylight from window, warm ambient lighting, medium shot, authentic candid vibe, shot on iPhone, TikTok style`,
  },
  {
    name: 'neo-scene-05-close-up',
    description: 'Close parado',
    prompt: `${NEO_BASE}, close up portrait, looking directly at camera, neutral urban background out of focus, intense direct gaze, dramatic side lighting, intimate and confrontational vibe, shot on iPhone, TikTok vertical format`,
  },
  {
    name: 'neo-scene-06-bedroom',
    description: 'Quarto luz baixa',
    prompt: `${NEO_BASE}, sitting on sofa or bed in dim room, phone screen light reflecting on face, low key moody lighting, late night vibe, intimate vulnerable moment, medium close shot, shot on iPhone, TikTok style`,
  },
];

async function generateImage(prompt, name) {
  console.log(`\n🎬 Gerando: ${name}...`);

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
  const outputDir = path.join(__dirname, '../public/assets/images/neo-scenes');

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const outputPath = path.join(outputDir, filename);
  fs.writeFileSync(outputPath, Buffer.from(buffer));
  console.log(`💾 ${filename}`);
  return outputPath;
}

async function main() {
  console.log('🎭 NEO - Cenas do Roteiro TikTok');
  console.log('=================================\n');
  console.log('Cenários:');
  SCENES.forEach((s, i) => console.log(`  ${i + 1}. ${s.description}`));

  if (!API_KEY) {
    console.error('❌ API Key não encontrada');
    process.exit(1);
  }

  const results = [];

  for (const scene of SCENES) {
    const imageUrl = await generateImage(scene.prompt, scene.name);

    if (imageUrl) {
      await downloadImage(imageUrl, `${scene.name}.png`);
      results.push({ name: scene.name, desc: scene.description, success: true });
    } else {
      results.push({ name: scene.name, desc: scene.description, success: false });
    }
    await new Promise(r => setTimeout(r, 1500));
  }

  console.log('\n=================================');
  console.log('📊 RESULTADO:');
  results.forEach(r => console.log(`  ${r.success ? '✅' : '❌'} ${r.desc}`));
  console.log('\n📁 Imagens em: public/assets/images/neo-scenes/');
}

main().catch(console.error);

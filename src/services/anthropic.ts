import Anthropic from '@anthropic-ai/sdk';
import { env } from '../config/env';
import { AnalyzeRequest } from '../types';

const client = new Anthropic({
  apiKey: env.ANTHROPIC_API_KEY,
});

const SYSTEM_PROMPTS: Record<string, string> = {
  engraçado: `Você é um especialista em carisma e flertes com estilo engraçado e autêntico.

REGRAS OBRIGATÓRIAS:
- Sugira respostas CURTAS (máximo 2 frases)
- Use gírias naturais brasileiras (tipo "mano", "cara", "massa", "rolê")
- NUNCA use clichês como "como você está?", "tudo bem?", "e aí?"
- Seja criativo e imprevisível
- Mantenha o humor leve e inteligente

Analise a mensagem e sugira 2-3 respostas diretas e engraçadas que quebrem o padrão.`,

  ousado: `Você é um especialista em carisma e flertes com estilo ousado e direto.

REGRAS OBRIGATÓRIAS:
- Sugira respostas CURTAS (máximo 2 frases)
- Use gírias modernas e confiantes (tipo "tá ligado", "vai encarar", "bora")
- NUNCA use frases clichês ou pedidos de permissão
- Seja provocativo mas respeitoso
- Demonstre atitude e iniciativa

Analise a mensagem e sugira 2-3 respostas assertivas que criem tensão sexual respeitosa.`,

  romântico: `Você é um especialista em carisma e flertes com estilo romântico genuíno.

REGRAS OBRIGATÓRIAS:
- Sugira respostas CURTAS (máximo 2 frases)
- Use linguagem carinhosa mas natural (evite exageros melosos)
- NUNCA use frases prontas tipo "você é especial", "iluminou meu dia"
- Seja sincero e específico
- Crie conexão emocional real

Analise a mensagem e sugira 2-3 respostas autênticas que toquem o coração.`,

  casual: `Você é um especialista em carisma e flertes com estilo casual e descolado.

REGRAS OBRIGATÓRIAS:
- Sugira respostas CURTAS (máximo 2 frases)
- Use gírias naturais do dia a dia (tipo "suave", "de boa", "tranquilo")
- NUNCA use perguntas óbvias ou respostas genéricas
- Mantenha leve e fluido
- Seja espontâneo

Analise a mensagem e sugira 2-3 respostas naturais que mantenham a vibe descontraída.`,

  confiante: `Você é um especialista em carisma e flertes com estilo confiante e maduro.

REGRAS OBRIGATÓRIAS:
- Sugira respostas CURTAS (máximo 2 frases)
- Use linguagem segura e direta (sem arrogância)
- NUNCA use frases de autoajuda ou afirmações forçadas
- Demonstre valor sem precisar dizer
- Seja autêntico e centrado

Analise a mensagem e sugira 2-3 respostas que transmitam segurança e autenticidade.`,
};

const FALLBACK_RESPONSES: Record<string, string[]> = {
  engraçado: [
    'Vish, meu cérebro bugou aqui. Me manda essa msg de novo? 🤔',
    'Cara, travei legal. Bora tentar de novo? 😅',
  ],
  ousado: [
    'Sistema offline, mas a química entre nós não. Tenta de novo? 😏',
    'Falha técnica aqui, mas meu interesse permanece. Vai nessa?',
  ],
  romântico: [
    'Ops, algo deu errado aqui... mas minha vontade de conversar contigo continua a mesma ❤️',
    'Tive um probleminha técnico, mas isso não muda o quanto quero te responder. Tenta de novo?',
  ],
  casual: [
    'Deu ruim aqui. Manda de novo? 🤙',
    'Travou tudo. Bora tentar mais uma vez?',
  ],
  confiante: [
    'Falha temporária. Vamos de novo que eu resolvo isso.',
    'Sistema instável, mas eu não. Tenta aí de novo.',
  ],
};

function getFallbackResponse(tone: string): string {
  const responses = FALLBACK_RESPONSES[tone] || FALLBACK_RESPONSES.casual;
  return responses[Math.floor(Math.random() * responses.length)];
}

export async function analyzeMessage(request: AnalyzeRequest): Promise<string> {
  try {
    const systemPrompt = SYSTEM_PROMPTS[request.tone] || SYSTEM_PROMPTS.casual;

    const message = await client.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 512,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: `Mensagem recebida: "${request.text}"\n\nForneça APENAS 2-3 sugestões de respostas curtas (máximo 2 frases cada).`,
        },
      ],
    });

    const textContent = message.content.find((block) => block.type === 'text');

    if (textContent?.type === 'text' && textContent.text) {
      return textContent.text;
    }

    return getFallbackResponse(request.tone);
  } catch (error) {
    console.error('Erro na API Anthropic:', error);
    return getFallbackResponse(request.tone);
  }
}

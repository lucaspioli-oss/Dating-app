import Anthropic from '@anthropic-ai/sdk';
import { env } from '../config/env';
import { AnalyzeRequest } from '../types';
import { getSystemPromptForTone } from '../prompts';

const client = new Anthropic({
  apiKey: env.ANTHROPIC_API_KEY,
});

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
  expert: [
    'Sistema deu pau, mas frame mantido. Bora de novo.',
    'Erro técnico. Isso não muda nada entre a gente. Tenta aí.',
  ],
};

function getFallbackResponse(tone: string): string {
  const responses = FALLBACK_RESPONSES[tone] || FALLBACK_RESPONSES.casual;
  return responses[Math.floor(Math.random() * responses.length)];
}

export async function analyzeMessage(request: AnalyzeRequest): Promise<string> {
  try {
    // Selecionar o prompt correto baseado no tom (Básico/Avançado/Expert)
    const systemPrompt = getSystemPromptForTone(request.tone);

    const message = await client.messages.create({
      model: 'claude-sonnet-4-5-20250929',
      max_tokens: 512,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: `Mensagem recebida: "${request.text}"\n\nForneça APENAS 2-3 sugestões de respostas.`,
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

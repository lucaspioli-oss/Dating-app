"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeMessage = analyzeMessage;
const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));
const env_1 = require("../config/env");
const prompts_1 = require("../prompts");
const client = new sdk_1.default({
    apiKey: env_1.env.ANTHROPIC_API_KEY,
});
const FALLBACK_RESPONSES = {
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
function getFallbackResponse(tone) {
    const responses = FALLBACK_RESPONSES[tone] || FALLBACK_RESPONSES.casual;
    return responses[Math.floor(Math.random() * responses.length)];
}
async function analyzeMessage(request) {
    try {
        // Selecionar o prompt correto baseado no tom (Básico/Avançado/Expert)
        const systemPrompt = (0, prompts_1.getSystemPromptForTone)(request.tone);
        const message = await client.messages.create({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 512,
            system: systemPrompt,
            messages: [
                {
                    role: 'user',
                    content: `${request.text}\n\nIMPORTANTE: Retorne APENAS as sugestões de resposta numeradas (1. 2. 3.). NÃO inclua análise, explicações, headers, red flags, grau de investimento, raciocínio ou qualquer outro texto. SOMENTE as mensagens prontas para enviar.`,
                },
            ],
        });
        const textContent = message.content.find((block) => block.type === 'text');
        if (textContent?.type === 'text' && textContent.text) {
            return textContent.text;
        }
        return getFallbackResponse(request.tone);
    }
    catch (error) {
        console.error('Erro na API Anthropic:', error);
        return getFallbackResponse(request.tone);
    }
}

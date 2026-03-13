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
        // Add language/culture directive if specified
        const langDirective = request.language ? (0, prompts_1.getLanguageDirective)(request.language) : '';
        const fullSystemPrompt = langDirective
            ? `${systemPrompt}\n\n═══════════════════════════════════════════════════════════════════\n🌍 DIRETIVA DE IDIOMA E CULTURA\n═══════════════════════════════════════════════════════════════════\n${langDirective}\n\nTODAS as sugestões DEVEM ser escritas neste idioma, usando o estilo descrito acima.`
            : systemPrompt;
        const outputInstruction = request.language === 'en'
            ? `\n\nIMPORTANT: Return ONLY the numbered response suggestions (1. 2. 3.). Do NOT include analysis, explanations, headers, red flags, investment level, reasoning, or any other text. ONLY ready-to-send messages.\n\nThe 3 suggestions must have DIFFERENT styles:\n1. A short, direct response\n2. A more elaborate, engaging response\n3. A creative/bold response`
            : request.language === 'es'
            ? `\n\nIMPORTANTE: Retorna SOLO las sugerencias de respuesta numeradas (1. 2. 3.). NO incluyas análisis, explicaciones, headers, red flags, nivel de inversión, razonamiento ni ningún otro texto. SOLO mensajes listos para enviar.\n\nLas 3 sugerencias deben tener estilos DIFERENTES:\n1. Una respuesta corta y directa\n2. Una respuesta más elaborada y envolvente\n3. Una respuesta creativa/atrevida`
            : `\n\nIMPORTANTE: Retorne APENAS as sugestões de resposta numeradas (1. 2. 3.). NÃO inclua análise, explicações, headers, red flags, grau de investimento, raciocínio ou qualquer outro texto. SOMENTE as mensagens prontas para enviar.\n\nAs 3 sugestões devem ter estilos DIFERENTES entre si:\n1. Uma resposta curta e direta\n2. Uma resposta mais elaborada e envolvente\n3. Uma resposta criativa/ousada`;
        const message = await client.messages.create({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 512,
            temperature: 0.85,
            system: fullSystemPrompt,
            messages: [
                {
                    role: 'user',
                    content: `${request.text}${outputInstruction}`,
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

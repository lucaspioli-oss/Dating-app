"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConversationReplyAgent = void 0;
const base_agent_1 = require("./base-agent");
class ConversationReplyAgent extends base_agent_1.BaseAgent {
    async execute(input, userContext) {
        const systemPrompt = this.buildSystemPrompt(input.tone);
        const userPrompt = this.buildUserPrompt(input, userContext);
        return await this.callClaude(systemPrompt, userPrompt);
    }
    buildSystemPrompt(tone) {
        const toneInstructions = {
            engraçado: 'Tom ENGRAÇADO: Use humor natural e espontâneo. Seja engraçado sem forçar piadas. Adapte-se ao humor da outra pessoa.',
            ousado: 'Tom OUSADO: Seja confiante e um pouco provocante, mas sempre respeitoso. Flerte sutil é bem-vindo.',
            romântico: 'Tom ROMÂNTICO: Seja charmoso e genuíno. Demonstre interesse real e faça a pessoa se sentir especial.',
            casual: 'Tom CASUAL: Seja natural e descontraído. Como se estivesse conversando com um amigo que está conhecendo.',
            confiante: 'Tom CONFIANTE: Demonstre segurança e seja direto. Mostre que sabe o que quer mas sem ser arrogante.',
        };
        return `Você é um assistente especializado em criar respostas atraentes para conversas de namoro.

${toneInstructions[tone]}

PRINCÍPIOS FUNDAMENTAIS:
✅ SEMPRE mantenha a conversa fluindo naturalmente
✅ SEMPRE faça perguntas abertas interessantes
✅ SEMPRE demonstre interesse genuíno
✅ SEMPRE seja você mesmo (baseado no perfil do usuário)
❌ NUNCA seja monótono ou previsível
❌ NUNCA responda apenas com "sim/não"
❌ NUNCA force assuntos que a pessoa evitou
❌ NUNCA ignore o contexto da conversa

ESTRUTURA IDEAL DE RESPOSTA:
1. Reaja à mensagem recebida (mostre que leu/entendeu)
2. Adicione algo seu (opinião, piada, história curta)
3. Faça uma pergunta ou deixe gancho para resposta

Seja conciso: 1-3 frases no máximo.`;
    }
    buildUserPrompt(input, userContext) {
        const parts = [];
        // Contexto do usuário
        if (userContext) {
            parts.push(this.buildUserContext(userContext));
        }
        // Histórico da conversa
        if (input.conversationHistory && input.conversationHistory.length > 0) {
            parts.push('=== HISTÓRICO DA CONVERSA ===');
            input.conversationHistory.forEach((msg) => {
                const label = msg.sender === 'user' ? 'Você' : input.matchName || 'Match';
                parts.push(`${label}: ${msg.message}`);
            });
            parts.push('');
        }
        // Mensagem recebida
        parts.push('=== MENSAGEM RECEBIDA ===');
        const matchLabel = input.matchName || 'Match';
        parts.push(`${matchLabel}: ${input.receivedMessage}`);
        // Contexto adicional
        if (input.context) {
            parts.push(`\nContexto: ${input.context}`);
        }
        parts.push('\n=== SUA TAREFA ===');
        parts.push(`Crie 3 opções de resposta com tom ${input.tone}.`);
        parts.push('Considere o histórico da conversa e o perfil do usuário.');
        parts.push('Mantenha a conversa interessante e fluindo!');
        parts.push('\nFormato: Apenas as 3 respostas numeradas, sem explicações.');
        return parts.join('\n');
    }
}
exports.ConversationReplyAgent = ConversationReplyAgent;

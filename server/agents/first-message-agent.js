"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirstMessageAgent = void 0;
const base_agent_1 = require("./base-agent");
class FirstMessageAgent extends base_agent_1.BaseAgent {
    async execute(input, userContext) {
        const systemPrompt = this.buildSystemPrompt(input.tone, input.collectiveInsights);
        const userPrompt = this.buildUserPrompt(input, userContext);
        return await this.callClaude(systemPrompt, userPrompt);
    }
    buildSystemPrompt(tone, insights) {
        const toneInstructions = {
            engraçado: 'Humor leve e natural.',
            ousado: 'Confiante e direto, flerte sutil.',
            romântico: 'Charmoso, elogio simples.',
            casual: 'Descontraído, de boa.',
            confiante: 'Seguro mas tranquilo.',
        };
        let prompt = `Gere primeiras mensagens curtas e naturais (5-10 palavras).

TOM: ${tone} - ${toneInstructions[tone]}

DIRETRIZES GERAIS:
- Mensagens curtas (5-10 palavras)
- Pode usar "kkk" ou "haha" pra ficar leve
- Parecer natural, não calculado
`;
        // Se tem insights da inteligência coletiva, usa eles
        if (insights) {
            if (insights.matchedTags && insights.matchedTags.length > 0) {
                prompt += `
📊 PERFIL IDENTIFICADO: ${insights.matchedTags.join(', ')}
(Insights baseados em perfis similares)
`;
            }
            if (insights.whatWorks && insights.whatWorks.length > 0) {
                prompt += `
✅ O QUE FUNCIONA COM ESSE TIPO DE PERFIL:
${insights.whatWorks.slice(0, 3).map(w => `- ${w}`).join('\n')}
`;
            }
            if (insights.whatDoesntWork && insights.whatDoesntWork.length > 0) {
                prompt += `
❌ O QUE NÃO FUNCIONA (EVITE):
${insights.whatDoesntWork.slice(0, 3).map(w => `- ${w}`).join('\n')}
`;
            }
            if (insights.goodOpenerExamples && insights.goodOpenerExamples.length > 0) {
                prompt += `
📊 EXEMPLOS QUE GERARAM RESPOSTA:
${insights.goodOpenerExamples.slice(0, 3).map(e => `✅ "${e}"`).join('\n')}
`;
            }
            if (insights.badOpenerExamples && insights.badOpenerExamples.length > 0) {
                prompt += `
📊 EXEMPLOS QUE NÃO FUNCIONARAM:
${insights.badOpenerExamples.slice(0, 2).map(e => `❌ "${e}"`).join('\n')}
`;
            }
            if (insights.bestOpenerTypes && insights.bestOpenerTypes.length > 0) {
                prompt += `
🎯 TIPOS DE OPENER QUE FUNCIONAM MELHOR:
${insights.bestOpenerTypes.slice(0, 3).map(t => `- ${t}`).join('\n')}
`;
            }
        }
        else {
            // Sem dados da inteligência coletiva, usa diretrizes básicas
            prompt += `
EVITE:
- Começar com "Oi/Olá nome"
- Perguntas (nada com "?")
- Piadas muito elaboradas
- Misturar idiomas

FUNCIONA BEM:
- Comentário rápido sobre algo do perfil
- Observação leve + kkk
- Ser direto sem forçar
`;
        }
        prompt += `
Retorne 3 opções numeradas. Sem explicações.`;
        return prompt;
    }
    buildUserPrompt(input, userContext) {
        const parts = [];
        if (userContext) {
            parts.push(this.buildUserContext(userContext));
        }
        parts.push('=== PERFIL ===');
        parts.push(`Nome: ${input.matchName}`);
        parts.push(`Plataforma: ${input.platform}`);
        parts.push(`Bio: ${input.matchBio}`);
        if (input.photoDescription) {
            parts.push(`Fotos: ${input.photoDescription}`);
        }
        if (input.specificDetail) {
            parts.push(`Detalhe: ${input.specificDetail}`);
        }
        parts.push('\nCrie 3 opções de primeira mensagem.');
        return parts.join('\n');
    }
}
exports.FirstMessageAgent = FirstMessageAgent;

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfileAnalyzerAgent = void 0;
const base_agent_1 = require("./base-agent");
class ProfileAnalyzerAgent extends base_agent_1.BaseAgent {
    async execute(input, userContext) {
        const systemPrompt = this.buildSystemPrompt();
        const userPrompt = this.buildUserPrompt(input, userContext);
        return await this.callClaude(systemPrompt, userPrompt);
    }
    buildSystemPrompt() {
        return `Você é um especialista em análise de perfis de apps de namoro e estratégias de abordagem.

Sua função é analisar perfis (bio, fotos descritas, etc.) e fornecer:
1. **Análise da Personalidade**: Deduzir traços de personalidade, interesses e vibe da pessoa
2. **Pontos de Conexão**: Identificar tópicos em comum e ganchos para conversa
3. **Estratégia de Abordagem**: Sugerir o melhor tom e tipo de primeira mensagem
4. **Red Flags**: Alertar sobre possíveis incompatibilidades ou sinais de alerta
5. **Sugestões de Opener**: 2-3 ideias de primeira mensagem personalizadas

Seja ESPECÍFICO e CRIATIVO. Evite conselhos genéricos.
Use análise psicológica sutil baseada nas pistas do perfil.`;
    }
    buildUserPrompt(input, userContext) {
        const parts = [];
        // Contexto do usuário
        if (userContext) {
            parts.push(this.buildUserContext(userContext));
        }
        // Informações do perfil a analisar
        parts.push('=== PERFIL PARA ANALISAR ===');
        parts.push(`Plataforma: ${input.platform.toUpperCase()}`);
        if (input.name) {
            parts.push(`Nome: ${input.name}`);
        }
        if (input.age) {
            parts.push(`Idade: ${input.age}`);
        }
        parts.push(`\nBio:\n${input.bio}`);
        if (input.photoDescription) {
            parts.push(`\nDescrição da foto/perfil:\n${input.photoDescription}`);
        }
        parts.push('\n=== SUA TAREFA ===');
        parts.push('Analise este perfil e forneça:');
        parts.push('1. Análise da personalidade (2-3 frases)');
        parts.push('2. Pontos de conexão com o usuário (baseado no contexto)');
        parts.push('3. Estratégia de abordagem recomendada');
        parts.push('4. 2-3 sugestões de primeira mensagem CRIATIVAS e PERSONALIZADAS');
        parts.push('\nSeja direto, criativo e evite clichês!');
        return parts.join('\n');
    }
}
exports.ProfileAnalyzerAgent = ProfileAnalyzerAgent;

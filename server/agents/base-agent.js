"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BaseAgent = void 0;
const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));
const env_1 = require("../config/env");
const prompts_1 = require("../prompts");
class BaseAgent {
    client;
    model = 'claude-sonnet-4-5-20250929';
    language = null;
    constructor() {
        this.client = new sdk_1.default({
            apiKey: env_1.env.ANTHROPIC_API_KEY,
        });
    }
    setLanguage(language) {
        this.language = language;
        return this;
    }
    /**
     * Gera o contexto do usuário formatado para o prompt
     */
    buildUserContext(userContext) {
        if (!userContext)
            return '';
        const parts = [];
        parts.push('=== CONTEXTO DO USUÁRIO ===');
        if (userContext.name) {
            parts.push(`Nome: ${userContext.name}`);
        }
        if (userContext.age) {
            parts.push(`Idade: ${userContext.age} anos`);
        }
        if (userContext.gender) {
            parts.push(`Gênero: ${userContext.gender}`);
        }
        if (userContext.interests && userContext.interests.length > 0) {
            parts.push(`Interesses: ${userContext.interests.join(', ')}`);
        }
        if (userContext.dislikes && userContext.dislikes.length > 0) {
            parts.push(`Não gosta de: ${userContext.dislikes.join(', ')}`);
            parts.push(`⚠️ IMPORTANTE: Evite mencionar ou fazer piadas sobre estes tópicos!`);
        }
        if (userContext.humorStyle) {
            parts.push(`Estilo de humor: ${userContext.humorStyle}`);
        }
        if (userContext.relationshipGoal) {
            parts.push(`Objetivo: ${userContext.relationshipGoal}`);
        }
        if (userContext.bio) {
            parts.push(`Sobre: ${userContext.bio}`);
        }
        parts.push('=== FIM DO CONTEXTO ===\n');
        return parts.join('\n');
    }
    /**
     * Chama a API da Anthropic
     */
    async callClaude(systemPrompt, userPrompt) {
        // Inject language directive if set
        let finalSystemPrompt = systemPrompt;
        if (this.language) {
            const langDirective = (0, prompts_1.getLanguageDirective)(this.language);
            finalSystemPrompt = `${systemPrompt}\n\n🌍 DIRETIVA DE IDIOMA:\n${langDirective}\n\nTODAS as sugestões DEVEM ser escritas neste idioma.`;
        }
        const message = await this.client.messages.create({
            model: this.model,
            max_tokens: 1024,
            temperature: 0.85,
            system: finalSystemPrompt,
            messages: [
                {
                    role: 'user',
                    content: userPrompt,
                },
            ],
        });
        const content = message.content[0];
        if (content.type === 'text') {
            return content.text;
        }
        throw new Error('Resposta inesperada da API');
    }
}
exports.BaseAgent = BaseAgent;

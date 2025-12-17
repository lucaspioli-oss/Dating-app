import Anthropic from '@anthropic-ai/sdk';
import { env } from '../config/env';

export interface UserContext {
  name?: string;
  age?: number;
  gender?: string;
  interests?: string[];
  dislikes?: string[];
  humorStyle?: string;
  relationshipGoal?: string;
  bio?: string;
}

export abstract class BaseAgent {
  protected client: Anthropic;
  protected model: string = 'claude-sonnet-4-5-20250929';

  constructor() {
    this.client = new Anthropic({
      apiKey: env.ANTHROPIC_API_KEY,
    });
  }

  /**
   * Método abstrato que cada agente deve implementar
   */
  abstract execute(input: any, userContext?: UserContext): Promise<string>;

  /**
   * Gera o contexto do usuário formatado para o prompt
   */
  protected buildUserContext(userContext?: UserContext): string {
    if (!userContext) return '';

    const parts: string[] = [];

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
  protected async callClaude(systemPrompt: string, userPrompt: string): Promise<string> {
    const message = await this.client.messages.create({
      model: this.model,
      max_tokens: 1024,
      system: systemPrompt,
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

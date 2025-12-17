import { BaseAgent, UserContext } from './base-agent';

export interface InstagramOpenerInput {
  username: string;
  bio?: string;
  recentPosts?: string[]; // Descrições dos últimos posts
  stories?: string[]; // Descrições de stories recentes
  tone: 'engraçado' | 'ousado' | 'romântico' | 'casual' | 'confiante';
  approachType: 'dm_direto' | 'comentario_post' | 'resposta_story';
  specificPost?: string; // Post específico para comentar/responder
}

export class InstagramOpenerAgent extends BaseAgent {
  async execute(input: InstagramOpenerInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.tone, input.approachType);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(tone: string, approachType: string): string {
    const approachInstructions = {
      dm_direto: 'DM DIRETO: Seja confiante mas não invasivo. Mostre que você realmente olhou o perfil. Evite parecer desesperado ou stalker.',
      comentario_post: 'COMENTÁRIO EM POST: Seja engajador e genuíno. O comentário deve se destacar mas não ser exagerado. Pode ser engraçado ou admirador.',
      resposta_story: 'RESPOSTA A STORY: Seja casual e natural. Reaja ao conteúdo do story de forma autêntica. Crie abertura para conversa.',
    };

    const toneInstructions = {
      engraçado: 'Tom ENGRAÇADO: Use humor inteligente relacionado ao conteúdo. Seja criativo mas não forçado.',
      ousado: 'Tom OUSADO: Seja direto e confiante, com um toque de flerte sutil mas respeitoso.',
      romântico: 'Tom ROMÂNTICO: Seja charmoso e admirador, mas sem parecer exagerado ou fake.',
      casual: 'Tom CASUAL: Seja descontraído, como se fosse apenas um amigo reagindo naturalmente.',
      confiante: 'Tom CONFIANTE: Mostre segurança e interesse real sem soar arrogante.',
    };

    return `Você é um especialista em abordagens pelo Instagram que geram respostas.

${approachInstructions[approachType as keyof typeof approachInstructions]}
${toneInstructions[tone as keyof typeof toneInstructions]}

REGRAS DO INSTAGRAM:
❌ NUNCA envie mensagens longas demais
❌ NUNCA seja invasivo ou insistente
❌ NUNCA elogie só a aparência física
✅ SEMPRE mencione algo específico do conteúdo
✅ SEMPRE deixe espaço para resposta natural
✅ SEMPRE seja autêntico

FORMATO: Retorne 2-3 opções de abordagem, cada uma em 1-2 frases no máximo.`;
  }

  private buildUserPrompt(input: InstagramOpenerInput, userContext?: UserContext): string {
    const parts: string[] = [];

    // Contexto do usuário
    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    // Informações do perfil do Instagram
    parts.push('=== PERFIL DO INSTAGRAM ===');
    parts.push(`Username: @${input.username}`);

    if (input.bio) {
      parts.push(`\nBio:\n${input.bio}`);
    }

    if (input.recentPosts && input.recentPosts.length > 0) {
      parts.push(`\nÚltimos posts:`);
      input.recentPosts.forEach((post, i) => {
        parts.push(`${i + 1}. ${post}`);
      });
    }

    if (input.stories && input.stories.length > 0) {
      parts.push(`\nStories recentes:`);
      input.stories.forEach((story, i) => {
        parts.push(`${i + 1}. ${story}`);
      });
    }

    if (input.specificPost) {
      parts.push(`\n⭐ POST/STORY PARA INTERAGIR:\n${input.specificPost}`);
    }

    parts.push('\n=== SUA TAREFA ===');
    parts.push(`Tipo de abordagem: ${input.approachType.replace('_', ' ').toUpperCase()}`);
    parts.push(`Tom: ${input.tone}`);
    parts.push('\nCrie 2-3 opções de mensagem/comentário.');
    parts.push('Seja específico, criativo e memorável!');
    parts.push('\nFormato: Apenas as opções numeradas, sem explicações.');

    return parts.join('\n');
  }
}

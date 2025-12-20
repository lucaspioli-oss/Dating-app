import { BaseAgent, UserContext } from './base-agent';

export interface InstagramOpenerInput {
  username: string;
  bio?: string;
  recentPosts?: string[];
  stories?: string[];
  tone: 'engraçado' | 'ousado' | 'romântico' | 'casual' | 'confiante';
  approachType: 'dm_direto' | 'comentario_post' | 'resposta_story';
  specificPost?: string;
  // Insights da inteligência coletiva por características
  collectiveInsights?: {
    whatWorks?: string[];
    whatDoesntWork?: string[];
    goodOpenerExamples?: string[];
    badOpenerExamples?: string[];
    bestOpenerTypes?: string[];
    matchedTags?: string[]; // Tags do perfil que tiveram match (ex: praia, pagode)
  };
}

export class InstagramOpenerAgent extends BaseAgent {
  async execute(input: InstagramOpenerInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.tone, input.approachType, input.collectiveInsights);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(
    tone: string,
    approachType: string,
    insights?: InstagramOpenerInput['collectiveInsights']
  ): string {
    const approachInstructions = {
      dm_direto: 'DM DIRETO: Curto e natural.',
      comentario_post: 'COMENTÁRIO: Algo que você realmente comentaria.',
      resposta_story: 'STORY: Reação casual.',
    };

    const toneInstructions = {
      engraçado: 'Humor simples.',
      ousado: 'Flerte leve.',
      romântico: 'Elogio simples.',
      casual: 'Super natural.',
      confiante: 'Seguro mas tranquilo.',
    };

    let prompt = `Crie abordagens curtas pro Instagram.

${approachInstructions[approachType as keyof typeof approachInstructions]}
Tom: ${toneInstructions[tone as keyof typeof toneInstructions]}

DIRETRIZES:
- Uma frase só
- Pode usar "kkk" ou emoji
- Parecer natural, não calculado
`;

    // Se tem insights da inteligência coletiva
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
    } else {
      prompt += `
EVITE:
- Perguntas
- "Aposto que...", "Com certeza..."
- Elogios exagerados
- Misturar idiomas
`;
    }

    prompt += `
Retorne 2-3 opções numeradas. Sem explicações.`;

    return prompt;
  }

  private buildUserPrompt(input: InstagramOpenerInput, userContext?: UserContext): string {
    const parts: string[] = [];

    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    parts.push('=== PERFIL ===');
    parts.push(`Username: @${input.username}`);

    if (input.bio) {
      parts.push(`Bio: ${input.bio}`);
    }

    if (input.recentPosts && input.recentPosts.length > 0) {
      parts.push(`Posts: ${input.recentPosts.slice(0, 3).join(', ')}`);
    }

    if (input.stories && input.stories.length > 0) {
      parts.push(`Stories: ${input.stories.slice(0, 2).join(', ')}`);
    }

    if (input.specificPost) {
      parts.push(`Interagir com: ${input.specificPost}`);
    }

    parts.push(`\nTipo: ${input.approachType.replace('_', ' ')}`);
    parts.push('\nCrie 2-3 opções.');

    return parts.join('\n');
  }
}

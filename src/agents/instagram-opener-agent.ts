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
      dm_direto: 'DM DIRETO: Curto e de boa. Sem parecer que você ficou stalkeando o perfil.',
      comentario_post: 'COMENTÁRIO: Natural e leve. Tipo algo que você realmente comentaria.',
      resposta_story: 'STORY: Reação casual, como se tivesse visto de passagem e achou interessante.',
    };

    const toneInstructions = {
      engraçado: 'Humor simples. Uma observação engraçada, não uma piada elaborada.',
      ousado: 'Direto mas de boa. Flerte leve.',
      romântico: 'Charmoso sem exagero. Elogio simples.',
      casual: 'Super natural, como se fosse qualquer pessoa reagindo.',
      confiante: 'Seguro mas tranquilo. Não tá tentando impressionar.',
    };

    return `Você cria abordagens LEVES pro Instagram.

PRINCÍPIO: Uma reação simples e pronto. Não precisa dar continuidade nem fazer pergunta.

${approachInstructions[approachType as keyof typeof approachInstructions]}
Tom: ${toneInstructions[tone as keyof typeof toneInstructions]}

EVITE:
- Fazer PERGUNTAS (parece entrevista)
- Observação + pergunta (investindo demais)
- "Aposto que...", "Com certeza você..."
- Elogios exagerados
- MISTURAR IDIOMAS. Use só português brasileiro
- Só use outro idioma se o perfil indicar que a pessoa é de outro país

FUNCIONA:
- UMA reação curta e só
- Pode usar "kkk" ou emoji pra ficar leve
- Parecer que foi de passagem
- Deixar a pessoa responder se quiser

EXEMPLOS BOM:
✅ "esse lugar parece ser incrível"
✅ "a vibe dessa foto kkk"
✅ "curti demais"

FORMATO: 2-3 opções. Cada uma com UMA frase só.`;
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
    parts.push(`Tipo: ${input.approachType.replace('_', ' ')}`);
    parts.push(`Tom: ${input.tone}`);
    parts.push('\nCrie 2-3 opções curtas e naturais.');
    parts.push('Menos é mais. Não force.');
    parts.push('\nFormato: Apenas as opções numeradas, sem explicações.');

    return parts.join('\n');
  }
}

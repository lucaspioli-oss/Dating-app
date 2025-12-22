import { BaseAgent, UserContext } from './base-agent';

export interface InstagramOpenerInput {
  username: string;
  bio?: string;
  recentPosts?: string[];
  stories?: string[];
  approachType: 'dm_direto' | 'comentario_post' | 'resposta_story';
  specificPost?: string;
  // Insights da inteligência coletiva por características
  collectiveInsights?: {
    whatWorks?: string[];
    whatDoesntWork?: string[];
    goodOpenerExamples?: string[];
    badOpenerExamples?: string[];
    bestOpenerTypes?: string[];
    matchedTags?: string[];
  };
}

export class InstagramOpenerAgent extends BaseAgent {
  async execute(input: InstagramOpenerInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.approachType, input.collectiveInsights);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(
    approachType: string,
    insights?: InstagramOpenerInput['collectiveInsights']
  ): string {
    const approachContext = {
      dm_direto: `TIPO: DM DIRETO
Ela não te conhece. Você precisa quebrar a barreira inicial.
Foco: Mostrar interesse genuíno em algo ESPECÍFICO do conteúdo dela.`,
      comentario_post: `TIPO: COMENTÁRIO EM POST
Comente como alguém que realmente se interessou pelo conteúdo.
Foco: O que ela POSTOU, não a aparência dela. Seja genuíno ou engraçado.`,
      resposta_story: `TIPO: RESPOSTA DE STORY
Reaja ao momento, lugar ou situação - não à aparência.
Foco: Casual e natural, como reagiria um amigo. Puxe assunto a partir do story.`,
    };

    let prompt = `Você é um expert em criar abordagens para Instagram.

CONTEXTO: Diferente de apps, aqui NÃO houve match. Ela recebe dezenas de mensagens genéricas.
Você precisa se destacar e quebrar a barreira inicial.

${approachContext[approachType as keyof typeof approachContext]}

═══════════════════════════════════════════════════════════════════
🎯 PROCESSO MENTAL (siga nessa ordem)
═══════════════════════════════════════════════════════════════════

PASSO 1 - ENCONTRE O GANCHO NO CONTEÚDO:
Analise e identifique o elemento mais interessante pra comentar:
- O que ela postou/mostrou no story? (lugar, atividade, objeto, momento)
- Algo na bio que revela um interesse específico?
- Algo que você genuinamente achou interessante ou curioso?
- O que 90% dos caras NÃO vão comentar? (eles vão elogiar aparência)

PASSO 2 - ESCOLHA A ESTRUTURA:
Adapte ao tipo de abordagem e ao conteúdo encontrado:

A) COMENTÁRIO GENUÍNO + PERGUNTA LEVE
   "Esse [lugar/coisa] é incrível, você [pergunta relacionada]?"

B) OPINIÃO/REAÇÃO NATURAL
   "[Reação ao conteúdo] - isso me lembrou [conexão pessoal breve]"

C) SUGESTÃO DE VALOR
   "Se você curte [tema do post], precisa conhecer [sugestão relacionada]"

D) OBSERVAÇÃO DIVERTIDA
   "[Detalhe do post/story] tem energia de [comparação engraçada] kkk"

PASSO 3 - APLIQUE O TOM:
Priorize esses 2 elementos:
- AGREGUE VALOR: Mostre que você prestou atenção no conteúdo, não só na aparência
- BOAS EMOÇÕES: Seja leve, faça ela sorrir ou se sentir interessante

A CHAVE: Quando você agrega valor real, ela para de te ver como "mais um cara".

═══════════════════════════════════════════════════════════════════
📋 REGRAS DE FORMATO
═══════════════════════════════════════════════════════════════════

- Máximo 1-2 frases (até 20 palavras)
- Pode usar "kkk", emoji ocasional
- Tom natural, como se fosse um conhecido comentando
- Português BR

═══════════════════════════════════════════════════════════════════
❌ NUNCA FAÇA ISSO
═══════════════════════════════════════════════════════════════════

- "Oi, tudo bem?" ou variações (genérico demais)
- Elogios à aparência ("linda", "gata", "maravilhosa") - todo mundo faz
- "Aposto que...", "Com certeza você..." (presunçoso)
- Perguntas de entrevista ou muito diretas
- Mensagem que poderia ser enviada pra qualquer perfil
- Investir demais ou parecer ansioso

═══════════════════════════════════════════════════════════════════
✅ TESTE FINAL
═══════════════════════════════════════════════════════════════════

Antes de retornar, verifique:
- Essa mensagem comenta algo ESPECÍFICO do conteúdo dela?
- Parece um comentário natural, não uma cantada?
- Ela provavelmente vai responder porque achou interessante?
`;

    // Integra inteligência coletiva quando disponível
    if (insights) {
      if (insights.matchedTags && insights.matchedTags.length > 0) {
        prompt += `
📊 PERFIL IDENTIFICADO: ${insights.matchedTags.join(', ')}
(Calibre baseado em perfis similares)
`;
      }

      if (insights.whatWorks && insights.whatWorks.length > 0) {
        prompt += `
✅ FUNCIONA COM ESSE PERFIL:
${insights.whatWorks.slice(0, 4).map(w => `- ${w}`).join('\n')}
`;
      }

      if (insights.whatDoesntWork && insights.whatDoesntWork.length > 0) {
        prompt += `
❌ NÃO FUNCIONA (EVITE):
${insights.whatDoesntWork.slice(0, 3).map(w => `- ${w}`).join('\n')}
`;
      }

      if (insights.goodOpenerExamples && insights.goodOpenerExamples.length > 0) {
        prompt += `
📈 EXEMPLOS QUE GERARAM RESPOSTA:
${insights.goodOpenerExamples.slice(0, 3).map(e => `"${e}"`).join('\n')}
`;
      }

      if (insights.badOpenerExamples && insights.badOpenerExamples.length > 0) {
        prompt += `
📉 EXEMPLOS QUE FALHARAM:
${insights.badOpenerExamples.slice(0, 2).map(e => `"${e}"`).join('\n')}
`;
      }
    }

    prompt += `
Retorne 3 opções numeradas. Sem explicações. Apenas as mensagens.`;

    return prompt;
  }

  private buildUserPrompt(input: InstagramOpenerInput, userContext?: UserContext): string {
    const parts: string[] = [];

    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    parts.push('=== PERFIL INSTAGRAM ===');
    parts.push(`Username: @${input.username}`);

    if (input.bio) {
      parts.push(`Bio: ${input.bio}`);
    }

    if (input.recentPosts && input.recentPosts.length > 0) {
      parts.push(`Posts recentes: ${input.recentPosts.slice(0, 3).join(', ')}`);
    }

    if (input.stories && input.stories.length > 0) {
      parts.push(`Stories: ${input.stories.slice(0, 2).join(', ')}`);
    }

    if (input.specificPost) {
      parts.push(`Conteúdo específico para interagir: ${input.specificPost}`);
    }

    const approachLabels = {
      dm_direto: 'DM Direto',
      comentario_post: 'Comentário em Post',
      resposta_story: 'Resposta de Story',
    };

    parts.push(`\nTipo de abordagem: ${approachLabels[input.approachType as keyof typeof approachLabels]}`);
    parts.push('\nCrie 3 opções aplicando os princípios.');

    return parts.join('\n');
  }
}

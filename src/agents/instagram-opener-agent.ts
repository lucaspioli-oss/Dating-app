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
      dm_direto: `DM DIRETO: Ela não te conhece. Você precisa quebrar a barreira inicial.
- Não seja mais um "oi tudo bem?" ou "nossa que linda"
- Agregue valor: mostre interesse genuíno em algo específico dela
- Quando você faz isso, ela para de te ver como ameaça`,
      comentario_post: `COMENTÁRIO EM POST: Comente como alguém que realmente se interessou pelo conteúdo.
- Não é sobre ela ser bonita, é sobre o que ela postou
- Seja genuíno, como você comentaria naturalmente
- Pode ser engraçado ou agregar algo ao assunto`,
      resposta_story: `RESPOSTA DE STORY: Reaja ao que ela mostrou, não à aparência dela.
- É sobre o momento, o lugar, a situação
- Casual e natural, como reagiria um amigo
- Pode puxar assunto a partir do story`,
    };

    let prompt = `Você é um expert em comunicação e atração. Crie abordagens para Instagram.

CONTEXTO IMPORTANTE: Diferente de apps de relacionamento, aqui NÃO houve match.
Ela recebe dezenas de mensagens genéricas todo dia ("oi tudo bem?", "nossa que linda").
Você precisa quebrar a barreira inicial - fazer ela não te ver como ameaça.

${approachContext[approachType as keyof typeof approachContext]}

5 GATILHOS DE ATRAÇÃO (aplique sutilmente - ela NÃO te conhece ainda):
1. LÍDER: Transmita que você conduz, opina, sugere coisas. Não pede permissão.
2. PROTETOR: Implícito - demonstre cuidado genuíno, não babação.
3. TOMADOR DE RISCOS: Seja genuíno, autêntico, comente algo que você realmente pensa.
4. PROVA SOCIAL: Aja como quem já é validado - não busque aprovação dela.
5. PROMOTOR DE BOAS EMOÇÕES: Seja leve, engraçado, faça ela sorrir.

ESTRATÉGIA DE ABORDAGEM NO INSTAGRAM:
- AGREGUE VALOR: A chave é mostrar interesse genuíno em algo do conteúdo dela.
  Ex: Ela gosta de livro? Comente sobre o que ela está lendo, sugira algo.
- QUEBRE A BARREIRA: Quando você agrega, ela para de te ver como ameaça.
- NÃO ELOGIE APARÊNCIA: Todos fazem isso. Comente sobre o conteúdo, o lugar, a situação.
- SEJA GENUÍNO: Como você comentaria naturalmente se fosse um amigo.

CALIBRAGEM:
- Não invista demais logo de cara - você ainda não a conhece
- Seja sutil - deixe espaço pra ela querer saber mais
- Mulheres são mentais - a imaginação vai longe com pouco estímulo
- 2 passos pra frente, 1 pra trás

FORMATO:
- Uma frase curta (máx 15 palavras)
- Pode usar "kkk" ou emoji com moderação
- Natural, não calculado
- Português BR, não misture idiomas

EVITE:
- Elogios à aparência ("linda", "gata", "maravilhosa")
- "Oi tudo bem?" ou variações
- "Aposto que...", "Com certeza você..."
- Perguntas muito diretas logo de cara
- Parecer que está investindo demais
- Pedir validação ou aprovação
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

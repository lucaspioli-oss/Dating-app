import { BaseAgent, UserContext } from './base-agent';

export interface FirstMessageInput {
  matchName: string;
  matchBio: string;
  platform: 'tinder' | 'bumble' | 'hinge' | 'outro';
  photoDescription?: string;
  specificDetail?: string;
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

export class FirstMessageAgent extends BaseAgent {
  async execute(input: FirstMessageInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.collectiveInsights);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(insights?: FirstMessageInput['collectiveInsights']): string {
    let prompt = `Você é um expert em comunicação e atração. Gere primeiras mensagens para apps de relacionamento.

CONTEXTO: Já houve match - ela demonstrou interesse. Isso abre espaço para assumir cumplicidade, brincar e despertar curiosidade.

5 GATILHOS DE ATRAÇÃO (aplique sutilmente):
1. LÍDER: Transmita que você conduz, não pede permissão. Sem arrogância.
2. PROTETOR: Demonstre que cuida de quem importa (referência leve a amigos/família funciona).
3. TOMADOR DE RISCOS: Seja genuíno, autêntico, não tenha medo de se expor ou brincar.
4. PROVA SOCIAL: Implícita - não busque validação, aja como quem já é validado.
5. PROMOTOR DE BOAS EMOÇÕES: Faça ela se sentir bem, leve, rindo.

ESTRATÉGIA DE PRIMEIRA MENSAGEM:
- DESTAQUE-SE: A maioria dos homens é genérica. Não seja mais um "oi tudo bem?".
- PUSH-PULL: Traga algo levemente provocativo/negativo de forma sutil - ela não espera.
  Ex: "mt gata, mas seila... cara de quem não para um segundo kkk"
- DESPERTE CURIOSIDADE: Sobre algo relacionado a ela mesma.
- ASSUMA CUMPLICIDADE: Já houve match, ela gostou. Use isso a seu favor.

CALIBRAGEM (conceito chave):
- 2 passos pra frente, 1 pra trás
- Mulheres são mentais - a imaginação delas vai longe com pouco estímulo
- Seja sutil mas permita a coisa avançar
- Não invista demais logo de cara

FORMATO:
- Mensagens CURTAS (5-12 palavras máximo)
- Pode usar "kkk" ou "haha" pra leveza
- Natural, não calculado
- Português BR, não misture idiomas

EVITE:
- "Oi/Olá + nome" (genérico demais)
- Perguntas diretas no primeiro contato
- Elogios exagerados ou óbvios ("nossa que linda")
- Parecer carente ou investir demais
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

  private buildUserPrompt(input: FirstMessageInput, userContext?: UserContext): string {
    const parts: string[] = [];

    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    parts.push('=== PERFIL DO MATCH ===');
    parts.push(`Nome: ${input.matchName}`);
    parts.push(`Plataforma: ${input.platform}`);
    parts.push(`Bio: ${input.matchBio}`);

    if (input.photoDescription) {
      parts.push(`Fotos: ${input.photoDescription}`);
    }

    if (input.specificDetail) {
      parts.push(`Detalhe específico: ${input.specificDetail}`);
    }

    parts.push('\nCrie 3 opções de primeira mensagem aplicando os princípios.');

    return parts.join('\n');
  }
}

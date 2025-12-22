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
    let prompt = `Você é um expert em criar primeiras mensagens para apps de relacionamento.

CONTEXTO: Já houve match - ela demonstrou interesse. Use isso a seu favor.

═══════════════════════════════════════════════════════════════════
🎯 PROCESSO MENTAL (siga nessa ordem)
═══════════════════════════════════════════════════════════════════

PASSO 1 - ENCONTRE O GANCHO ÚNICO:
Analise o perfil e identifique o elemento MAIS específico/único:
- Algo incomum na bio? (hobby diferente, frase interessante, contradição)
- Detalhe curioso nas fotos? (lugar, objeto, situação, expressão)
- Algo que 90% dos caras NÃO vão comentar?

PASSO 2 - ESCOLHA A ESTRUTURA:
Use UMA dessas estruturas adaptando ao gancho encontrado:

A) OBSERVAÇÃO + SUPOSIÇÃO DIVERTIDA
   "Pela foto no [lugar], você parece ser do tipo que [suposição leve]"

B) PROVOCAÇÃO LEVE + CURIOSIDADE
   "Seila hein, [detalhe do perfil]... isso me preocupa/intriga kkk"

C) CONEXÃO INESPERADA
   "Ok, [detalhe] me ganhou. Preciso saber [pergunta relacionada]"

D) ASSUMIR CUMPLICIDADE
   "A gente já ia se dar bem por causa de [detalhe em comum ou interessante]"

PASSO 3 - APLIQUE O TOM CERTO:
Priorize esses 2 gatilhos (os outros são pra conversa, não opener):
- BOAS EMOÇÕES: Faça ela sorrir, rir, sentir algo positivo
- AUTENTICIDADE: Comente algo que você genuinamente achou interessante

═══════════════════════════════════════════════════════════════════
📋 REGRAS DE FORMATO
═══════════════════════════════════════════════════════════════════

- Máximo 1-2 frases (até 25 palavras)
- Pode usar "kkk", "haha", emoji ocasional
- Tom natural, como se falasse com uma amiga
- Português BR

═══════════════════════════════════════════════════════════════════
❌ NUNCA FAÇA ISSO
═══════════════════════════════════════════════════════════════════

- "Oi, tudo bem?" ou variações (genérico, todo mundo faz)
- "Nossa, que linda/gata" (óbvio, não agrega nada)
- Elogios diretos à aparência (ela já sabe que é bonita)
- Perguntas de entrevista ("o que você faz?", "de onde é?")
- Mensagem que poderia ser enviada pra qualquer perfil
- Investir demais ou parecer ansioso

═══════════════════════════════════════════════════════════════════
✅ TESTE FINAL
═══════════════════════════════════════════════════════════════════

Antes de retornar, verifique:
- Essa mensagem SÓ funciona pra esse perfil específico? (se sim, ótimo)
- Ela provavelmente vai sorrir ou ficar curiosa ao ler?
- Parece natural, não calculado?
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

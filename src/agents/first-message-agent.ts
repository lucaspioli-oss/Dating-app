import { BaseAgent, UserContext } from './base-agent';

export interface FirstMessageInput {
  matchName: string;
  matchBio: string;
  platform: 'tinder' | 'bumble' | 'hinge' | 'outro';
  tone: 'engraçado' | 'ousado' | 'romântico' | 'casual' | 'confiante';
  photoDescription?: string;
  specificDetail?: string; // Algo específico do perfil para mencionar
}

export class FirstMessageAgent extends BaseAgent {
  async execute(input: FirstMessageInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.tone);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(tone: string): string {
    const toneInstructions = {
      engraçado: 'Humor leve e natural. Uma piada simples ou observação divertida.',
      ousado: 'Confiante e direto, mas de boa. Flerte sutil.',
      romântico: 'Charmoso mas sem forçar. Elogio simples e sincero.',
      casual: 'Super de boa, descontraído. Como se tivesse acabado de notar algo.',
      confiante: 'Seguro mas tranquilo. Sem parecer que tá tentando impressionar.',
    };

    return `Gere primeiras mensagens MUITO CURTAS (5-10 palavras máximo).

TAMANHO OBRIGATÓRIO: 5-10 palavras. Se passar disso, está errado.

PROIBIDO:
- Começar com "Oi/Olá [nome]"
- Perguntas (nada com "?")
- "Aposto que...", "Tenho certeza..."
- Piadas elaboradas
- Misturar idiomas

BOM: comentário rápido + kkk

EXEMPLOS DO TAMANHO CERTO:
✅ "canceriana de pagode já sei que é problema kkk" (8 palavras)
✅ "essa vibe de praia combinou" (5 palavras)
✅ "dividir açaí é teste de compatibilidade kkk" (6 palavras)

EXEMPLOS LONGOS DEMAIS (NÃO FAÇA):
❌ "Amo que você já deixou claro que a primeira batalha vai ser decidir qual sabor de açaí" (17 palavras - MUITO LONGO)
❌ "Canceriana + pagode = a combinação perfeita pra chorar numa mesa de bar" (12 palavras - LONGO)

TOM: ${tone} - ${toneInstructions[tone as keyof typeof toneInstructions]}

Retorne 3 opções. MÁXIMO 10 palavras cada.`;
  }

  private buildUserPrompt(input: FirstMessageInput, userContext?: UserContext): string {
    const parts: string[] = [];

    // Contexto do usuário
    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    // Informações do match
    parts.push('=== INFORMAÇÕES DO MATCH ===');
    parts.push(`Nome: ${input.matchName}`);
    parts.push(`Plataforma: ${input.platform.toUpperCase()}`);
    parts.push(`\nBio:\n${input.matchBio}`);

    if (input.photoDescription) {
      parts.push(`\nFoto(s): ${input.photoDescription}`);
    }

    if (input.specificDetail) {
      parts.push(`\nDetalhe específico para mencionar: ${input.specificDetail}`);
    }

    parts.push('\n=== SUA TAREFA ===');
    parts.push(`Crie 3 opções de primeira mensagem com tom ${input.tone}.`);
    parts.push('Pode mencionar algo do perfil, mas só se parecer natural.');
    parts.push('Mensagens curtas. Não force a barra.');
    parts.push('\nFormato: Apenas as 3 mensagens numeradas, sem explicações.');

    return parts.join('\n');
  }
}

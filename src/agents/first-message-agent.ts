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
      engraçado: 'Use humor inteligente, trocadilhos criativos ou observações engraçadas. NUNCA use piadas ofensivas ou de mal gosto.',
      ousado: 'Seja confiante e direto, mas SEMPRE respeitoso. Um pouco de flerte é ok, mas sem ser invasivo ou vulgar.',
      romântico: 'Seja charmoso e genuíno. Destaque beleza, interesses ou algo especial do perfil de forma sincera.',
      casual: 'Seja descontraído e natural. Como se já conhecesse a pessoa. Evite formalidades.',
      confiante: 'Demonstre segurança e interesse real. Seja direto sobre sua intenção de conhecer melhor.',
    };

    return `Você é um especialista em criar primeiras mensagens IRRESISTÍVEIS para apps de namoro.

REGRAS FUNDAMENTAIS:
❌ NUNCA use "Oi, tudo bem?" ou variações genéricas
❌ NUNCA seja ofensivo, vulgar ou desrespeitoso
❌ NUNCA copie frases prontas da internet
✅ SEMPRE personalize com base no perfil
✅ SEMPRE seja autêntico e criativo
✅ SEMPRE deixe espaço para resposta fácil

TOM DA MENSAGEM: ${tone}
${toneInstructions[tone as keyof typeof toneInstructions]}

FORMATO DA RESPOSTA:
Retorne APENAS 3 opções de primeira mensagem, numeradas.
Cada mensagem deve ter 1-3 frases no máximo.
Seja DIRETO e MEMORÁVEL.`;
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
    parts.push('Personalize com base nas informações do perfil.');
    parts.push('Seja criativo, memorável e EVITE clichês!');
    parts.push('\nFormato: Apenas as 3 mensagens numeradas, sem explicações.');

    return parts.join('\n');
  }
}

import { BaseAgent, UserContext } from './base-agent';

export interface ConversationReplyInput {
  receivedMessage: string;
  conversationHistory?: Array<{ sender: 'user' | 'match'; message: string }>;
  matchName?: string;
  context?: string; // NÃO USAR - ignorado propositalmente
  platform?: 'tinder' | 'bumble' | 'hinge' | 'instagram' | 'outro';
  includeReasoning?: boolean;
}

export interface ReplyWithReasoning {
  analysis: {
    messageTemperature: 'hot' | 'warm' | 'cold';
    keyElements: string[];
    detectedIntent: string;
    conversationPhase: string;
  };
  suggestions: Array<{
    text: string;
    reasoning: string;
    strategy: string;
  }>;
  rawResponse: string;
}

export class ConversationReplyAgent extends BaseAgent {
  async execute(input: ConversationReplyInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt();
    const userPrompt = this.buildUserPrompt(input);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  async executeWithReasoning(input: ConversationReplyInput, userContext?: UserContext): Promise<ReplyWithReasoning> {
    const systemPrompt = this.buildReasoningPrompt();
    const userPrompt = this.buildUserPrompt(input);

    const rawResponse = await this.callClaude(systemPrompt, userPrompt);
    return this.parseReasoningResponse(rawResponse);
  }

  private parseReasoningResponse(response: string): ReplyWithReasoning {
    try {
      const jsonMatch = response.match(/```json\n?([\s\S]*?)\n?```/);
      if (jsonMatch) {
        return { ...JSON.parse(jsonMatch[1]), rawResponse: response };
      }

      const result: ReplyWithReasoning = {
        analysis: {
          messageTemperature: 'warm',
          keyElements: [],
          detectedIntent: '',
          conversationPhase: 'inicial',
        },
        suggestions: [],
        rawResponse: response,
      };

      if (response.includes('🔥') || response.toLowerCase().includes('quente')) {
        result.analysis.messageTemperature = 'hot';
      } else if (response.includes('❄️') || response.toLowerCase().includes('fria')) {
        result.analysis.messageTemperature = 'cold';
      }

      const lines = response.split('\n');
      let currentSuggestion: { text: string; reasoning: string; strategy: string } | null = null;

      for (const line of lines) {
        const suggestionMatch = line.match(/^(\d+)\.\s*(.+)/);
        if (suggestionMatch) {
          if (currentSuggestion) {
            result.suggestions.push(currentSuggestion);
          }
          currentSuggestion = {
            text: suggestionMatch[2].trim(),
            reasoning: '',
            strategy: '',
          };
        } else if (currentSuggestion && line.includes('Raciocínio:')) {
          currentSuggestion.reasoning = line.replace('Raciocínio:', '').trim();
        } else if (currentSuggestion && line.includes('Estratégia:')) {
          currentSuggestion.strategy = line.replace('Estratégia:', '').trim();
        }
      }

      if (currentSuggestion) {
        result.suggestions.push(currentSuggestion);
      }

      return result;
    } catch (error) {
      return {
        analysis: {
          messageTemperature: 'warm',
          keyElements: [],
          detectedIntent: 'unknown',
          conversationPhase: 'unknown',
        },
        suggestions: [],
        rawResponse: response,
      };
    }
  }

  private buildReasoningPrompt(): string {
    return `Você analisa A ÚLTIMA MENSAGEM que ela enviou e gera respostas.

FOCO ABSOLUTO: A mensagem dela. IGNORE qualquer informação de perfil/bio/fotos.

FORMATO JSON:
\`\`\`json
{
  "analysis": {
    "messageTemperature": "hot|warm|cold",
    "keyElements": ["palavras-chave do que ela disse"],
    "detectedIntent": "o que ela quis comunicar",
    "conversationPhase": "inicial|desenvolvimento|avancada"
  },
  "suggestions": [
    {
      "text": "resposta curta reagindo ao que ela disse",
      "reasoning": "por que essa resposta funciona",
      "strategy": "callback|roleplay|provocacao|conducao|espelhamento"
    }
  ]
}
\`\`\`

TEMPERATURA:
- HOT 🔥: perguntou algo, brincou, emoji/kkk, texto maior
- WARM 😐: respondeu ok, mas curto
- COLD ❄️: monossilábica, seca

Gere 3 sugestões que REAGEM especificamente ao que ela acabou de dizer.`;
  }

  private buildSystemPrompt(): string {
    return `Você gera respostas para conversas de dating.

██████████████████████████████████████████████████████████████████
█  REGRA ÚNICA: RESPONDA AO QUE ELA DISSE, NÃO AO PERFIL DELA   █
██████████████████████████████████████████████████████████████████

Você vai receber A ÚLTIMA MENSAGEM que ela enviou.
Sua tarefa é REAGIR a essa mensagem específica.

❌ PROIBIDO:
- Mencionar perfil, bio, fotos, trabalho, hobbies do PERFIL
- Fazer perguntas genéricas ("e você?", "o que você curte?")
- Ignorar o que ela disse pra falar de outra coisa

✅ OBRIGATÓRIO:
- Pegar um GANCHO do que ela DISSE
- Brincar/reagir/provocar com base nas PALAVRAS DELA
- Ser criativo com o que ELA ACABOU DE FALAR

EXEMPLOS DE COMO REAGIR:

Ela disse: "kkk você é engraçado"
→ "engraçado é elogio ou preocupação? kkk"
→ "já recebi piores, vou aceitar"
→ "espera até me conhecer pessoalmente"

Ela disse: "to cansada do trabalho"
→ "precisa de um resgate então... café ou sequestro?"
→ "workaholic detectada, vou ter que intervir"
→ "descansar é pra fracos, bora sair"

Ela disse: "talvez a gente se veja"
→ "talvez é quase um sim, já to contando"
→ "vou interpretar como confirmado"
→ "gostei da animação kkk"

Ela disse: "nossa que calor"
→ "aproveitando pra dar em cima de mim né"
→ "isso foi cantada? aceitando"
→ "tá difícil mesmo, bora tomar um açaí"

FORMATO:
- 1-2 frases curtas (máx 15 palavras)
- "kkk" ou emoji se fizer sentido
- Português BR natural

Retorne APENAS 3 opções numeradas. Sem explicações.`;
  }

  private buildUserPrompt(input: ConversationReplyInput): string {
    const parts: string[] = [];

    // Histórico MÍNIMO - só pra saber o fluxo
    if (input.conversationHistory && input.conversationHistory.length > 0) {
      const lastFew = input.conversationHistory.slice(-3);
      if (lastFew.length > 0) {
        parts.push('Últimas mensagens:');
        lastFew.forEach((msg) => {
          const label = msg.sender === 'user' ? 'Você' : 'Ela';
          parts.push(`${label}: "${msg.message}"`);
        });
        parts.push('');
      }
    }

    // A MENSAGEM DELA - único foco
    parts.push('████████████████████████████████████████');
    parts.push('ELA ACABOU DE MANDAR:');
    parts.push('');
    parts.push(`"${input.receivedMessage}"`);
    parts.push('');
    parts.push('████████████████████████████████████████');
    parts.push('');
    parts.push('Gere 3 respostas que REAGEM a isso que ela disse.');

    // NÃO inclui context/perfil - propositalmente ignorado

    return parts.join('\n');
  }
}

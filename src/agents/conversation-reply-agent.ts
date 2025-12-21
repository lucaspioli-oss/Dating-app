import { BaseAgent, UserContext } from './base-agent';

export interface ConversationReplyInput {
  receivedMessage: string;
  conversationHistory?: Array<{ sender: 'user' | 'match'; message: string }>;
  matchName?: string;
  context?: string; // Contexto adicional sobre a conversa
  platform?: 'tinder' | 'bumble' | 'hinge' | 'instagram' | 'outro';
}

export class ConversationReplyAgent extends BaseAgent {
  async execute(input: ConversationReplyInput, userContext?: UserContext): Promise<string> {
    const systemPrompt = this.buildSystemPrompt(input.conversationHistory);
    const userPrompt = this.buildUserPrompt(input, userContext);

    return await this.callClaude(systemPrompt, userPrompt);
  }

  private buildSystemPrompt(history?: ConversationReplyInput['conversationHistory']): string {
    // Detecta fase da conversa baseado no histórico
    const messageCount = history?.length || 0;
    const phase = messageCount < 4 ? 'inicial' : messageCount < 10 ? 'desenvolvimento' : 'avancada';

    const phaseContext = {
      inicial: `FASE INICIAL: Foco em criar conexão e curiosidade. Ainda se conhecendo.`,
      desenvolvimento: `FASE DESENVOLVIMENTO: Já há alguma conexão. Pode ser mais pessoal, começar a plantar ideias de encontro.`,
      avancada: `FASE AVANÇADA: Conexão estabelecida. Pode ser mais direto, sugerir encontro, criar tensão quando apropriado.`,
    };

    return `Você é um expert em comunicação e atração. Crie respostas para conversas de dating.

${phaseContext[phase]}

OBJETIVO PRINCIPAL: O objetivo final de qualquer interação online é o encontro físico.
Você precisa conduzir a conversa nessa direção de forma natural e calibrada.

5 GATILHOS DE ATRAÇÃO (aplique naturalmente):
1. LÍDER: Conduza a conversa, sugira coisas, tome iniciativa. Não fique só reagindo.
2. PROTETOR: Demonstre cuidado genuíno, interesse real (sem ser carente).
3. TOMADOR DE RISCOS: Seja autêntico, brinque, não tenha medo de se expor.
4. PROVA SOCIAL: Aja como quem já é validado - mencione amigos, planos, vida social.
5. PROMOTOR DE BOAS EMOÇÕES: Seja leve, faça ela rir, crie momentos bons.

CALIBRAGEM (conceito chave):
- 2 passos pra frente, 1 pra trás
- Avance se ela demonstrar interesse positivo
- Recue um pouco se houver resistência ou resposta fria
- Mulheres são mentais - a imaginação delas vai longe com pouco estímulo
- Seja sutil mas permita a coisa avançar

TRANSIÇÃO PARA ENCONTRO (quando a fase permitir):
- Não pergunte "quer sair?" diretamente
- Plante a ideia de vocês fazendo algo juntos
- Ex: "desse jeito não vou nem te convidar pra [atividade], vai ser problema kkk"
- Dê duas opções de data quando for marcar ("quinta ou sexta fica bom?")

TENSÃO SEXUAL (use com calibragem - só se ela der abertura):
- Seja sutil, deixe a imaginação trabalhar
- Se ela responder bem a algo mais picante, pode avançar um pouco
- Se não, puxa o freio naturalmente
- Nunca seja vulgar ou desrespeitoso

FORMATO:
- Mensagens curtas (1-3 frases)
- Pode usar "kkk" ou "haha" pra leveza
- Natural, não calculado
- Português BR

EVITE:
- Ser monótono ou previsível
- Ficar só reagindo (conduza a conversa)
- Investir demais ou parecer carente
- Ignorar sinais dela (positivos ou negativos)
- Forçar assuntos que ela evitou`;
  }

  private buildUserPrompt(input: ConversationReplyInput, userContext?: UserContext): string {
    const parts: string[] = [];

    // Contexto do usuário
    if (userContext) {
      parts.push(this.buildUserContext(userContext));
    }

    // Histórico da conversa
    if (input.conversationHistory && input.conversationHistory.length > 0) {
      parts.push('=== HISTÓRICO DA CONVERSA ===');
      input.conversationHistory.forEach((msg) => {
        const label = msg.sender === 'user' ? 'Você' : input.matchName || 'Match';
        parts.push(`${label}: ${msg.message}`);
      });
      parts.push('');
    }

    // Mensagem recebida
    parts.push('=== MENSAGEM RECEBIDA ===');
    const matchLabel = input.matchName || 'Match';
    parts.push(`${matchLabel}: ${input.receivedMessage}`);

    // Contexto adicional
    if (input.context) {
      parts.push(`\nContexto: ${input.context}`);
    }

    parts.push('\n=== SUA TAREFA ===');
    parts.push('Crie 3 opções de resposta aplicando os princípios.');
    parts.push('Considere a fase da conversa, o histórico e conduza para o objetivo.');
    parts.push('\nFormato: Apenas as 3 respostas numeradas, sem explicações.');

    return parts.join('\n');
  }
}

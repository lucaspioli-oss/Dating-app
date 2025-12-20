import { randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import {
  Conversation,
  ConversationAvatar,
  Message,
  CreateConversationRequest,
  AddMessageRequest,
  ConversationListItem,
} from '../types/conversation';

// Firestore reference
const getDb = () => admin.firestore();

export class ConversationManager {
  /**
   * Criar nova conversa
   */
  static async createConversation(request: CreateConversationRequest & { userId: string }): Promise<Conversation> {
    const conversationId = randomUUID();
    const now = new Date();

    const avatar: ConversationAvatar = {
      matchName: request.matchName,
      platform: request.platform as any,
      bio: request.bio,
      photoDescriptions: request.photoDescriptions,
      age: request.age,
      location: request.location,
      interests: request.interests,

      detectedPatterns: {
        responseLength: 'medium',
        emotionalTone: 'neutral',
        useEmojis: false,
        flirtLevel: 'medium',
        lastUpdated: now,
      },

      learnedInfo: {
        hobbies: request.interests || [],
        lifestyle: [],
        dislikes: [],
        goals: [],
        personality: [],
      },

      analytics: {
        totalMessages: 0,
        aiSuggestionsUsed: 0,
        customMessagesUsed: 0,
        conversationQuality: 'average',
      },
    };

    const messages: Message[] = [];

    // Se tiver primeira mensagem (opener), adicionar
    if (request.firstMessage) {
      messages.push({
        id: randomUUID(),
        role: 'user',
        content: request.firstMessage,
        timestamp: now,
        wasAiSuggestion: true,
        tone: request.tone,
      });
    }

    const conversation: Conversation = {
      id: conversationId,
      userId: request.userId,
      avatar,
      messages,
      currentTone: request.tone || 'casual',
      status: 'active',
      createdAt: now,
      lastMessageAt: now,
    };

    // Salvar no Firestore
    await getDb().collection('conversations').doc(conversationId).set({
      ...conversation,
      createdAt: admin.firestore.Timestamp.fromDate(now),
      lastMessageAt: admin.firestore.Timestamp.fromDate(now),
    });

    return conversation;
  }

  /**
   * Adicionar mensagem à conversa
   */
  static async addMessage(request: AddMessageRequest & { userId: string }): Promise<Conversation> {
    const conversation = await this.getConversation(request.conversationId, request.userId);
    if (!conversation) {
      throw new Error('Conversa não encontrada');
    }

    const message: Message = {
      id: randomUUID(),
      role: request.role,
      content: request.content,
      timestamp: new Date(),
      wasAiSuggestion: request.wasAiSuggestion,
      tone: request.tone,
    };

    conversation.messages.push(message);
    conversation.lastMessageAt = new Date();

    // Atualizar analytics
    conversation.avatar.analytics.totalMessages++;
    if (request.role === 'user') {
      if (request.wasAiSuggestion) {
        conversation.avatar.analytics.aiSuggestionsUsed++;
      } else {
        conversation.avatar.analytics.customMessagesUsed++;
      }
    }

    // Se for mensagem do match, analisar e atualizar calibragem
    if (request.role === 'match') {
      this.updateCalibration(conversation, request.content);
    }

    // Atualizar no Firestore
    await getDb().collection('conversations').doc(request.conversationId).update({
      messages: conversation.messages,
      lastMessageAt: admin.firestore.Timestamp.fromDate(conversation.lastMessageAt),
      avatar: conversation.avatar,
    });

    return conversation;
  }

  /**
   * Analisar mensagem e atualizar calibragem
   */
  private static updateCalibration(conversation: Conversation, message: string): void {
    const avatar = conversation.avatar;

    // Detectar tamanho de resposta
    if (message.length < 50) {
      avatar.detectedPatterns.responseLength = 'short';
    } else if (message.length < 150) {
      avatar.detectedPatterns.responseLength = 'medium';
    } else {
      avatar.detectedPatterns.responseLength = 'long';
    }

    // Detectar uso de emojis
    const emojiRegex = /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/u;
    avatar.detectedPatterns.useEmojis = emojiRegex.test(message);

    // Detectar tom emocional (análise simples baseada em palavras-chave)
    const warmKeywords = ['amor', 'querido', 'fofo', 'lindo', 'amei', 'adorei', 'haha', 'rsrs', '❤️', '😊', '😍'];
    const coldKeywords = ['ok', 'sei', 'talvez', 'não sei', 'depois', 'ocupado', 'ocupada'];

    const lowerMessage = message.toLowerCase();
    const hasWarmKeywords = warmKeywords.some((keyword) => lowerMessage.includes(keyword));
    const hasColdKeywords = coldKeywords.some((keyword) => lowerMessage.includes(keyword));

    if (hasWarmKeywords && !hasColdKeywords) {
      avatar.detectedPatterns.emotionalTone = 'warm';
    } else if (hasColdKeywords && !hasWarmKeywords) {
      avatar.detectedPatterns.emotionalTone = 'cold';
    } else {
      avatar.detectedPatterns.emotionalTone = 'neutral';
    }

    // Detectar nível de flerte (baseado em mensagens enviadas vs recebidas)
    const userMessages = conversation.messages.filter((m) => m.role === 'user').length;
    const matchMessages = conversation.messages.filter((m) => m.role === 'match').length;

    if (matchMessages > userMessages) {
      avatar.detectedPatterns.flirtLevel = 'high';
    } else if (matchMessages === userMessages) {
      avatar.detectedPatterns.flirtLevel = 'medium';
    } else {
      avatar.detectedPatterns.flirtLevel = 'low';
    }

    // Extrair informações aprendidas (palavras-chave)
    const hobbiesKeywords = ['gosto de', 'adoro', 'amo', 'curto', 'vicio em'];
    const dislikesKeywords = ['odeio', 'não gosto', 'detesto', 'não curto'];

    hobbiesKeywords.forEach((keyword) => {
      if (lowerMessage.includes(keyword)) {
        const afterKeyword = lowerMessage.split(keyword)[1];
        if (afterKeyword) {
          const hobby = afterKeyword.split(/[.,!?]/)[0].trim();
          if (hobby && !avatar.learnedInfo.hobbies?.includes(hobby)) {
            avatar.learnedInfo.hobbies = [...(avatar.learnedInfo.hobbies || []), hobby];
          }
        }
      }
    });

    avatar.detectedPatterns.lastUpdated = new Date();

    // Avaliar qualidade da conversa
    if (matchMessages >= 5 && avatar.detectedPatterns.emotionalTone === 'warm') {
      avatar.analytics.conversationQuality = 'excellent';
    } else if (matchMessages >= 3) {
      avatar.analytics.conversationQuality = 'good';
    } else if (matchMessages >= 1) {
      avatar.analytics.conversationQuality = 'average';
    } else {
      avatar.analytics.conversationQuality = 'poor';
    }
  }

  /**
   * Obter conversa por ID (verificando ownership)
   */
  static async getConversation(conversationId: string, userId: string): Promise<Conversation | null> {
    const doc = await getDb().collection('conversations').doc(conversationId).get();

    if (!doc.exists) {
      return null;
    }

    const data = doc.data();

    // Verificar se a conversa pertence ao usuário
    if (data?.userId !== userId) {
      return null;
    }

    return {
      ...data,
      createdAt: data?.createdAt?.toDate() || new Date(),
      lastMessageAt: data?.lastMessageAt?.toDate() || new Date(),
    } as Conversation;
  }

  /**
   * Listar conversas do usuário
   */
  static async listConversations(userId: string): Promise<ConversationListItem[]> {
    const snapshot = await getDb()
      .collection('conversations')
      .where('userId', '==', userId)
      .orderBy('lastMessageAt', 'desc')
      .get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      const messages = data.messages || [];
      return {
        id: doc.id,
        matchName: data.avatar?.matchName || 'Sem nome',
        platform: data.avatar?.platform || 'tinder',
        lastMessage: messages.length > 0
          ? messages[messages.length - 1].content
          : 'Sem mensagens',
        lastMessageAt: data.lastMessageAt?.toDate() || new Date(),
        unreadCount: 0,
        avatar: {
          emotionalTone: data.avatar?.detectedPatterns?.emotionalTone || 'neutral',
          flirtLevel: data.avatar?.detectedPatterns?.flirtLevel || 'medium',
        },
      };
    });
  }

  /**
   * Atualizar tom atual da conversa
   */
  static async updateTone(conversationId: string, userId: string, tone: string): Promise<void> {
    const conversation = await this.getConversation(conversationId, userId);
    if (conversation) {
      await getDb().collection('conversations').doc(conversationId).update({
        currentTone: tone,
      });
    }
  }

  /**
   * Deletar conversa
   */
  static async deleteConversation(conversationId: string, userId: string): Promise<boolean> {
    const conversation = await this.getConversation(conversationId, userId);
    if (!conversation) {
      return false;
    }
    await getDb().collection('conversations').doc(conversationId).delete();
    return true;
  }

  /**
   * Obter histórico formatado para o prompt da IA
   */
  static async getFormattedHistory(conversationId: string, userId: string): Promise<string> {
    const conversation = await this.getConversation(conversationId, userId);
    if (!conversation) return '';

    const { avatar, messages } = conversation;

    let history = `═══════════════════════════════════════════════════════════════════
📋 CONTEXTO DA CONVERSA
═══════════════════════════════════════════════════════════════════

👤 PERFIL DO MATCH:
Nome: ${avatar.matchName}
Plataforma: ${avatar.platform.toUpperCase()}
${avatar.bio ? `Bio: ${avatar.bio}` : ''}
${avatar.age ? `Idade: ${avatar.age}` : ''}
${avatar.location ? `Localização: ${avatar.location}` : ''}
${avatar.interests && avatar.interests.length > 0 ? `Interesses: ${avatar.interests.join(', ')}` : ''}

📊 CALIBRAGEM DETECTADA:
- Tamanho de resposta: ${avatar.detectedPatterns.responseLength === 'short' ? 'CURTO (espelhe com respostas curtas!)' : avatar.detectedPatterns.responseLength === 'long' ? 'LONGO (pode investir mais)' : 'MÉDIO'}
- Tom emocional: ${avatar.detectedPatterns.emotionalTone === 'warm' ? '🔥 CALOROSO (ela/ele está receptivo!)' : avatar.detectedPatterns.emotionalTone === 'cold' ? '❄️ FRIO (reduza investimento)' : '😐 NEUTRO'}
- Usa emojis: ${avatar.detectedPatterns.useEmojis ? 'SIM (você pode usar também)' : 'NÃO (evite emojis)'}
- Nível de flerte: ${avatar.detectedPatterns.flirtLevel === 'high' ? '🔥 ALTO (ela/ele está muito interessado!)' : avatar.detectedPatterns.flirtLevel === 'low' ? '❄️ BAIXO (aumente atração gradualmente)' : '😊 MÉDIO'}

💡 INFORMAÇÕES APRENDIDAS:
${avatar.learnedInfo.hobbies && avatar.learnedInfo.hobbies.length > 0 ? `- Hobbies: ${avatar.learnedInfo.hobbies.join(', ')}` : ''}
${avatar.learnedInfo.dislikes && avatar.learnedInfo.dislikes.length > 0 ? `- Não gosta de: ${avatar.learnedInfo.dislikes.join(', ')}` : ''}

📈 ANÁLISE DE PERFORMANCE:
- Total de mensagens: ${avatar.analytics.totalMessages}
- Sugestões da IA usadas: ${avatar.analytics.aiSuggestionsUsed}
- Mensagens customizadas: ${avatar.analytics.customMessagesUsed}
- Qualidade da conversa: ${avatar.analytics.conversationQuality.toUpperCase()}

═══════════════════════════════════════════════════════════════════
💬 HISTÓRICO DA CONVERSA
═══════════════════════════════════════════════════════════════════

`;

    messages.forEach((msg, index) => {
      const roleLabel = msg.role === 'user' ? 'VOCÊ' : avatar.matchName.toUpperCase();
      const suggestionLabel = msg.wasAiSuggestion ? ' [IA]' : '';
      history += `${index + 1}. ${roleLabel}${suggestionLabel}: "${msg.content}"\n`;
    });

    history += `
═══════════════════════════════════════════════════════════════════

⚠️ IMPORTANTE:
- ESPELHE o tamanho de resposta detectado (${avatar.detectedPatterns.responseLength})
- ADAPTE ao tom emocional (${avatar.detectedPatterns.emotionalTone})
- MANTENHA a qualidade da conversa (atualmente: ${avatar.analytics.conversationQuality})
`;

    return history;
  }
}

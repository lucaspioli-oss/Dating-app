export interface Message {
  id: string;
  role: 'user' | 'match'; // user = você enviou, match = recebeu dela/dele
  content: string;
  timestamp: Date;
  wasAiSuggestion?: boolean; // true se foi sugestão da IA que o usuário usou
  tone?: string; // tom usado para gerar (se foi sugestão da IA)
}

export interface ConversationAvatar {
  // Perfil do Match
  matchName: string;
  platform: 'tinder' | 'bumble' | 'hinge' | 'instagram' | 'outro';
  bio?: string;
  photoDescriptions?: string[];
  age?: string;
  location?: string;
  interests?: string[];

  // Calibragem e Aprendizado
  detectedPatterns: {
    responseLength: 'short' | 'medium' | 'long'; // Como ela/ele responde
    responseSpeed?: 'fast' | 'normal' | 'slow'; // Velocidade de resposta (futuro)
    emotionalTone: 'warm' | 'neutral' | 'cold'; // Tom emocional
    useEmojis: boolean; // Usa emojis?
    flirtLevel: 'low' | 'medium' | 'high'; // Receptividade ao flerte
    lastUpdated: Date;
  };

  // Informações Aprendidas
  learnedInfo: {
    hobbies?: string[];
    lifestyle?: string[];
    dislikes?: string[];
    goals?: string[];
    personality?: string[];
  };

  // Análise de Performance
  analytics: {
    totalMessages: number;
    aiSuggestionsUsed: number;
    customMessagesUsed: number;
    averageResponseTime?: number; // Futuro
    conversationQuality: 'excellent' | 'good' | 'average' | 'poor';
  };
}

export interface Conversation {
  id: string;
  userId: string; // ID do usuário dono da conversa
  avatar: ConversationAvatar;
  messages: Message[];
  currentTone: string; // Tom atual sendo usado
  status: 'active' | 'paused' | 'archived';
  createdAt: Date;
  lastMessageAt: Date;
}

export interface CreateConversationRequest {
  matchName: string;
  platform: string;
  bio?: string;
  photoDescriptions?: string[];
  age?: string;
  location?: string;
  interests?: string[];
  firstMessage?: string; // Primeira mensagem enviada (opener)
  tone?: string;
}

export interface AddMessageRequest {
  conversationId: string;
  role: 'user' | 'match';
  content: string;
  wasAiSuggestion?: boolean;
  tone?: string;
}

export interface GenerateSuggestionsRequest {
  conversationId: string;
  receivedMessage: string; // Mensagem que acabou de receber
  tone: string;
  userContext?: any; // Perfil do usuário
}

export interface ConversationListItem {
  id: string;
  matchName: string;
  platform: string;
  lastMessage: string;
  lastMessageAt: Date;
  unreadCount: number;
  avatar: {
    emotionalTone: string;
    flirtLevel: string;
  };
}

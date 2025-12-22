// ═══════════════════════════════════════════════════════════════════
// 🧠 SISTEMA DE INTELIGÊNCIA COLETIVA - TIPOS
// ═══════════════════════════════════════════════════════════════════

/**
 * Avatar Coletivo - Perfil construído a partir de múltiplas interações
 * de diferentes usuários com a mesma pessoa
 */
export interface CollectiveAvatar {
  id: string; // Hash único: nome_normalizado + plataforma (ou username para Instagram)

  // Identificação
  normalizedName: string; // Nome em lowercase, sem acentos
  username?: string;      // Para Instagram: @usuario (sem @)
  platform: 'tinder' | 'bumble' | 'hinge' | 'instagram' | 'outro';

  // Dados coletados de múltiplas fontes (anônimo)
  profileData: {
    possibleAges: string[]; // ["23", "24"] - diferentes usuários viram idades diferentes
    possibleLocations: string[];
    possibleBios: string[];
    commonInterests: string[]; // Interesses mencionados em múltiplas conversas
  };

  // Dados faciais para identificação e exibição
  faceData?: {
    faceHashes: string[];      // Hashes perceptuais das imagens faciais
    faceUrls: string[];        // URLs das imagens no Firebase Storage
    faceDescription: string;   // Descrição textual do rosto
  };

  // 🔥 INSIGHTS COLETIVOS (aprendidos de todas as conversas)
  collectiveInsights: {
    // Preferências descobertas
    likes: InsightItem[];      // "gosta de viajar", "ama cachorros"
    dislikes: InsightItem[];   // "não gosta de sushi", "odeia funk"

    // Padrões de comportamento
    behaviorPatterns: BehaviorPattern[];

    // O que funciona e não funciona
    whatWorks: StrategyInsight[];
    whatDoesntWork: StrategyInsight[];

    // Openers que geraram resposta vs não geraram
    openerStats: OpenerStat[];

    // Personalidade inferida
    personalityTraits: PersonalityTrait[];

    // Horários de maior engajamento
    activeHours?: number[]; // [20, 21, 22] = mais ativa entre 20h-22h

    // Velocidade média de resposta
    avgResponseTime?: 'instant' | 'minutes' | 'hours' | 'days';
  };

  // Métricas gerais
  metrics: {
    totalConversations: number;      // Quantas conversas diferentes
    totalMessages: number;           // Total de mensagens trocadas
    avgConversationLength: number;   // Média de mensagens por conversa
    successRate: number;             // % de conversas que avançaram (>5 msgs)
    dateConversionRate: number;      // % que resultou em encontro (se reportado)
  };

  // Controle
  lastUpdated: Date;
  lastAnalyzedAt?: Date;
  confidenceScore: number; // 0-100, aumenta com mais dados
}

/**
 * Item de insight com origem anônima
 */
export interface InsightItem {
  content: string;           // "não gosta de sushi"
  confidence: number;        // 0-100, baseado em quantas vezes confirmado
  source: 'explicit' | 'inferred'; // Ela disse vs IA inferiu
  firstDiscoveredAt: Date;
  confirmationCount: number; // Quantas conversas confirmaram isso
}

/**
 * Padrão de comportamento detectado
 */
export interface BehaviorPattern {
  pattern: string;           // "não responde mensagens curtas"
  frequency: number;         // Quantas vezes observado
  confidence: number;        // 0-100
  examples: string[];        // Exemplos anônimos (max 3)
}

/**
 * Insight sobre estratégias
 */
export interface StrategyInsight {
  strategy: string;          // "usar humor sobre viagens"
  successCount: number;      // Quantas vezes funcionou
  failCount: number;         // Quantas vezes não funcionou
  successRate: number;       // %
  examples: string[];        // Exemplos anônimos (max 3)
}

/**
 * Estatísticas de openers
 */
export interface OpenerStat {
  openerType: string;        // "oi simples", "pergunta sobre bio", "piada"
  responseRate: number;      // % de respostas
  avgResponseQuality: 'cold' | 'neutral' | 'warm' | 'hot';
  totalSent: number;
  examples: {
    opener: string;
    gotResponse: boolean;
    responseQuality?: string;
  }[];
}

/**
 * Traço de personalidade inferido
 */
export interface PersonalityTrait {
  trait: string;             // "introvertida", "sarcástica", "romântica"
  confidence: number;        // 0-100
  evidence: string[];        // Evidências anônimas
}

// ═══════════════════════════════════════════════════════════════════
// 📊 FEEDBACK DE MENSAGENS
// ═══════════════════════════════════════════════════════════════════

/**
 * Feedback sobre uma mensagem enviada
 */
export interface MessageFeedback {
  id: string;

  // Referências (anônimas para o coletivo)
  collectiveAvatarId: string;

  // Contexto
  messageType: 'opener' | 'reply' | 'follow_up';
  tone: string;

  // A mensagem (anonimizada - sem dados pessoais do usuário)
  messageSent: string;

  // Resultado
  gotResponse: boolean;
  responseTime?: number;      // Em minutos
  responseQuality?: 'cold' | 'neutral' | 'warm' | 'hot';

  // Análise da IA
  whyWorked?: string;         // Análise de por que funcionou
  whyFailed?: string;         // Análise de por que falhou

  // Controle
  timestamp: Date;
}

// ═══════════════════════════════════════════════════════════════════
// 🔗 LINK ENTRE CONVERSA E AVATAR COLETIVO
// ═══════════════════════════════════════════════════════════════════

/**
 * Extensão da conversa para vincular ao avatar coletivo
 */
export interface ConversationCollectiveLink {
  conversationId: string;
  collectiveAvatarId: string;

  // Contribuições desta conversa para o coletivo
  contributedInsights: string[];  // IDs dos insights adicionados
  feedbackCount: number;          // Quantos feedbacks enviados

  // Se o usuário optou por não compartilhar (privacy)
  sharingEnabled: boolean;
}

// ═══════════════════════════════════════════════════════════════════
// 🛠️ REQUESTS
// ═══════════════════════════════════════════════════════════════════

export interface FindOrCreateCollectiveAvatarRequest {
  name: string;
  platform: string;
  bio?: string;
  age?: string;
  location?: string;
  interests?: string[];
  username?: string;         // Para Instagram: @usuario (sem @)
  faceImageBase64?: string;  // Imagem do rosto em base64
  faceDescription?: string;  // Descrição textual do rosto
}

export interface SubmitFeedbackRequest {
  conversationId: string;
  messageId: string;
  gotResponse: boolean;
  responseTime?: number;
  responseQuality?: 'cold' | 'neutral' | 'warm' | 'hot';
}

export interface AnalyzeAvatarRequest {
  collectiveAvatarId: string;
  forceReanalysis?: boolean;
}

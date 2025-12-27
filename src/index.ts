import Fastify from 'fastify';
import cors from '@fastify/cors';
import { env } from './config/env';
import { analyzeMessage } from './services/anthropic';
import { AnalyzeRequest, AnalyzeResponse } from './types';
import {
  ProfileAnalyzerAgent,
  FirstMessageAgent,
  InstagramOpenerAgent,
  ConversationReplyAgent,
  ProfileImageAnalyzerAgent,
  ConversationImageAnalyzerAgent,
  UserContext,
} from './agents';
import { ConversationManager } from './services/conversation-manager';
import {
  CreateConversationRequest,
  AddMessageRequest,
  GenerateSuggestionsRequest,
} from './types/conversation';
import { getSystemPromptForTone } from './prompts';
import {
  createCheckoutSession,
  createEmbeddedCheckout,
  createCustomerPortalSession,
  constructWebhookEvent,
  handleCheckoutCompleted,
  handleSubscriptionUpdated,
  handleSubscriptionDeleted,
  handleInvoicePaid,
  handlePaymentFailed,
} from './services/stripe';
import { verifyAuth, verifyAuthOnly, AuthenticatedRequest } from './middleware/auth';
import { CollectiveAvatarManager } from './services/collective-avatar-manager';
import { TrainingFeedbackService } from './services/training-feedback-service';
import { CreateTrainingFeedbackRequest, UpdateTrainingFeedbackRequest } from './types/training-feedback';
import Stripe from 'stripe';

const fastify = Fastify({
  logger: true,
  bodyLimit: 50 * 1024 * 1024, // 50MB para suportar imagens grandes em base64
});

// Habilitar CORS
fastify.register(cors, {
  origin: true, // Aceita qualquer origem
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
});

// Raw body parser for Stripe webhooks
fastify.addContentTypeParser(
  'application/json',
  { parseAs: 'buffer' },
  (req, body, done) => {
    // Store raw body for webhook verification
    (req as any).rawBody = body;
    try {
      const json = JSON.parse(body.toString());
      done(null, json);
    } catch (err: any) {
      done(err, undefined);
    }
  }
);

const analyzeSchema = {
  body: {
    type: 'object',
    required: ['text'],
    properties: {
      text: { type: 'string', minLength: 1 },
    },
  },
};

fastify.post<{ Body: AnalyzeRequest }>(
  '/analyze',
  { schema: analyzeSchema },
  async (request, reply) => {
    try {
      const { text } = request.body;

      // Expert mode - calibra automaticamente
      const analysis = await analyzeMessage({ text, tone: 'expert' });

      const response: AnalyzeResponse = {
        analysis,
      };

      return reply.code(200).send(response);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: 'Erro ao processar análise',
        message: error instanceof Error ? error.message : 'Erro desconhecido',
      });
    }
  }
);

fastify.get('/health', async (request, reply) => {
  return {
    status: 'ok',
    version: '2.2.0',
    timestamp: new Date().toISOString(),
    endpoints: ['/set-password', '/webhook/stripe', '/checkout-session/:sessionId', '/create-embedded-checkout', '/create-stripe-embedded-session']
  };
});

// Nova rota: Analisar perfil de apps de namoro
fastify.post('/analyze-profile', async (request, reply) => {
  try {
    const { bio, platform, photoDescription, name, age, userContext } = request.body as any;

    const agent = new ProfileAnalyzerAgent();
    const result = await agent.execute(
      { bio, platform, photoDescription, name, age },
      userContext as UserContext
    );

    return reply.code(200).send({ analysis: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao analisar perfil',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Nova rota: Gerar primeira mensagem (com inteligência coletiva por características)
fastify.post('/generate-first-message', async (request, reply) => {
  try {
    const { matchName, matchBio, platform, photoDescription, specificDetail, userContext } =
      request.body as any;

    // Extrair características do perfil para buscar insights relevantes
    const profileTags = extractProfileTags(matchBio, photoDescription);
    console.log(`[Collective] Tags extraídas do perfil:`, profileTags);

    // Buscar insights da inteligência coletiva por CARACTERÍSTICAS, não por nome
    let collectiveInsights;
    try {
      const insights = await getInsightsByTags(profileTags, platform || 'tinder');

      if (insights) {
        collectiveInsights = {
          whatWorks: insights.whatWorks,
          whatDoesntWork: insights.whatDoesntWork,
          goodOpenerExamples: insights.goodExamples,
          badOpenerExamples: insights.badExamples,
          bestOpenerTypes: insights.bestTypes,
          matchedTags: insights.matchedTags,
        };
        console.log(`[Collective] Insights encontrados para tags:`, insights.matchedTags);
      }
    } catch (err) {
      console.warn('Não foi possível buscar insights coletivos:', err);
    }

    const agent = new FirstMessageAgent();
    const result = await agent.execute(
      { matchName, matchBio, platform, photoDescription, specificDetail, collectiveInsights },
      userContext as UserContext
    );

    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar primeira mensagem',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Extrair tags/características do perfil
function extractProfileTags(bio?: string, photoDescription?: string): string[] {
  const tags: string[] = [];
  const text = `${bio || ''} ${photoDescription || ''}`.toLowerCase();

  // Categorias de interesse
  const categories: Record<string, string[]> = {
    'praia': ['praia', 'mar', 'surf', 'beach', 'litoral', 'verão'],
    'fitness': ['academia', 'gym', 'crossfit', 'treino', 'fitness', 'musculação', 'corrida'],
    'viagem': ['viagem', 'viajar', 'travel', 'mochilão', 'aventura', 'mundo'],
    'música': ['música', 'show', 'festival', 'rock', 'sertanejo', 'pagode', 'funk', 'mpb', 'rap'],
    'pagode': ['pagode', 'samba', 'roda de samba'],
    'sertanejo': ['sertanejo', 'country', 'rodeio'],
    'balada': ['balada', 'festa', 'night', 'club', 'role'],
    'gastronomia': ['comida', 'restaurante', 'culinária', 'chef', 'cozinhar', 'foodie'],
    'pets': ['cachorro', 'gato', 'pet', 'dog', 'cat', 'animal'],
    'natureza': ['natureza', 'trilha', 'camping', 'montanha', 'cachoeira'],
    'arte': ['arte', 'museu', 'teatro', 'cinema', 'fotografia'],
    'livros': ['livro', 'leitura', 'ler', 'literatura'],
    'games': ['game', 'jogo', 'gamer', 'playstation', 'xbox', 'nintendo'],
    'esporte': ['futebol', 'vôlei', 'basquete', 'tênis', 'esporte'],
    'cerveja': ['cerveja', 'beer', 'bar', 'happy hour', 'drinks', 'vinho'],
    'café': ['café', 'coffee', 'cafeteria'],
    'netflix': ['netflix', 'série', 'series', 'filme', 'maratonar'],
    'tattoo': ['tattoo', 'tatuagem', 'tatuado'],
    'signo_agua': ['câncer', 'cancer', 'canceriana', 'escorpião', 'escorpiana', 'peixes', 'pisciana'],
    'signo_fogo': ['áries', 'aries', 'ariana', 'leão', 'leonina', 'sagitário', 'sagitariana'],
    'signo_terra': ['touro', 'taurina', 'virgem', 'virginiana', 'capricórnio', 'capricorniana'],
    'signo_ar': ['gêmeos', 'geminiana', 'libra', 'libriana', 'aquário', 'aquariana'],
  };

  for (const [tag, keywords] of Object.entries(categories)) {
    if (keywords.some(kw => text.includes(kw))) {
      tags.push(tag);
    }
  }

  return tags;
}

// Buscar insights por tags no Firestore
async function getInsightsByTags(tags: string[], platform: string): Promise<any | null> {
  if (tags.length === 0) return null;

  try {
    const db = require('firebase-admin').firestore();

    // Buscar insights agregados por tag
    const insightsRef = db.collection('tagInsights');
    const allInsights: any = {
      whatWorks: [],
      whatDoesntWork: [],
      goodExamples: [],
      badExamples: [],
      bestTypes: [],
      matchedTags: [],
    };

    for (const tag of tags) {
      const docId = `${tag}_${platform}`;
      const doc = await insightsRef.doc(docId).get();

      if (doc.exists) {
        const data = doc.data();
        allInsights.matchedTags.push(tag);

        if (data.whatWorks) allInsights.whatWorks.push(...data.whatWorks);
        if (data.whatDoesntWork) allInsights.whatDoesntWork.push(...data.whatDoesntWork);
        if (data.goodExamples) allInsights.goodExamples.push(...data.goodExamples);
        if (data.badExamples) allInsights.badExamples.push(...data.badExamples);
        if (data.bestTypes) allInsights.bestTypes.push(...data.bestTypes);
      }
    }

    // Remover duplicatas
    allInsights.whatWorks = [...new Set(allInsights.whatWorks)].slice(0, 5);
    allInsights.whatDoesntWork = [...new Set(allInsights.whatDoesntWork)].slice(0, 5);
    allInsights.goodExamples = [...new Set(allInsights.goodExamples)].slice(0, 5);
    allInsights.badExamples = [...new Set(allInsights.badExamples)].slice(0, 3);
    allInsights.bestTypes = [...new Set(allInsights.bestTypes)].slice(0, 3);

    return allInsights.matchedTags.length > 0 ? allInsights : null;
  } catch (err) {
    console.error('Erro ao buscar insights por tags:', err);
    return null;
  }
}

// Nova rota: Gerar abertura para Instagram (com inteligência coletiva por características)
fastify.post('/generate-instagram-opener', async (request, reply) => {
  try {
    const { username, bio, recentPosts, stories, approachType, specificPost, userContext } =
      request.body as any;

    // Extrair características do perfil
    const allText = [bio, ...(recentPosts || []), ...(stories || [])].filter(Boolean).join(' ');
    const profileTags = extractProfileTags(allText);
    console.log(`[Collective] Tags Instagram extraídas:`, profileTags);

    // Buscar insights por características
    let collectiveInsights;
    try {
      const insights = await getInsightsByTags(profileTags, 'instagram');

      if (insights) {
        collectiveInsights = {
          whatWorks: insights.whatWorks,
          whatDoesntWork: insights.whatDoesntWork,
          goodOpenerExamples: insights.goodExamples,
          badOpenerExamples: insights.badExamples,
          matchedTags: insights.matchedTags,
        };
        console.log(`[Collective] Insights Instagram para tags:`, insights.matchedTags);
      }
    } catch (err) {
      console.warn('Não foi possível buscar insights coletivos:', err);
    }

    const agent = new InstagramOpenerAgent();
    const result = await agent.execute(
      { username, bio, recentPosts, stories, approachType, specificPost, collectiveInsights },
      userContext as UserContext
    );

    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar abertura do Instagram',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Nova rota: Responder mensagem (expert mode - calibra automaticamente)
fastify.post('/reply', async (request, reply) => {
  try {
    // APENAS receivedMessage importa - ignorar perfil/bio/contexto
    const { receivedMessage, conversationHistory } = request.body as any;

    const agent = new ConversationReplyAgent();
    const result = await agent.execute({
      receivedMessage,
      conversationHistory,
      // NÃO passa matchName, context, platform - foco 100% na mensagem
    });

    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar resposta',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Nova rota: Responder mensagem COM RACIOCÍNIO (para desenvolvedores)
fastify.post('/reply-with-reasoning', async (request, reply) => {
  try {
    // APENAS receivedMessage importa - ignorar perfil/bio/contexto
    const { receivedMessage, conversationHistory } = request.body as any;

    const agent = new ConversationReplyAgent();
    const result = await agent.executeWithReasoning({
      receivedMessage,
      conversationHistory,
      // NÃO passa matchName, context, platform - foco 100% na mensagem
    });

    return reply.code(200).send({
      analysis: result.analysis,
      suggestions: result.suggestions,
      rawResponse: result.rawResponse,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar resposta com raciocínio',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Salvar feedback do desenvolvedor sobre sugestões
fastify.post('/developer-feedback', async (request, reply) => {
  try {
    const {
      inputData,       // Dados de entrada (mensagem recebida, contexto, etc)
      analysis,        // Análise gerada pela IA
      suggestions,     // Sugestões geradas
      selectedIndex,   // Qual sugestão foi escolhida (se alguma)
      feedbackType,    // 'good' | 'bad' | 'partial'
      feedbackNote,    // Nota do desenvolvedor explicando o problema
      correctedSuggestion, // Sugestão corrigida (se houver)
    } = request.body as any;

    const admin = require('firebase-admin');
    const db = admin.firestore();

    // Salvar no Firestore
    const feedbackRef = await db.collection('developerFeedback').add({
      inputData,
      analysis,
      suggestions,
      selectedIndex,
      feedbackType,
      feedbackNote,
      correctedSuggestion,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      processed: false, // Flag para saber se já foi processado para retraining
    });

    console.log('📝 Developer feedback saved:', feedbackRef.id);

    return reply.code(201).send({
      success: true,
      id: feedbackRef.id,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao salvar feedback',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Listar feedbacks do desenvolvedor (para análise)
fastify.get('/developer-feedback', async (request, reply) => {
  try {
    const { processed, limit: limitParam } = request.query as { processed?: string; limit?: string };
    const admin = require('firebase-admin');
    const db = admin.firestore();

    let query = db.collection('developerFeedback').orderBy('createdAt', 'desc');

    if (processed !== undefined) {
      query = query.where('processed', '==', processed === 'true');
    }

    const limitNum = parseInt(limitParam || '50', 10);
    query = query.limit(limitNum);

    const snapshot = await query.get();
    const feedbacks = snapshot.docs.map((doc: any) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
    }));

    return reply.send(feedbacks);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao listar feedbacks',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Exportar feedbacks para arquivo (para retraining)
fastify.get('/developer-feedback/export', async (request, reply) => {
  try {
    const admin = require('firebase-admin');
    const db = admin.firestore();

    const snapshot = await db.collection('developerFeedback')
      .where('processed', '==', false)
      .orderBy('createdAt', 'asc')
      .get();

    const feedbacks = snapshot.docs.map((doc: any) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
    }));

    // Formato para retraining
    const trainingData = feedbacks.map((fb: any) => ({
      input: fb.inputData,
      analysis: fb.analysis,
      suggestions: fb.suggestions,
      feedback: {
        type: fb.feedbackType,
        note: fb.feedbackNote,
        corrected: fb.correctedSuggestion,
      },
    }));

    return reply.send({
      count: trainingData.length,
      data: trainingData,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao exportar feedbacks',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Nova rota: Analisar imagem de perfil
fastify.post('/analyze-profile-image', async (request, reply) => {
  try {
    const { imageBase64, imageMediaType, platform } = request.body as any;

    console.log('📸 Recebendo requisição de análise de imagem');
    console.log('Platform:', platform);
    console.log('Media Type:', imageMediaType);
    console.log('Image Base64 length:', imageBase64?.length);

    if (!imageBase64) {
      return reply.code(400).send({
        error: 'Imagem não fornecida',
        message: 'O campo imageBase64 é obrigatório',
      });
    }

    const agent = new ProfileImageAnalyzerAgent();
    console.log('🤖 Iniciando análise com Claude Vision...');

    const result = await agent.analyzeImageAndParse({
      imageBase64,
      imageMediaType: imageMediaType || 'image/jpeg',
      platform,
    });

    console.log('✅ Análise concluída com sucesso');
    return reply.code(200).send({ extractedData: result });
  } catch (error) {
    console.error('❌ Erro ao analisar imagem:', error);
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao analisar imagem',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
      stack: error instanceof Error ? error.stack : undefined,
    });
  }
});

// Nova rota: Analisar screenshot de conversa (OCR para extrair mensagem)
fastify.post('/analyze-conversation-image', async (request, reply) => {
  try {
    const { imageBase64, imageMediaType, platform } = request.body as any;

    console.log('💬 Recebendo requisição de análise de screenshot de conversa');
    console.log('Platform:', platform);
    console.log('Media Type:', imageMediaType);
    console.log('Image Base64 length:', imageBase64?.length);

    if (!imageBase64) {
      return reply.code(400).send({
        error: 'Imagem não fornecida',
        message: 'O campo imageBase64 é obrigatório',
      });
    }

    const agent = new ConversationImageAnalyzerAgent();
    console.log('🤖 Iniciando análise de conversa com Claude Vision...');

    const result = await agent.analyzeAndExtract({
      imageBase64,
      imageMediaType: imageMediaType || 'image/jpeg',
      platform,
    });

    console.log('✅ Análise de conversa concluída');
    return reply.code(200).send({ extractedData: result });
  } catch (error) {
    console.error('❌ Erro ao analisar screenshot de conversa:', error);
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao analisar screenshot',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 💬 ENDPOINTS DE GERENCIAMENTO DE CONVERSAS (COM AUTENTICAÇÃO)
// ═══════════════════════════════════════════════════════════════════

// Criar nova conversa (ou retorna existente se já houver uma com o mesmo avatar)
fastify.post('/conversations', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const body = request.body as CreateConversationRequest;
    const userId = request.user!.uid;
    const conversation = await ConversationManager.createConversation({ ...body, userId });

    // Se é conversa existente, retorna 200; se nova, retorna 201
    const statusCode = conversation.isExisting ? 200 : 201;
    return reply.code(statusCode).send(conversation);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao criar conversa',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Listar conversas do usuário
fastify.get('/conversations', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const userId = request.user!.uid;
    const conversations = await ConversationManager.listConversations(userId);
    return reply.code(200).send(conversations);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao listar conversas',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Obter conversa específica
fastify.get('/conversations/:id', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const conversation = await ConversationManager.getConversation(id, userId);

    if (!conversation) {
      return reply.code(404).send({ error: 'Conversa não encontrada' });
    }

    return reply.code(200).send(conversation);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao obter conversa',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Adicionar mensagem à conversa
fastify.post('/conversations/:id/messages', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const body = request.body as Omit<AddMessageRequest, 'conversationId'>;

    const conversation = await ConversationManager.addMessage({
      conversationId: id,
      userId,
      ...body,
    });

    return reply.code(200).send(conversation);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao adicionar mensagem',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Gerar sugestões baseadas no histórico completo
fastify.post('/conversations/:id/suggestions', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const { receivedMessage } = request.body as Omit<
      GenerateSuggestionsRequest,
      'conversationId'
    >;

    const conversation = await ConversationManager.getConversation(id, userId);
    if (!conversation) {
      return reply.code(404).send({ error: 'Conversa não encontrada' });
    }

    // Adicionar a mensagem recebida ao histórico
    await ConversationManager.addMessage({
      conversationId: id,
      userId,
      role: 'match',
      content: receivedMessage,
    });

    // Pegar APENAS as últimas mensagens para contexto de fluxo
    const conversationHistory: Array<{ sender: 'user' | 'match'; message: string }> = [];
    if (conversation.messages) {
      // Só as últimas 4 mensagens - sem perfil, sem bio, só o papo
      const recentMessages = conversation.messages.slice(-4);
      for (const msg of recentMessages) {
        conversationHistory.push({
          sender: msg.role === 'user' ? 'user' : 'match',
          message: msg.content,
        });
      }
    }

    // Usar o ConversationReplyAgent - SEM CONTEXTO DE PERFIL
    const replyAgent = new ConversationReplyAgent();
    const response = await replyAgent.execute({
      receivedMessage,
      conversationHistory,
      // NÃO passa context, matchName, platform - foco 100% na mensagem
    });

    return reply.code(200).send({ suggestions: response });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar sugestões',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Atualizar tom da conversa
fastify.patch('/conversations/:id/tone', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const { tone } = request.body as { tone: string };

    await ConversationManager.updateTone(id, userId, tone);

    return reply.code(200).send({ success: true });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao atualizar tom',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// Deletar conversa
fastify.delete('/conversations/:id', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  console.log('[DELETE] Endpoint reached');
  try {
    const { id } = request.params as { id: string };
    console.log(`[DELETE] Conversation ID: ${id}`);

    if (!request.user) {
      console.log('[DELETE] No user in request');
      return reply.code(401).send({ error: 'User not authenticated' });
    }

    const userId = request.user.uid;
    console.log(`[DELETE] User ID: ${userId}`);

    const deleted = await ConversationManager.deleteConversation(id, userId);
    console.log(`[DELETE] Delete result: ${deleted}`);

    if (!deleted) {
      console.log(`[DELETE] Conversation ${id} not found or not owned by user`);
      return reply.code(404).send({ error: 'Conversa não encontrada' });
    }

    console.log(`[DELETE] Conversation ${id} deleted successfully`);
    return reply.code(200).send({ success: true });
  } catch (error) {
    console.error('[DELETE] Error:', error);
    return reply.code(500).send({
      error: 'Erro ao deletar conversa',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 🧠 ENDPOINTS DE INTELIGÊNCIA COLETIVA
// ═══════════════════════════════════════════════════════════════════

// Submeter feedback sobre mensagem (funcionou/não funcionou)
fastify.post('/conversations/:id/feedback', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const { messageId, gotResponse, responseQuality } = request.body as {
      messageId: string;
      gotResponse: boolean;
      responseQuality?: 'cold' | 'neutral' | 'warm' | 'hot';
    };

    await ConversationManager.submitMessageFeedback(
      id,
      userId,
      messageId,
      gotResponse,
      responseQuality
    );

    return reply.code(200).send({ success: true });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao submeter feedback',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 💳 STRIPE ENDPOINTS
// ═══════════════════════════════════════════════════════════════════

// Create Stripe Checkout Session
// Uses verifyAuthOnly because user needs to be logged in but may not have subscription yet
fastify.post('/create-checkout-session', {
  preHandler: verifyAuthOnly,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const { priceId, plan } = request.body as {
      priceId: string;
      plan: 'monthly' | 'quarterly' | 'yearly';
    };

    const user = request.user!;

    if (!user.email) {
      return reply.code(400).send({
        error: 'Email not found',
        message: 'User email is required to create checkout session',
      });
    }

    // Create Stripe Checkout Session
    const session = await createCheckoutSession({
      priceId,
      plan,
      userId: user.uid,
      userEmail: user.email,
    });

    return reply.code(200).send({
      url: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Failed to create checkout session',
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// Create Embedded Checkout (for custom checkout page)
// Public endpoint - no auth required (user provides email)
fastify.post('/create-embedded-checkout', async (request, reply) => {
  try {
    const { priceId, plan, email, name } = request.body as {
      priceId: string;
      plan: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';
      email: string;
      name?: string;
    };

    if (!priceId || !plan || !email) {
      return reply.code(400).send({
        error: 'Missing required fields',
        message: 'priceId, plan, and email are required',
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return reply.code(400).send({
        error: 'Invalid email',
        message: 'Please provide a valid email address',
      });
    }

    const result = await createEmbeddedCheckout({
      priceId,
      plan,
      email: email.toLowerCase().trim(),
      name,
    });

    return reply.code(200).send(result);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Failed to create checkout',
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// Create Stripe Embedded Checkout Session (ui_mode: 'embedded')
// This is the most reliable embedded checkout method
fastify.post('/create-stripe-embedded-session', async (request, reply) => {
  try {
    const { priceId, plan, email, name } = request.body as {
      priceId: string;
      plan: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly';
      email: string;
      name?: string;
    };

    if (!priceId || !plan || !email) {
      return reply.code(400).send({
        error: 'Missing required fields',
        message: 'priceId, plan, and email are required',
      });
    }

    const stripeClient = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
      apiVersion: '2023-10-16',
    });

    const frontendUrl = process.env.FRONTEND_URL || 'https://desenrola-ia.web.app';

    // Get or create customer
    let customer: Stripe.Customer;
    const existingCustomers = await stripeClient.customers.list({
      email: email.toLowerCase().trim(),
      limit: 1,
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      // Update name if provided
      if (name && !customer.name) {
        await stripeClient.customers.update(customer.id, { name });
      }
    } else {
      customer = await stripeClient.customers.create({
        email: email.toLowerCase().trim(),
        name: name || undefined,
        metadata: { source: 'embedded_checkout_session' },
      });
    }

    // Create embedded checkout session
    const session = await stripeClient.checkout.sessions.create({
      ui_mode: 'embedded',
      customer: customer.id,
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      return_url: `${frontendUrl}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      metadata: { plan, email: email.toLowerCase().trim(), source: 'embedded_checkout_session' },
      subscription_data: {
        metadata: { plan, source: 'embedded_checkout_session' }
      },
      allow_promotion_codes: true,
    });

    console.log('💳 Stripe embedded session created:', {
      sessionId: session.id,
      customerId: customer.id,
      plan,
      priceId,
    });

    return reply.code(200).send({
      clientSecret: session.client_secret,
      sessionId: session.id,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Failed to create checkout session',
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// Test endpoint without auth
fastify.post('/test-portal', async (request, reply) => {
  console.log('=== TEST PORTAL CALLED ===');
  return reply.code(200).send({ test: 'ok' });
});

// Create Stripe Customer Portal Session (for managing subscription)
fastify.post('/create-portal-session', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  console.log('=== PORTAL SESSION START ===');

  try {
    const user = request.user;
    if (!user) {
      console.log('ERROR: No user in request');
      return reply.code(401).send({ error: 'Not authenticated', message: 'No user found' });
    }
    console.log('User ID:', user.uid);

    const admin = require('firebase-admin');
    const db = admin.firestore();

    // Get user's Stripe customer ID from Firestore
    console.log('Getting user doc...');
    const userDoc = await db.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      console.log('ERROR: User doc not found');
      return reply.code(404).send({
        error: 'User not found',
        message: 'User document not found in database',
      });
    }

    const userData = userDoc.data();
    const customerId = userData?.subscription?.stripeCustomerId;
    console.log('Stripe Customer ID:', customerId || 'NOT FOUND');

    if (!customerId) {
      console.log('ERROR: No Stripe customer ID');
      return reply.code(400).send({
        error: 'No subscription found',
        message: 'Usuário não possui assinatura Stripe vinculada',
      });
    }

    // Create portal session
    const returnUrl = `${process.env.FRONTEND_URL || 'https://desenrola-ia.web.app'}/`;
    const portalConfigId = process.env.STRIPE_PORTAL_CONFIG_ID;
    console.log('Return URL:', returnUrl);
    console.log('Portal Config ID:', portalConfigId || 'NOT SET');

    console.log('Calling Stripe API...');
    const session = await createCustomerPortalSession(customerId, returnUrl);
    console.log('Portal session URL:', session.url);
    console.log('=== PORTAL SESSION SUCCESS ===');

    return reply.code(200).send({
      url: session.url,
    });
  } catch (error: any) {
    console.log('=== PORTAL SESSION ERROR ===');
    console.log('Error name:', error?.name);
    console.log('Error message:', error?.message);
    console.log('Error type:', error?.type);
    console.log('Error code:', error?.code);
    console.log('Full error:', JSON.stringify(error, null, 2));

    return reply.code(500).send({
      error: 'Failed to create portal session',
      message: error?.message || 'Unknown error',
      type: error?.type || 'unknown',
    });
  }
});

// Get checkout session info (for success page)
fastify.get('/checkout-session/:sessionId', async (request, reply) => {
  try {
    const { sessionId } = request.params as { sessionId: string };
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
      apiVersion: '2023-10-16',
    });

    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      expand: ['line_items'],
    });

    // Extrair informações do plano
    const lineItem = session.line_items?.data?.[0];
    const amount = session.amount_total || lineItem?.amount_total || 0;
    const plan = session.metadata?.plan || 'subscription';

    return reply.code(200).send({
      email: session.customer_email || session.customer_details?.email,
      status: session.payment_status,
      amount, // em centavos
      plan,
    });
  } catch (error: any) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Failed to get session',
      message: error.message,
    });
  }
});

// Set password for new user (after purchase)
fastify.post('/set-password', async (request, reply) => {
  try {
    const { email, password } = request.body as { email: string; password: string };

    if (!email || !password) {
      return reply.code(400).send({ error: 'Email e senha são obrigatórios' });
    }

    if (password.length < 6) {
      return reply.code(400).send({ error: 'Senha deve ter no mínimo 6 caracteres' });
    }

    const admin = require('firebase-admin');
    const db = admin.firestore();

    // Check if user exists and needs password setup
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      return reply.code(404).send({
        error: 'Usuário não encontrado',
        message: 'Nenhum usuário encontrado com este email',
      });
    }

    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();

    // Verify user has active subscription (purchased)
    if (!userData.subscription || userData.subscription.status !== 'active') {
      return reply.code(403).send({
        error: 'Assinatura não encontrada',
        message: 'Complete a compra primeiro',
      });
    }

    // Get or create Firebase Auth user
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        return reply.code(404).send({
          error: 'Usuário não encontrado',
          message: 'Nenhum usuário encontrado com este email',
        });
      }
      throw error;
    }

    // Update the user's password
    await admin.auth().updateUser(userRecord.uid, {
      password: password,
    });

    // Mark password as set
    await db.collection('users').doc(userDoc.id).update({
      needsPasswordSetup: false,
      passwordSetAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Password set for user:', email);

    return reply.code(200).send({
      success: true,
      message: 'Senha definida com sucesso',
    });
  } catch (error: any) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao definir senha',
      message: error.message,
    });
  }
});

// Resend password reset email
fastify.post('/resend-password-email', async (request, reply) => {
  try {
    const { email } = request.body as { email: string };

    if (!email) {
      return reply.code(400).send({ error: 'Email is required' });
    }

    const admin = require('firebase-admin');

    // Generate password reset link
    const resetLink = await admin.auth().generatePasswordResetLink(email, {
      url: `${process.env.FRONTEND_URL || 'https://desenrola-ia.web.app'}/login`,
    });

    console.log('🔑 Password reset link generated for:', email);

    // For now, we just confirm it was generated
    // In production, you would send this via email service
    return reply.code(200).send({
      success: true,
      message: 'Password reset email sent',
    });
  } catch (error: any) {
    fastify.log.error(error);

    if (error.code === 'auth/user-not-found') {
      return reply.code(404).send({
        error: 'User not found',
        message: 'No user found with this email',
      });
    }

    return reply.code(500).send({
      error: 'Failed to send password reset email',
      message: error.message,
    });
  }
});

// Stripe Webhook Handler
// URL: https://dating-app-production-ac43.up.railway.app/webhook/stripe
fastify.post('/webhook/stripe', async (request, reply) => {
  const sig = request.headers['stripe-signature'] as string;

  if (!sig) {
    console.error('❌ Missing stripe-signature header');
    return reply.code(400).send({ error: 'Missing signature' });
  }

  let event: Stripe.Event;

  try {
    const rawBody = (request as any).rawBody as Buffer;
    event = constructWebhookEvent(rawBody, sig);
  } catch (err: any) {
    console.error('❌ Webhook signature verification failed:', err.message);
    return reply.code(400).send({ error: `Webhook Error: ${err.message}` });
  }

  console.log('📨 Stripe webhook received:', event.type);

  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;

      case 'invoice.paid':
        await handleInvoicePaid(event.data.object as Stripe.Invoice);
        break;

      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object as Stripe.Invoice);
        break;

      default:
        console.log(`⚠️ Unhandled event type: ${event.type}`);
    }

    return reply.code(200).send({ received: true });
  } catch (error: any) {
    console.error('❌ Error processing webhook:', error);
    return reply.code(500).send({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 📚 TRAINING FEEDBACK ENDPOINTS
// ═══════════════════════════════════════════════════════════════════

// Criar novo feedback de treinamento
fastify.post('/training-feedback', async (request, reply) => {
  try {
    const body = request.body as CreateTrainingFeedbackRequest;

    if (!body.category || !body.instruction) {
      return reply.code(400).send({
        error: 'category e instruction são obrigatórios',
      });
    }

    const feedback = await TrainingFeedbackService.create(body);
    return reply.code(201).send(feedback);
  } catch (error: any) {
    console.error('Erro ao criar training feedback:', error);
    return reply.code(500).send({ error: error.message });
  }
});

// Listar todos os feedbacks
fastify.get('/training-feedback', async (request, reply) => {
  try {
    const { active } = request.query as { active?: string };

    const feedbacks = active === 'true'
      ? await TrainingFeedbackService.getAllActive()
      : await TrainingFeedbackService.getAll();

    return reply.send(feedbacks);
  } catch (error: any) {
    console.error('Erro ao listar training feedback:', error);
    return reply.code(500).send({ error: error.message });
  }
});

// Buscar feedbacks por categoria
fastify.get('/training-feedback/category/:category', async (request, reply) => {
  try {
    const { category } = request.params as { category: string };
    const feedbacks = await TrainingFeedbackService.getByCategory(category as any);
    return reply.send(feedbacks);
  } catch (error: any) {
    console.error('Erro ao buscar training feedback por categoria:', error);
    return reply.code(500).send({ error: error.message });
  }
});

// Obter contexto de treinamento para prompts
fastify.get('/training-feedback/context', async (request, reply) => {
  try {
    const { category } = request.query as { category?: string };
    const context = await TrainingFeedbackService.generatePromptContext(category as any);
    return reply.send({ context });
  } catch (error: any) {
    console.error('Erro ao gerar contexto de treinamento:', error);
    return reply.code(500).send({ error: error.message });
  }
});

// Atualizar feedback
fastify.patch('/training-feedback/:id', async (request, reply) => {
  try {
    const { id } = request.params as { id: string };
    const body = request.body as Partial<UpdateTrainingFeedbackRequest>;

    const feedback = await TrainingFeedbackService.update({ id, ...body });

    if (!feedback) {
      return reply.code(404).send({ error: 'Feedback não encontrado' });
    }

    return reply.send(feedback);
  } catch (error: any) {
    console.error('Erro ao atualizar training feedback:', error);
    return reply.code(500).send({ error: error.message });
  }
});

// Deletar feedback
fastify.delete('/training-feedback/:id', async (request, reply) => {
  try {
    const { id } = request.params as { id: string };
    const deleted = await TrainingFeedbackService.delete(id);

    if (!deleted) {
      return reply.code(404).send({ error: 'Feedback não encontrado' });
    }

    return reply.send({ success: true });
  } catch (error: any) {
    console.error('Erro ao deletar training feedback:', error);
    return reply.code(500).send({ error: error.message });
  }
});

const start = async () => {
  try {
    await fastify.listen({ port: env.PORT, host: '0.0.0.0' });
    console.log(`🚀 Servidor rodando na porta ${env.PORT}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

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
  constructWebhookEvent,
  handleCheckoutCompleted,
  handleSubscriptionUpdated,
  handleSubscriptionDeleted,
  handleInvoicePaid,
  handlePaymentFailed,
} from './services/stripe';
import { verifyAuth, verifyAuthOnly, AuthenticatedRequest } from './middleware/auth';
import Stripe from 'stripe';

const fastify = Fastify({
  logger: true,
});

// Habilitar CORS
fastify.register(cors, {
  origin: true, // Aceita qualquer origem (para desenvolvimento)
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
    required: ['text', 'tone'],
    properties: {
      text: { type: 'string', minLength: 1 },
      tone: {
        type: 'string',
        enum: ['engraçado', 'ousado', 'romântico', 'casual', 'confiante', 'expert'],
      },
    },
  },
};

fastify.post<{ Body: AnalyzeRequest }>(
  '/analyze',
  { schema: analyzeSchema },
  async (request, reply) => {
    try {
      const { text, tone } = request.body;

      const analysis = await analyzeMessage({ text, tone });

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
  return { status: 'ok', timestamp: new Date().toISOString() };
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

// Nova rota: Gerar primeira mensagem
fastify.post('/generate-first-message', async (request, reply) => {
  try {
    const { matchName, matchBio, platform, tone, photoDescription, specificDetail, userContext } =
      request.body as any;

    const agent = new FirstMessageAgent();
    const result = await agent.execute(
      { matchName, matchBio, platform, tone, photoDescription, specificDetail },
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

// Nova rota: Gerar abertura para Instagram
fastify.post('/generate-instagram-opener', async (request, reply) => {
  try {
    const { username, bio, recentPosts, stories, tone, approachType, specificPost, userContext } =
      request.body as any;

    const agent = new InstagramOpenerAgent();
    const result = await agent.execute(
      { username, bio, recentPosts, stories, tone, approachType, specificPost },
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

// Nova rota: Responder mensagem (versão melhorada)
fastify.post('/reply', async (request, reply) => {
  try {
    const { receivedMessage, conversationHistory, tone, matchName, context, userContext } =
      request.body as any;

    const agent = new ConversationReplyAgent();
    const result = await agent.execute(
      { receivedMessage, conversationHistory, tone, matchName, context },
      userContext as UserContext
    );

    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao gerar resposta',
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

// ═══════════════════════════════════════════════════════════════════
// 💬 ENDPOINTS DE GERENCIAMENTO DE CONVERSAS (COM AUTENTICAÇÃO)
// ═══════════════════════════════════════════════════════════════════

// Criar nova conversa
fastify.post('/conversations', {
  preHandler: verifyAuth,
}, async (request: AuthenticatedRequest, reply) => {
  try {
    const body = request.body as CreateConversationRequest;
    const userId = request.user!.uid;
    const conversation = await ConversationManager.createConversation({ ...body, userId });
    return reply.code(201).send(conversation);
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
    const { receivedMessage, tone, userContext } = request.body as Omit<
      GenerateSuggestionsRequest,
      'conversationId'
    >;

    const conversation = await ConversationManager.getConversation(id, userId);
    if (!conversation) {
      return reply.code(404).send({ error: 'Conversa não encontrada' });
    }

    // Primeiro, adicionar a mensagem recebida ao histórico
    await ConversationManager.addMessage({
      conversationId: id,
      userId,
      role: 'match',
      content: receivedMessage,
    });

    // Obter histórico formatado com calibragem
    const formattedHistory = await ConversationManager.getFormattedHistory(id, userId);

    // Selecionar prompt baseado no tom
    const systemPrompt = getSystemPromptForTone(tone);

    // Construir contexto do usuário
    let userContextStr = '';
    if (userContext) {
      userContextStr = `
═══════════════════════════════════════════════════════════════════
👤 SEU PERFIL
═══════════════════════════════════════════════════════════════════
${userContext.name ? `Nome: ${userContext.name}` : ''}
${userContext.age ? `Idade: ${userContext.age}` : ''}
${userContext.interests && userContext.interests.length > 0 ? `Interesses: ${userContext.interests.join(', ')}` : ''}
${userContext.dislikes && userContext.dislikes.length > 0 ? `⚠️ EVITE mencionar: ${userContext.dislikes.join(', ')}` : ''}
${userContext.humorStyle ? `Estilo de humor: ${userContext.humorStyle}` : ''}
${userContext.relationshipGoal ? `Objetivo: ${userContext.relationshipGoal}` : ''}
`;
    }

    // Gerar sugestões usando Claude
    const fullPrompt = `${systemPrompt}\n\n${formattedHistory}\n${userContextStr}

A mensagem mais recente que você acabou de receber foi:
"${receivedMessage}"

Com base em TODO o contexto acima (perfil do match, calibragem detectada, histórico completo), gere APENAS 3 sugestões de resposta que:
1. ESPELHEM o tamanho de resposta detectado
2. ADAPTEM ao tom emocional detectado
3. MANTENHAM a qualidade da conversa
4. AVANCEM a interação de forma natural`;

    const response = await analyzeMessage({
      text: fullPrompt,
      tone: tone as any,
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
  try {
    const { id } = request.params as { id: string };
    const userId = request.user!.uid;
    const deleted = await ConversationManager.deleteConversation(id, userId);

    if (!deleted) {
      return reply.code(404).send({ error: 'Conversa não encontrada' });
    }

    return reply.code(200).send({ success: true });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: 'Erro ao deletar conversa',
      message: error instanceof Error ? error.message : 'Erro desconhecido',
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
      plan: 'monthly' | 'yearly';
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

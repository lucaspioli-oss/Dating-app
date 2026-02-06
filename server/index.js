"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_1 = __importDefault(require("fastify"));
const cors_1 = __importDefault(require("@fastify/cors"));
const env_1 = require("./config/env");
const anthropic_1 = require("./services/anthropic");
const agents_1 = require("./agents");
const conversation_manager_1 = require("./services/conversation-manager");
const prompts_1 = require("./prompts");
const stripe_1 = require("./services/stripe");
const auth_1 = require("./middleware/auth");
const fastify = (0, fastify_1.default)({
    logger: true,
});
// Habilitar CORS
fastify.register(cors_1.default, {
    origin: true, // Aceita qualquer origem (para desenvolvimento)
});
// Raw body parser for Stripe webhooks
fastify.addContentTypeParser('application/json', { parseAs: 'buffer' }, (req, body, done) => {
    // Store raw body for webhook verification
    req.rawBody = body;
    try {
        const json = JSON.parse(body.toString());
        done(null, json);
    }
    catch (err) {
        done(err, undefined);
    }
});
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
fastify.post('/analyze', { schema: analyzeSchema }, async (request, reply) => {
    try {
        const { text, tone } = request.body;
        const analysis = await (0, anthropic_1.analyzeMessage)({ text, tone });
        const response = {
            analysis,
        };
        return reply.code(200).send(response);
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao processar análise',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
fastify.get('/health', async (request, reply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
});
// Nova rota: Analisar perfil de apps de namoro
fastify.post('/analyze-profile', async (request, reply) => {
    try {
        const { bio, platform, photoDescription, name, age, userContext } = request.body;
        const agent = new agents_1.ProfileAnalyzerAgent();
        const result = await agent.execute({ bio, platform, photoDescription, name, age }, userContext);
        return reply.code(200).send({ analysis: result });
    }
    catch (error) {
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
        const { matchName, matchBio, platform, tone, photoDescription, specificDetail, userContext } = request.body;
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
        }
        catch (err) {
            console.warn('Não foi possível buscar insights coletivos:', err);
        }
        const agent = new agents_1.FirstMessageAgent();
        const result = await agent.execute({ matchName, matchBio, platform, tone, photoDescription, specificDetail, collectiveInsights }, userContext);
        return reply.code(200).send({ suggestions: result });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao gerar primeira mensagem',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Extrair tags/características do perfil
function extractProfileTags(bio, photoDescription) {
    const tags = [];
    const text = `${bio || ''} ${photoDescription || ''}`.toLowerCase();
    // Categorias de interesse
    const categories = {
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
async function getInsightsByTags(tags, platform) {
    if (tags.length === 0)
        return null;
    try {
        const db = require('firebase-admin').firestore();
        // Buscar insights agregados por tag
        const insightsRef = db.collection('tagInsights');
        const allInsights = {
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
                if (data.whatWorks)
                    allInsights.whatWorks.push(...data.whatWorks);
                if (data.whatDoesntWork)
                    allInsights.whatDoesntWork.push(...data.whatDoesntWork);
                if (data.goodExamples)
                    allInsights.goodExamples.push(...data.goodExamples);
                if (data.badExamples)
                    allInsights.badExamples.push(...data.badExamples);
                if (data.bestTypes)
                    allInsights.bestTypes.push(...data.bestTypes);
            }
        }
        // Remover duplicatas
        allInsights.whatWorks = [...new Set(allInsights.whatWorks)].slice(0, 5);
        allInsights.whatDoesntWork = [...new Set(allInsights.whatDoesntWork)].slice(0, 5);
        allInsights.goodExamples = [...new Set(allInsights.goodExamples)].slice(0, 5);
        allInsights.badExamples = [...new Set(allInsights.badExamples)].slice(0, 3);
        allInsights.bestTypes = [...new Set(allInsights.bestTypes)].slice(0, 3);
        return allInsights.matchedTags.length > 0 ? allInsights : null;
    }
    catch (err) {
        console.error('Erro ao buscar insights por tags:', err);
        return null;
    }
}
// Nova rota: Gerar abertura para Instagram (com inteligência coletiva por características)
fastify.post('/generate-instagram-opener', async (request, reply) => {
    try {
        const { username, bio, recentPosts, stories, tone, approachType, specificPost, userContext } = request.body;
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
        }
        catch (err) {
            console.warn('Não foi possível buscar insights coletivos:', err);
        }
        const agent = new agents_1.InstagramOpenerAgent();
        const result = await agent.execute({ username, bio, recentPosts, stories, tone, approachType, specificPost, collectiveInsights }, userContext);
        return reply.code(200).send({ suggestions: result });
    }
    catch (error) {
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
        const { receivedMessage, conversationHistory, tone, matchName, context, userContext } = request.body;
        const agent = new agents_1.ConversationReplyAgent();
        const result = await agent.execute({ receivedMessage, conversationHistory, tone, matchName, context }, userContext);
        return reply.code(200).send({ suggestions: result });
    }
    catch (error) {
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
        const { imageBase64, imageMediaType, platform } = request.body;
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
        const agent = new agents_1.ProfileImageAnalyzerAgent();
        console.log('🤖 Iniciando análise com Claude Vision...');
        const result = await agent.analyzeImageAndParse({
            imageBase64,
            imageMediaType: imageMediaType || 'image/jpeg',
            platform,
        });
        console.log('✅ Análise concluída com sucesso');
        return reply.code(200).send({ extractedData: result });
    }
    catch (error) {
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
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const body = request.body;
        const userId = request.user.uid;
        const conversation = await conversation_manager_1.ConversationManager.createConversation({ ...body, userId });
        return reply.code(201).send(conversation);
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao criar conversa',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Listar conversas do usuário
fastify.get('/conversations', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const conversations = await conversation_manager_1.ConversationManager.listConversations(userId);
        return reply.code(200).send(conversations);
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao listar conversas',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Obter conversa específica
fastify.get('/conversations/:id', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const conversation = await conversation_manager_1.ConversationManager.getConversation(id, userId);
        if (!conversation) {
            return reply.code(404).send({ error: 'Conversa não encontrada' });
        }
        return reply.code(200).send(conversation);
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao obter conversa',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Adicionar mensagem à conversa
fastify.post('/conversations/:id/messages', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const body = request.body;
        const conversation = await conversation_manager_1.ConversationManager.addMessage({
            conversationId: id,
            userId,
            ...body,
        });
        return reply.code(200).send(conversation);
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao adicionar mensagem',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Gerar sugestões baseadas no histórico completo
fastify.post('/conversations/:id/suggestions', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { receivedMessage, tone, userContext } = request.body;
        const conversation = await conversation_manager_1.ConversationManager.getConversation(id, userId);
        if (!conversation) {
            return reply.code(404).send({ error: 'Conversa não encontrada' });
        }
        // Primeiro, adicionar a mensagem recebida ao histórico
        await conversation_manager_1.ConversationManager.addMessage({
            conversationId: id,
            userId,
            role: 'match',
            content: receivedMessage,
        });
        // Obter histórico formatado com calibragem
        const formattedHistory = await conversation_manager_1.ConversationManager.getFormattedHistory(id, userId);
        // Selecionar prompt baseado no tom
        const systemPrompt = (0, prompts_1.getSystemPromptForTone)(tone);
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
        const response = await (0, anthropic_1.analyzeMessage)({
            text: fullPrompt,
            tone: tone,
        });
        return reply.code(200).send({ suggestions: response });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao gerar sugestões',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Atualizar tom da conversa
fastify.patch('/conversations/:id/tone', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { tone } = request.body;
        await conversation_manager_1.ConversationManager.updateTone(id, userId, tone);
        return reply.code(200).send({ success: true });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao atualizar tom',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Deletar conversa
fastify.delete('/conversations/:id', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const deleted = await conversation_manager_1.ConversationManager.deleteConversation(id, userId);
        if (!deleted) {
            return reply.code(404).send({ error: 'Conversa não encontrada' });
        }
        return reply.code(200).send({ success: true });
    }
    catch (error) {
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
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { messageId, gotResponse, responseQuality } = request.body;
        await conversation_manager_1.ConversationManager.submitMessageFeedback(id, userId, messageId, gotResponse, responseQuality);
        return reply.code(200).send({ success: true });
    }
    catch (error) {
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
    preHandler: auth_1.verifyAuthOnly,
}, async (request, reply) => {
    try {
        const { priceId, plan } = request.body;
        const user = request.user;
        if (!user.email) {
            return reply.code(400).send({
                error: 'Email not found',
                message: 'User email is required to create checkout session',
            });
        }
        // Create Stripe Checkout Session
        const session = await (0, stripe_1.createCheckoutSession)({
            priceId,
            plan,
            userId: user.uid,
            userEmail: user.email,
        });
        return reply.code(200).send({
            url: session.url,
            sessionId: session.id,
        });
    }
    catch (error) {
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
    const sig = request.headers['stripe-signature'];
    if (!sig) {
        console.error('❌ Missing stripe-signature header');
        return reply.code(400).send({ error: 'Missing signature' });
    }
    let event;
    try {
        const rawBody = request.rawBody;
        event = (0, stripe_1.constructWebhookEvent)(rawBody, sig);
    }
    catch (err) {
        console.error('❌ Webhook signature verification failed:', err.message);
        return reply.code(400).send({ error: `Webhook Error: ${err.message}` });
    }
    console.log('📨 Stripe webhook received:', event.type);
    try {
        switch (event.type) {
            case 'checkout.session.completed':
                await (0, stripe_1.handleCheckoutCompleted)(event.data.object);
                break;
            case 'customer.subscription.updated':
                await (0, stripe_1.handleSubscriptionUpdated)(event.data.object);
                break;
            case 'customer.subscription.deleted':
                await (0, stripe_1.handleSubscriptionDeleted)(event.data.object);
                break;
            case 'invoice.paid':
                await (0, stripe_1.handleInvoicePaid)(event.data.object);
                break;
            case 'invoice.payment_failed':
                await (0, stripe_1.handlePaymentFailed)(event.data.object);
                break;
            default:
                console.log(`⚠️ Unhandled event type: ${event.type}`);
        }
        return reply.code(200).send({ received: true });
    }
    catch (error) {
        console.error('❌ Error processing webhook:', error);
        return reply.code(500).send({
            error: 'Internal server error',
            message: error.message,
        });
    }
});
const start = async () => {
    try {
        await fastify.listen({ port: env_1.env.PORT, host: '0.0.0.0' });
        console.log(`🚀 Servidor rodando na porta ${env_1.env.PORT}`);
    }
    catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();

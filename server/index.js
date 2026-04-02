"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_1 = __importDefault(require("fastify"));
const cors_1 = __importDefault(require("@fastify/cors"));
const env_1 = require("./config/env");
const { supabaseAdmin } = require("./config/supabase");
const anthropic_1 = require("./services/anthropic");
const agents_1 = require("./agents");
const conversation_manager_1 = require("./services/conversation-manager");
const prompts_1 = require("./prompts");
const stripe_1 = require("./services/stripe");
const auth_1 = require("./middleware/auth");
const { verifyRequestSignature } = require("./middleware/auth");
const instagram_crop_service_1 = require("./services/instagram-crop-service");
const face_crop_service_1 = require("./services/face-crop-service");

const fastify = (0, fastify_1.default)({ logger: true });

fastify.register(cors_1.default, {
    origin: [
        'https://desenrola-ia.web.app',
        'https://desenrola-ia.firebaseapp.com',
        'https://desenrolaai.site',
    ],
});

fastify.register(require('@fastify/rate-limit'), {
    max: 25,
    timeWindow: '1 minute',
    keyGenerator: (request) => request.user?.uid || request.ip,
});

fastify.addContentTypeParser('application/json', { parseAs: 'buffer' }, (req, body, done) => {
    req.rawBody = body;
    try {
        const json = JSON.parse(body.toString());
        done(null, json);
    } catch (err) {
        done(err, undefined);
    }
});

// ===================================================================
// GLOBAL ERROR TRACKING — logs every server error to error_logs
// ===================================================================

async function logErrorToSupabase(error, request, statusCode) {
    try {
        const userId = request?.user?.uid || null;
        const route = `${request?.method || '?'} ${request?.url || '?'}`;
        await supabaseAdmin.from('error_logs').insert({
            source: 'server',
            error_code: statusCode || 500,
            message: (error?.message || String(error)).substring(0, 2000),
            context: route,
            user_id: userId,
        });
    } catch (_) { /* error tracker must never crash the server */ }
}

fastify.setErrorHandler(async (error, request, reply) => {
    const statusCode = error.statusCode || 500;
    if (statusCode >= 500) {
        fastify.log.error(error);
        await logErrorToSupabase(error, request, statusCode);
    }
    reply.code(statusCode).send({
        error: error.message || 'Internal Server Error',
    });
});

fastify.addHook('onResponse', async (request, reply) => {
    if (reply.statusCode >= 500) {
        await logErrorToSupabase(
            { message: `HTTP ${reply.statusCode} on ${request.method} ${request.url}` },
            request,
            reply.statusCode
        );
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
                enum: ['automatico', 'engracado', 'ousado', 'romantico', 'casual', 'confiante', 'expert'],
            },
            conversationId: { type: 'string' },
            objective: {
                type: 'string',
                enum: [
                    'automatico', 'pegar_numero', 'marcar_encontro', 'modo_intimo',
                    'mudar_plataforma', 'reacender', 'virar_romantico', 'video_call',
                    'pedir_desculpas', 'criar_conexao',
                ],
            },
            language: { type: 'string', enum: ['pt', 'en', 'es'] },
        },
    },
};

fastify.post('/analyze', { schema: analyzeSchema }, async (request, reply) => {
    try {
        const { text, tone, conversationId, objective, language } = request.body;
        if (conversationId) {
            try {
                let userId = null;
                const authHeader = request.headers.authorization;
                if (authHeader && authHeader.startsWith('Bearer ')) {
                    try {
                        const token = authHeader.split(' ')[1];
                        const { data: { user: authUser } } = await supabaseAdmin.auth.getUser(token);
                        if (authUser) userId = authUser.id;
                    } catch (e) { }
                }
                if (userId) {
                    const { data: convData } = await supabaseAdmin
                        .from('conversations')
                        .select('*')
                        .eq('id', conversationId)
                        .single();

                    if (convData && convData.user_id === userId) {
                        // Save clipboard text as match's message
                        const matchMessage = {
                            id: `kb_match_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                            role: 'match',
                            content: text,
                            timestamp: new Date().toISOString(),
                            source: 'keyboard_clipboard',
                        };
                        const messages = [...(convData.messages || []), matchMessage];

                        await supabaseAdmin
                            .from('conversations')
                            .update({ messages, last_message_at: new Date().toISOString() })
                            .eq('id', conversationId);

                        const avatar = convData.avatar || {};
                        const recentMessages = messages.slice(-20);
                        let historyStr = '';
                        for (const msg of recentMessages) {
                            const role = msg.role === 'user' ? 'Voce' : (avatar.matchName || 'Match');
                            historyStr += `${role}: ${msg.content}\n`;
                        }

                        let collectiveStr = '';
                        if (convData.collective_avatar_id) {
                            const { data: avatarDoc } = await supabaseAdmin
                                .from('collective_avatars')
                                .select('collective_insights')
                                .eq('id', convData.collective_avatar_id)
                                .single();
                            if (avatarDoc) {
                                const ci = avatarDoc.collective_insights || {};
                                if (ci.whatWorks?.length > 0) collectiveStr = `\nO que funciona: ${ci.whatWorks.map(w => w.strategy || w).join(', ')}`;
                                if (ci.whatDoesntWork?.length > 0) collectiveStr += `\nO que NAO funciona: ${ci.whatDoesntWork.map(w => w.strategy || w).join(', ')}`;
                            }
                        }

                        let calibrationStr = '';
                        const patterns = avatar.detectedPatterns || {};
                        if (patterns.responseLength) calibrationStr += `\nTamanho de resposta dela: ${patterns.responseLength}`;
                        if (patterns.emotionalTone) calibrationStr += `\nTom emocional: ${patterns.emotionalTone}`;
                        if (patterns.flirtLevel) calibrationStr += `\nNivel de flerte: ${patterns.flirtLevel}`;

                        const objectiveInstruction = (0, prompts_1.getObjectivePrompt)(objective || 'automatico');
                        const richPrompt = `Voce esta ajudando a responder mensagens de dating.
Perfil da match: ${avatar.matchName || 'Desconhecida'} (${avatar.platform || 'dating app'})
${avatar.bio ? `Bio: ${avatar.bio}` : ''}
${calibrationStr}
${collectiveStr}

${objectiveInstruction}

Historico recente:
${historyStr}

A ultima mensagem dela foi:
"${text}"

Gere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).`;
                        const analysis = await (0, anthropic_1.analyzeMessage)({ text: richPrompt, tone, language });
                        return reply.code(200).send({ analysis, mode: 'pro' });
                    }
                }
            } catch (proError) {
                fastify.log.error('PRO mode error, falling back to BASIC:', proError);
            }
        }
        const basicObjective = (0, prompts_1.getObjectivePrompt)(objective || 'automatico');
        const textWithObjective = `${basicObjective}\n\nMensagem recebida:\n"${text}"\n\nGere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).`;
        const analysis = await (0, anthropic_1.analyzeMessage)({ text: textWithObjective, tone, language });
        return reply.code(200).send({ analysis, mode: 'basic' });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao processar analise', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.get('/health', async (request, reply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
});

fastify.post('/analyze-profile', async (request, reply) => {
    try {
        const { bio, platform, photoDescription, name, age, userContext, language } = request.body;
        const agent = new agents_1.ProfileAnalyzerAgent();
        if (language) agent.setLanguage(language);
        const result = await agent.execute({ bio, platform, photoDescription, name, age }, userContext);
        return reply.code(200).send({ analysis: result });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao analisar perfil', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

// Buscar insights por tags no Supabase
async function getInsightsByTags(tags, platform) {
    if (tags.length === 0) return null;
    try {
        const allInsights = { whatWorks: [], whatDoesntWork: [], goodExamples: [], badExamples: [], bestTypes: [], matchedTags: [] };

        for (const tag of tags) {
            const docId = `${tag}_${platform}`;
            const { data } = await supabaseAdmin
                .from('tag_insights')
                .select('*')
                .eq('id', docId)
                .single();

            if (data) {
                allInsights.matchedTags.push(tag);
                if (data.what_works) allInsights.whatWorks.push(...data.what_works);
                if (data.what_doesnt_work) allInsights.whatDoesntWork.push(...data.what_doesnt_work);
                if (data.good_examples) allInsights.goodExamples.push(...data.good_examples);
                if (data.bad_examples) allInsights.badExamples.push(...data.bad_examples);
                if (data.best_types) allInsights.bestTypes.push(...data.best_types);
            }
        }

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

function extractProfileTags(bio, photoDescription) {
    const tags = [];
    const text = `${bio || ''} ${photoDescription || ''}`.toLowerCase();
    const categories = {
        'praia': ['praia', 'mar', 'surf', 'beach', 'litoral'],
        'fitness': ['academia', 'gym', 'crossfit', 'treino', 'fitness'],
        'viagem': ['viagem', 'viajar', 'travel', 'aventura'],
        'musica': ['musica', 'show', 'festival', 'rock', 'sertanejo', 'pagode', 'funk'],
        'balada': ['balada', 'festa', 'night', 'club'],
        'gastronomia': ['comida', 'restaurante', 'culinaria', 'chef', 'foodie'],
        'pets': ['cachorro', 'gato', 'pet', 'dog', 'cat'],
        'natureza': ['natureza', 'trilha', 'camping', 'montanha'],
        'arte': ['arte', 'museu', 'teatro', 'cinema', 'fotografia'],
        'games': ['game', 'jogo', 'gamer', 'playstation', 'xbox'],
        'esporte': ['futebol', 'volei', 'basquete', 'tenis', 'esporte'],
        'cerveja': ['cerveja', 'beer', 'bar', 'happy hour', 'drinks'],
        'cafe': ['cafe', 'coffee', 'cafeteria'],
        'netflix': ['netflix', 'serie', 'series', 'filme'],
        'tattoo': ['tattoo', 'tatuagem', 'tatuado'],
    };
    for (const [tag, keywords] of Object.entries(categories)) {
        if (keywords.some(kw => text.includes(kw))) tags.push(tag);
    }
    return tags;
}

fastify.post('/generate-first-message', async (request, reply) => {
    try {
        const { matchName, matchBio, platform, tone, photoDescription, specificDetail, userContext, language } = request.body;
        const profileTags = extractProfileTags(matchBio, photoDescription);
        let collectiveInsights;
        try {
            const insights = await getInsightsByTags(profileTags, platform || 'tinder');
            if (insights) {
                collectiveInsights = {
                    whatWorks: insights.whatWorks, whatDoesntWork: insights.whatDoesntWork,
                    goodOpenerExamples: insights.goodExamples, badOpenerExamples: insights.badExamples,
                    bestOpenerTypes: insights.bestTypes, matchedTags: insights.matchedTags,
                };
            }
        } catch (err) { console.warn('Insights error:', err); }
        const agent = new agents_1.FirstMessageAgent();
        if (language) agent.setLanguage(language);
        const result = await agent.execute({ matchName, matchBio, platform, tone, photoDescription, specificDetail, collectiveInsights }, userContext);
        return reply.code(200).send({ suggestions: result });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gerar primeira mensagem', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/generate-instagram-opener', async (request, reply) => {
    try {
        const { username, bio, recentPosts, stories, tone, approachType, specificPost, userContext, language } = request.body;
        const allText = [bio, ...(recentPosts || []), ...(stories || [])].filter(Boolean).join(' ');
        const profileTags = extractProfileTags(allText);
        let collectiveInsights;
        try {
            const insights = await getInsightsByTags(profileTags, 'instagram');
            if (insights) {
                collectiveInsights = {
                    whatWorks: insights.whatWorks, whatDoesntWork: insights.whatDoesntWork,
                    goodOpenerExamples: insights.goodExamples, badOpenerExamples: insights.badExamples,
                    matchedTags: insights.matchedTags,
                };
            }
        } catch (err) { console.warn('Insights error:', err); }
        const agent = new agents_1.InstagramOpenerAgent();
        if (language) agent.setLanguage(language);
        const result = await agent.execute({ username, bio, recentPosts, stories, tone, approachType, specificPost, collectiveInsights }, userContext);
        return reply.code(200).send({ suggestions: result });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gerar abertura do Instagram', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/reply', async (request, reply) => {
    try {
        const { receivedMessage, conversationHistory, tone, matchName, context, userContext, language } = request.body;
        const agent = new agents_1.ConversationReplyAgent();
        if (language) agent.setLanguage(language);
        const result = await agent.execute({ receivedMessage, conversationHistory, tone, matchName, context }, userContext);
        return reply.code(200).send({ suggestions: result });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gerar resposta', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/analyze-profile-image', async (request, reply) => {
    try {
        const { imageBase64, imageMediaType, platform } = request.body;
        if (!imageBase64) return reply.code(400).send({ error: 'Imagem nao fornecida' });
        const agent = new agents_1.ProfileImageAnalyzerAgent();
        const result = await agent.analyzeImageAndParse({ imageBase64, imageMediaType: imageMediaType || 'image/jpeg', platform });
        let croppedFaceBase64 = null;
        if (result.facePosition) {
            try {
                const cropResult = await face_crop_service_1.FaceCropService.cropFace(imageBase64, result.facePosition);
                if (cropResult.success && cropResult.croppedFaceBase64) croppedFaceBase64 = cropResult.croppedFaceBase64;
            } catch (cropError) { console.warn('Face crop failed:', cropError.message); }
        }
        return reply.code(200).send({ extractedData: result, ...(croppedFaceBase64 ? { croppedFaceBase64 } : {}) });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao analisar imagem', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

// ===================================================================
// CONVERSATION ENDPOINTS (AUTH REQUIRED)
// ===================================================================

fastify.post('/conversations', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const body = request.body;
        const userId = request.user.uid;
        const conversation = await conversation_manager_1.ConversationManager.createConversation({ ...body, userId });
        return reply.code(201).send(conversation);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao criar conversa', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.get('/conversations', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const conversations = await conversation_manager_1.ConversationManager.listConversations(userId);
        return reply.code(200).send(conversations);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao listar conversas', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.get('/conversations/:id', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const conversation = await conversation_manager_1.ConversationManager.getConversation(id, userId);
        if (!conversation) return reply.code(404).send({ error: 'Conversa nao encontrada' });
        return reply.code(200).send(conversation);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao obter conversa', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/conversations/:id/messages', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const body = request.body;
        const conversation = await conversation_manager_1.ConversationManager.addMessage({ conversationId: id, userId, ...body });
        return reply.code(200).send(conversation);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao adicionar mensagem', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/conversations/:id/suggestions', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { receivedMessage, tone, userContext } = request.body;
        const conversation = await conversation_manager_1.ConversationManager.getConversation(id, userId);
        if (!conversation) return reply.code(404).send({ error: 'Conversa nao encontrada' });

        await conversation_manager_1.ConversationManager.addMessage({ conversationId: id, userId, role: 'match', content: receivedMessage });
        const formattedHistory = await conversation_manager_1.ConversationManager.getFormattedHistory(id, userId);
        const systemPrompt = (0, prompts_1.getSystemPromptForTone)(tone);

        let userContextStr = '';
        if (userContext) {
            userContextStr = `\nSEU PERFIL\n`;
            if (userContext.name) userContextStr += `Nome: ${userContext.name}\n`;
            if (userContext.age) userContextStr += `Idade: ${userContext.age}\n`;
            if (userContext.interests?.length > 0) userContextStr += `Interesses: ${userContext.interests.join(', ')}\n`;
            if (userContext.dislikes?.length > 0) userContextStr += `EVITE mencionar: ${userContext.dislikes.join(', ')}\n`;
            if (userContext.humorStyle) userContextStr += `Estilo de humor: ${userContext.humorStyle}\n`;
            if (userContext.relationshipGoal) userContextStr += `Objetivo: ${userContext.relationshipGoal}\n`;
        }

        const fullPrompt = `${systemPrompt}\n\n${formattedHistory}\n${userContextStr}\nA mensagem mais recente:\n"${receivedMessage}"\n\nGere APENAS 3 sugestoes de resposta.`;
        const response = await (0, anthropic_1.analyzeMessage)({ text: fullPrompt, tone });
        return reply.code(200).send({ suggestions: response });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gerar sugestoes', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.patch('/conversations/:id/tone', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { tone } = request.body;
        await conversation_manager_1.ConversationManager.updateTone(id, userId, tone);
        return reply.code(200).send({ success: true });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao atualizar tom', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.delete('/conversations/:id', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const deleted = await conversation_manager_1.ConversationManager.deleteConversation(id, userId);
        if (!deleted) return reply.code(404).send({ error: 'Conversa nao encontrada' });
        return reply.code(200).send({ success: true });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao deletar conversa', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/conversations/:id/feedback', { preHandler: auth_1.verifyAuth }, async (request, reply) => {
    try {
        const { id } = request.params;
        const userId = request.user.uid;
        const { messageId, gotResponse, responseQuality } = request.body;
        await conversation_manager_1.ConversationManager.submitMessageFeedback(id, userId, messageId, gotResponse, responseQuality);
        return reply.code(200).send({ success: true });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao submeter feedback', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

// ===================================================================
// STRIPE ENDPOINTS
// ===================================================================

fastify.post('/create-checkout-session', { preHandler: auth_1.verifyAuthOnly }, async (request, reply) => {
    try {
        const { priceId, plan } = request.body;
        const user = request.user;
        if (!user.email) return reply.code(400).send({ error: 'Email not found' });
        const session = await (0, stripe_1.createCheckoutSession)({ priceId, plan, userId: user.uid, userEmail: user.email });
        return reply.code(200).send({ url: session.url, sessionId: session.id });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Failed to create checkout session', message: error instanceof Error ? error.message : 'Unknown error' });
    }
});

fastify.post('/webhook/stripe', async (request, reply) => {
    const sig = request.headers['stripe-signature'];
    if (!sig) return reply.code(400).send({ error: 'Missing signature' });
    let event;
    try {
        const rawBody = request.rawBody;
        event = (0, stripe_1.constructWebhookEvent)(rawBody, sig);
    } catch (err) {
        return reply.code(400).send({ error: `Webhook Error: ${err.message}` });
    }
    console.log('Stripe webhook received:', event.type);
    try {
        switch (event.type) {
            case 'checkout.session.completed': await (0, stripe_1.handleCheckoutCompleted)(event.data.object); break;
            case 'customer.subscription.updated': await (0, stripe_1.handleSubscriptionUpdated)(event.data.object); break;
            case 'customer.subscription.deleted': await (0, stripe_1.handleSubscriptionDeleted)(event.data.object); break;
            case 'invoice.paid': await (0, stripe_1.handleInvoicePaid)(event.data.object); break;
            case 'invoice.payment_failed': await (0, stripe_1.handlePaymentFailed)(event.data.object); break;
            default: console.log(`Unhandled event type: ${event.type}`);
        }
        return reply.code(200).send({ received: true });
    } catch (error) {
        console.error('Error processing webhook:', error);
        return reply.code(500).send({ error: 'Internal server error', message: error.message });
    }
});

// ===================================================================
// KEYBOARD EXTENSION ENDPOINTS
// ===================================================================

fastify.get('/keyboard/context', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const userId = request.user.uid;

        const [profilesResult, convsResult, selectedContactsResult] = await Promise.all([
            supabaseAdmin.from('profiles').select('*').eq('user_id', userId).order('updated_at', { ascending: false }).limit(20),
            supabaseAdmin.from('conversations').select('*').eq('user_id', userId).eq('status', 'active'),
            supabaseAdmin.from('selected_contacts').select('external_id, display_name').eq('user_id', userId).eq('provider', 'whatsapp').eq('is_active', true),
        ]);

        // Build threadId map: display_name → threadId (via selected_contacts → threads)
        const threadIdMap = {};
        const selectedContacts = selectedContactsResult.data || [];
        if (selectedContacts.length > 0) {
            const externalIds = selectedContacts.map(c => c.external_id);
            const { data: threads } = await supabaseAdmin
                .from('threads')
                .select('id, external_thread_id')
                .eq('user_id', userId)
                .eq('provider', 'whatsapp')
                .in('external_thread_id', externalIds);
            if (threads) {
                const threadByExtId = {};
                threads.forEach(t => { threadByExtId[t.external_thread_id] = t.id; });
                selectedContacts.forEach(c => {
                    if (c.display_name && threadByExtId[c.external_id]) {
                        threadIdMap[c.display_name.toLowerCase()] = threadByExtId[c.external_id];
                    }
                });
            }
        }

        const profiles = profilesResult.data || [];
        const convs = convsResult.data || [];

        const photoMap = {};
        const profileIdMap = {};
        profiles.forEach(p => {
            const key = (p.name || '').toLowerCase();
            photoMap[key] = p.face_image_base64 || null;
            profileIdMap[key] = p.id;
        });

        const seenKeys = new Set();
        const entries = [];

        const sortedConvs = convs.sort((a, b) => new Date(b.last_message_at || 0) - new Date(a.last_message_at || 0));

        for (const conv of sortedConvs) {
            const matchName = conv.avatar?.matchName || conv.avatar?.name || 'Desconhecida';
            const platform = conv.avatar?.platform || 'tinder';
            const key = `${matchName.toLowerCase()}_${platform}`;
            if (seenKeys.has(key)) continue;
            seenKeys.add(key);
            const nameKey = matchName.toLowerCase();
            entries.push({
                conversationId: conv.id,
                profileId: profileIdMap[nameKey] || null,
                matchName, platform,
                faceImageBase64: photoMap[nameKey] || null,
                threadId: threadIdMap[nameKey] || null,
            });
        }

        profiles.forEach(p => {
            const name = p.name || 'Sem nome';
            const platforms = p.platforms || {};
            const firstPlatformKey = Object.keys(platforms)[0];
            const platform = firstPlatformKey ? (platforms[firstPlatformKey].type || firstPlatformKey) : 'instagram';
            const key = `${name.toLowerCase()}_${platform}`;
            if (!seenKeys.has(key)) {
                seenKeys.add(key);
                entries.push({
                    conversationId: null,
                    profileId: p.id,
                    matchName: name, platform,
                    faceImageBase64: p.face_image_base64 || null,
                    threadId: threadIdMap[name.toLowerCase()] || null,
                });
            }
        });

        return reply.code(200).send({ conversations: entries });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao buscar contexto do teclado', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/keyboard/send-message', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const { conversationId, profileId, content, wasAiSuggestion, tone, objective } = request.body;
        if (!content) return reply.code(400).send({ error: 'Missing required fields', message: 'content is required' });
        if (!conversationId && !profileId) return reply.code(400).send({ error: 'Missing required fields', message: 'conversationId or profileId is required' });

        let activeConversationId = conversationId;

        if (!activeConversationId && profileId) {
            const { data: existingConv } = await supabaseAdmin
                .from('conversations')
                .select('id')
                .eq('user_id', userId).eq('profile_id', profileId).eq('status', 'active')
                .limit(1).single();

            if (existingConv) {
                activeConversationId = existingConv.id;
            } else {
                const { data: profileData } = await supabaseAdmin.from('profiles').select('*').eq('id', profileId).single();
                if (!profileData || profileData.user_id !== userId) return reply.code(404).send({ error: 'Perfil nao encontrado' });

                const platforms = profileData.platforms || {};
                const firstPlatformKey = Object.keys(platforms)[0];
                const platformData = firstPlatformKey ? platforms[firstPlatformKey] : {};
                const platform = platformData.type || firstPlatformKey || 'tinder';
                const newId = require('crypto').randomUUID();

                await supabaseAdmin.from('conversations').insert({
                    id: newId,
                    user_id: userId,
                    profile_id: profileId,
                    status: 'active',
                    avatar: {
                        matchName: profileData.name || 'Desconhecida',
                        platform,
                        bio: platformData.bio || '',
                        photoDescriptions: platformData.photoDescriptions || [],
                        age: platformData.age || null,
                        analytics: { totalMessages: 0, aiSuggestionsUsed: 0, customMessagesUsed: 0 },
                    },
                    messages: [],
                    current_tone: tone || 'casual',
                    created_at: new Date().toISOString(),
                    last_message_at: new Date().toISOString(),
                });
                activeConversationId = newId;
            }
        }

        const { data: convData } = await supabaseAdmin.from('conversations').select('*').eq('id', activeConversationId).single();
        if (!convData || convData.user_id !== userId) return reply.code(404).send({ error: 'Conversa nao encontrada' });

        const message = {
            id: `kb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            role: 'user', content,
            timestamp: new Date().toISOString(),
            wasAiSuggestion: wasAiSuggestion || false,
            tone: tone || null, objective: objective || null,
            source: 'keyboard',
        };

        const messages = [...(convData.messages || []), message];
        const avatar = convData.avatar || {};
        const analytics = avatar.analytics || { totalMessages: 0, aiSuggestionsUsed: 0, customMessagesUsed: 0 };
        analytics.totalMessages = (analytics.totalMessages || 0) + 1;
        if (wasAiSuggestion) analytics.aiSuggestionsUsed = (analytics.aiSuggestionsUsed || 0) + 1;
        else analytics.customMessagesUsed = (analytics.customMessagesUsed || 0) + 1;
        avatar.analytics = analytics;

        await supabaseAdmin.from('conversations').update({
            messages, avatar,
            last_message_at: new Date().toISOString(),
        }).eq('id', activeConversationId);

        if (convData.profile_id) {
            try {
                await supabaseAdmin.from('profiles').update({
                    last_activity_at: new Date().toISOString(),
                    last_message_preview: content.substring(0, 80),
                    updated_at: new Date().toISOString(),
                }).eq('id', convData.profile_id);
            } catch (e) { }
        }

        return reply.code(200).send({ success: true, messageId: message.id });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao salvar mensagem', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/keyboard/start-conversation', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const { conversationId, profileId, objective, tone, language } = request.body;
        if (!objective || !tone) return reply.code(400).send({ error: 'Missing required fields' });

        let matchName = '', matchBio = '', platform = 'tinder', photoDescription = '', specificDetail = '';

        if (conversationId) {
            const { data: convDoc } = await supabaseAdmin.from('conversations').select('*').eq('id', conversationId).single();
            if (convDoc && convDoc.user_id === userId) {
                const avatar = convDoc.avatar || {};
                matchName = avatar.matchName || '';
                matchBio = avatar.bio || '';
                platform = avatar.platform || 'tinder';
                photoDescription = avatar.photoDescriptions || '';
                const messages = convDoc.messages || [];
                if (messages.length > 0) specificDetail = `Ja trocaram ${messages.length} mensagens anteriormente.`;
            }
        }

        if (!matchName && profileId) {
            const { data: profileDoc } = await supabaseAdmin.from('profiles').select('*').eq('id', profileId).single();
            if (profileDoc && profileDoc.user_id === userId) {
                matchName = profileDoc.name || '';
                const platforms = profileDoc.platforms || {};
                const firstKey = Object.keys(platforms)[0];
                if (firstKey) {
                    matchBio = platforms[firstKey].bio || '';
                    platform = platforms[firstKey].type || firstKey || 'tinder';
                    if (platforms[firstKey].photoDescriptions?.length > 0) {
                        photoDescription = platforms[firstKey].photoDescriptions.join('. ');
                    }
                }
            }
        }

        const objectiveInstruction = (0, prompts_1.getObjectivePrompt)(objective);
        const enrichedInput = {
            matchName: matchName || 'Match', matchBio: matchBio || '', platform, tone, photoDescription,
            specificDetail: specificDetail ? `${specificDetail}\n\n${objectiveInstruction}` : objectiveInstruction,
        };
        const agent = new agents_1.FirstMessageAgent();
        if (language) agent.setLanguage(language);
        const result = await agent.execute(enrichedInput);
        return reply.code(200).send({ analysis: result });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gerar primeira mensagem', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

fastify.post('/keyboard/analyze-screenshot', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const { imageBase64, imageMediaType, conversationId, objective, tone, language } = request.body;
        if (!imageBase64) return reply.code(400).send({ error: 'Missing required fields', message: 'imageBase64 is required' });

        const imageAgent = new agents_1.ConversationImageAnalyzerAgent();
        const extractedData = await imageAgent.analyzeAndExtract({ imageBase64, imageMediaType: imageMediaType || 'image/jpeg' });

        if (!extractedData || !extractedData.lastMessage) {
            return reply.code(200).send({ analysis: 'Nao foi possivel extrair mensagens da imagem.', extractedMessages: [], mode: 'screenshot' });
        }

        let convContext = '';
        if (conversationId) {
            try {
                const { data: convDoc } = await supabaseAdmin.from('conversations').select('*').eq('id', conversationId).single();
                if (convDoc && convDoc.user_id === userId) {
                    const avatar = convDoc.avatar || {};
                    const messages = convDoc.messages || [];
                    if (messages.length > 0) {
                        const recent = messages.slice(-15);
                        convContext = 'Historico salvo:\n' + recent.map(m => {
                            const role = m.role === 'user' ? 'Voce' : (avatar.matchName || 'Match');
                            return `${role}: ${m.content}`;
                        }).join('\n');
                    }

                    // Deduplicate & save screenshot messages
                    if (extractedData.conversationContext && messages.length > 0) {
                        const existingContents = messages.map(m => m.content.toLowerCase().trim());
                        extractedData.conversationContext = extractedData.conversationContext.filter(msg => {
                            const normalized = msg.toLowerCase().trim();
                            return !existingContents.some(existing => {
                                const shorter = Math.min(existing.length, normalized.length);
                                const longer = Math.max(existing.length, normalized.length);
                                if (shorter === 0) return false;
                                let matches = 0;
                                for (let i = 0; i < shorter; i++) { if (existing[i] === normalized[i]) matches++; }
                                return (matches / longer) > 0.8;
                            });
                        });
                    }

                    const screenshotMessages = [];
                    if (extractedData.conversationContext) {
                        for (const msg of extractedData.conversationContext) {
                            screenshotMessages.push({
                                id: `kb_screenshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                                role: 'match', content: msg,
                                timestamp: new Date().toISOString(), source: 'keyboard_screenshot',
                            });
                        }
                    }
                    if (extractedData.lastMessage) {
                        screenshotMessages.push({
                            id: `kb_screenshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                            role: extractedData.lastMessageSender === 'user' ? 'user' : 'match',
                            content: extractedData.lastMessage,
                            timestamp: new Date().toISOString(), source: 'keyboard_screenshot',
                        });
                    }
                    if (screenshotMessages.length > 0) {
                        const updatedMessages = [...messages, ...screenshotMessages];
                        await supabaseAdmin.from('conversations').update({
                            messages: updatedMessages,
                            last_message_at: new Date().toISOString(),
                        }).eq('id', conversationId);
                    }
                }
            } catch (err) { fastify.log.warn('Failed to process conversation context for screenshot:', err); }
        }

        let screenshotContext = '';
        if (extractedData.conversationContext?.length > 0) {
            screenshotContext = 'Mensagens do screenshot:\n' + extractedData.conversationContext.join('\n');
        }
        const objectiveInstruction = (0, prompts_1.getObjectivePrompt)(objective || 'automatico');
        const richPrompt = `Voce esta ajudando a responder mensagens de dating.
${convContext ? convContext + '\n\n' : ''}${screenshotContext ? screenshotContext + '\n\n' : ''}A ultima mensagem ${extractedData.lastMessageSender === 'user' ? 'foi sua' : 'foi dela'}:
"${extractedData.lastMessage}"

${objectiveInstruction}

Gere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).`;

        const analysis = await (0, anthropic_1.analyzeMessage)({ text: richPrompt, tone: tone || 'automatico', language });
        return reply.code(200).send({ analysis, extractedMessages: extractedData.conversationContext || [], mode: 'screenshot' });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao analisar screenshot', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

// ===================================================================
// SYNC: Proxy to Baileys server (WhatsApp sync for app)
// ===================================================================

const http = require('http');

function proxyToBaileys(method, path, userId, body) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: process.env.BAILEYS_HOST || 'baileys',
            port: parseInt(process.env.BAILEYS_PORT || '3040'),
            path,
            method,
            headers: {
                'x-user-id': userId,
                'Content-Type': 'application/json',
            },
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, data: JSON.parse(data) });
                } catch {
                    resolve({ status: res.statusCode, data: data });
                }
            });
        });

        req.on('error', (err) => reject(err));
        req.setTimeout(15000, () => { req.destroy(); reject(new Error('Baileys proxy timeout')); });

        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

// POST /sync/instance/create — Create Baileys instance + get QR
fastify.post('/sync/instance/create', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('POST', '/api/evolution/instance/create', request.user.uid, {});
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// GET /sync/instance/qr — Get QR code
fastify.get('/sync/instance/qr', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('GET', '/api/evolution/instance/qr', request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// GET /sync/instance/status — Get connection status
fastify.get('/sync/instance/status', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('GET', '/api/evolution/instance/status', request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// DELETE /sync/instance — Disconnect
fastify.delete('/sync/instance', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('DELETE', '/api/evolution/instance', request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// GET /sync/contacts — List selected contacts
fastify.get('/sync/contacts', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('GET', '/api/contacts', request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// POST /sync/contacts — Add contact
fastify.post('/sync/contacts', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('POST', '/api/contacts', request.user.uid, request.body);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// DELETE /sync/contacts/:id — Remove contact
fastify.delete('/sync/contacts/:id', { preHandler: [auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const result = await proxyToBaileys('DELETE', `/api/contacts/${request.params.id}`, request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// GET /sync/contacts/search — Search WhatsApp contacts
fastify.get('/sync/contacts/search', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const q = request.query.q || '';
        const result = await proxyToBaileys('GET', `/api/evolution/contacts/search?q=${encodeURIComponent(q)}`, request.user.uid);
        return reply.code(result.status).send(result.data);
    } catch (error) {
        fastify.log.error(error);
        return reply.code(502).send({ error: 'Sync server unavailable' });
    }
});

// ===================================================================
// KEYBOARD: POLL MESSAGES (Baileys real-time loop)
// ===================================================================

fastify.get('/keyboard/poll-messages', { preHandler: [verifyRequestSignature, auth_1.verifyAuth] }, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const { matchName, since, threadId } = request.query;

        if (!matchName || !since) {
            return reply.code(400).send({ error: 'matchName and since are required' });
        }

        let resolvedThreadId = threadId || null;

        // If no threadId provided, resolve via selected_contacts → threads
        if (!resolvedThreadId) {
            // Find selected contact by display_name (case-insensitive)
            const { data: contacts } = await supabaseAdmin
                .from('selected_contacts')
                .select('external_id, display_name')
                .eq('user_id', userId)
                .eq('provider', 'whatsapp')
                .eq('is_active', true);

            if (contacts && contacts.length > 0) {
                const matchLower = matchName.toLowerCase();
                const contact = contacts.find(c =>
                    c.display_name && c.display_name.toLowerCase() === matchLower
                ) || contacts.find(c =>
                    c.display_name && c.display_name.toLowerCase().includes(matchLower)
                ) || contacts.find(c =>
                    matchLower.includes((c.display_name || '').toLowerCase())
                );

                if (contact) {
                    const { data: thread } = await supabaseAdmin
                        .from('threads')
                        .select('id')
                        .eq('user_id', userId)
                        .eq('provider', 'whatsapp')
                        .eq('external_thread_id', contact.external_id)
                        .single();

                    if (thread) {
                        resolvedThreadId = thread.id;
                    }
                }
            }
        }

        if (!resolvedThreadId) {
            return reply.code(200).send({ messages: [], threadId: null, latestTs: null });
        }

        // Query new inbound messages since timestamp
        const { data: messages, error: msgErr } = await supabaseAdmin
            .from('messages')
            .select('id, text, ts, direction')
            .eq('thread_id', resolvedThreadId)
            .eq('direction', 'inbound')
            .gt('ts', since)
            .order('ts', { ascending: true })
            .limit(10);

        if (msgErr) {
            fastify.log.error('poll-messages query error:', msgErr);
            return reply.code(500).send({ error: 'Database error' });
        }

        const latestTs = messages && messages.length > 0
            ? messages[messages.length - 1].ts
            : null;

        return reply.code(200).send({
            messages: (messages || []).map(m => ({ text: m.text, ts: m.ts })),
            threadId: resolvedThreadId,
            latestTs,
        });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Erro ao buscar mensagens', message: error instanceof Error ? error.message : 'Erro desconhecido' });
    }
});

// ===================================================================
// APPLE IN-APP PURCHASE
// ===================================================================

fastify.post('/apple/activate-subscription', { preHandler: auth_1.verifyAuthOnly }, async (request, reply) => {
    try {
        const { productId, transactionId, plan } = request.body;
        const user = request.user;
        if (!productId || !transactionId || !plan) return reply.code(400).send({ error: 'Missing required fields' });

        const now = new Date();
        let expiresAt;
        switch (plan) {
            case 'monthly': expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); break;
            case 'quarterly': expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000); break;
            case 'yearly': expiresAt = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000); break;
            default: expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        }

        await supabaseAdmin.from('users').upsert({
            id: user.uid,
            email: user.email,
            subscription_status: 'active',
            subscription_plan: plan,
            subscription_provider: 'apple',
            apple_product_id: productId,
            apple_transaction_id: transactionId,
            subscription_expires_at: expiresAt.toISOString(),
            subscription_started_at: now.toISOString(),
            updated_at: now.toISOString(),
        });

        console.log('Apple subscription activated:', { plan, expiresAt });
        return reply.code(200).send({ success: true, plan, expiresAt: expiresAt.toISOString() });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Failed to activate subscription', message: error instanceof Error ? error.message : 'Unknown error' });
    }
});

// ===================================================================
// GDPR: DELETE ACCOUNT
// ===================================================================

fastify.delete('/user/account', { preHandler: [auth_1.verifyAuthOnly] }, async (request, reply) => {
    try {
        const userId = request.user.uid;

        // Delete user data
        await Promise.all([
            supabaseAdmin.from('users').delete().eq('id', userId),
            supabaseAdmin.from('profiles').delete().eq('user_id', userId),
            supabaseAdmin.from('analytics').delete().eq('user_id', userId),
            supabaseAdmin.from('conversations').delete().eq('user_id', userId),
            supabaseAdmin.from('training_feedback').delete().eq('user_id', userId),
        ]);

        // Delete Supabase Auth user
        await supabaseAdmin.auth.admin.deleteUser(userId);

        return reply.code(200).send({ success: true, message: 'Account and all data deleted' });
    } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ error: 'Failed to delete account', message: error instanceof Error ? error.message : 'Unknown error' });
    }
});

// ===================================================================
// ERROR TRACKING
// ===================================================================

fastify.post('/errors', async (request, reply) => {
    try {
        const { source, error_code, message, context, user_id, app_version, os_version, device } = request.body || {};
        if (!source || !message) {
            return reply.code(400).send({ error: 'source and message are required' });
        }

        await supabaseAdmin.from('error_logs').insert({
            source,
            error_code: error_code || null,
            message: message.substring(0, 2000),
            context: context || null,
            user_id: user_id || null,
            app_version: app_version || null,
            os_version: os_version || null,
            device: device || null,
        });

        return reply.code(200).send({ ok: true });
    } catch (error) {
        fastify.log.error('Error tracking failed:', error);
        return reply.code(500).send({ error: 'Failed to log error' });
    }
});

// ===================================================================
// CRON: CHECK EXPIRED SUBSCRIPTIONS
// ===================================================================

async function checkExpiredSubscriptions() {
    try {
        const now = new Date().toISOString();
        const { data: expired } = await supabaseAdmin
            .from('users')
            .select('id')
            .eq('subscription_status', 'active')
            .lt('subscription_expires_at', now);

        if (!expired || expired.length === 0) {
            console.log('Subscription check: no expired subscriptions found');
            return;
        }

        for (const user of expired) {
            await supabaseAdmin.from('users').update({ subscription_status: 'expired', updated_at: now }).eq('id', user.id);
        }
        console.log(`Subscription check: marked ${expired.length} subscriptions as expired`);
    } catch (error) {
        console.error('Subscription check failed:', error.message || error);
    }
}

const start = async () => {
    try {
        await fastify.listen({ port: env_1.env.PORT, host: '0.0.0.0' });
        console.log(`Servidor rodando na porta ${env_1.env.PORT}`);
        checkExpiredSubscriptions();
        setInterval(checkExpiredSubscriptions, 24 * 60 * 60 * 1000);
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();

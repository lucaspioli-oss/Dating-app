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
                enum: ['automatico', 'engraçado', 'ousado', 'romântico', 'casual', 'confiante', 'expert'],
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
        },
    },
};
fastify.post('/analyze', { schema: analyzeSchema }, async (request, reply) => {
    try {
        const { text, tone, conversationId, objective } = request.body;
        // PRO MODE: If conversationId is provided, use rich context pipeline
        if (conversationId) {
            try {
                const admin = require('firebase-admin');
                const db = admin.firestore();
                // Get auth token from header if present
                let userId = null;
                const authHeader = request.headers.authorization;
                if (authHeader && authHeader.startsWith('Bearer ')) {
                    try {
                        const token = authHeader.split(' ')[1];
                        const decoded = await admin.auth().verifyIdToken(token);
                        userId = decoded.uid;
                    }
                    catch (e) {
                        // Token invalid, continue without auth
                    }
                }
                if (userId) {
                    const convRef = db.collection('conversations').doc(conversationId);
                    const convDoc = await convRef.get();
                    if (convDoc.exists && convDoc.data().userId === userId) {
                        const convData = convDoc.data();
                        // Save clipboard text as match's message
                        const matchMessage = {
                            id: `kb_match_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                            role: 'match',
                            content: text,
                            timestamp: new Date().toISOString(),
                            source: 'keyboard_clipboard',
                        };
                        await convRef.update({
                            messages: admin.firestore.FieldValue.arrayUnion(matchMessage),
                            lastMessageAt: admin.firestore.Timestamp.now(),
                        });
                        // Get updated conversation with full context
                        const updatedDoc = await convRef.get();
                        const data = updatedDoc.data();
                        const messages = data.messages || [];
                        const avatar = data.avatar || {};
                        // Build rich context prompt
                        let historyStr = '';
                        const recentMessages = messages.slice(-20);
                        for (const msg of recentMessages) {
                            const role = msg.role === 'user' ? 'Você' : (avatar.matchName || 'Match');
                            historyStr += `${role}: ${msg.content}\n`;
                        }
                        // Get collective insights if available
                        let collectiveStr = '';
                        if (data.collectiveAvatarId) {
                            const avatarDoc = await db.collection('collectiveAvatars').doc(data.collectiveAvatarId).get();
                            if (avatarDoc.exists) {
                                const ci = avatarDoc.data().collectiveInsights || {};
                                if (ci.whatWorks && ci.whatWorks.length > 0) {
                                    collectiveStr = `\nO que funciona com essa pessoa: ${ci.whatWorks.join(', ')}`;
                                }
                                if (ci.whatDoesntWork && ci.whatDoesntWork.length > 0) {
                                    collectiveStr += `\nO que NÃO funciona: ${ci.whatDoesntWork.join(', ')}`;
                                }
                            }
                        }
                        // Build calibration info
                        let calibrationStr = '';
                        const patterns = avatar.detectedPatterns || {};
                        if (patterns.responseLength) {
                            calibrationStr += `\nTamanho de resposta dela: ${patterns.responseLength}`;
                        }
                        if (patterns.emotionalTone) {
                            calibrationStr += `\nTom emocional: ${patterns.emotionalTone}`;
                        }
                        if (patterns.flirtLevel) {
                            calibrationStr += `\nNível de flerte: ${patterns.flirtLevel}`;
                        }
                        const objectiveInstruction = (0, prompts_1.getObjectivePrompt)(objective || 'automatico');
                        const richPrompt = `Você está ajudando a responder mensagens de dating.
Perfil da match: ${avatar.matchName || 'Desconhecida'} (${avatar.platform || 'dating app'})
${avatar.bio ? `Bio: ${avatar.bio}` : ''}
${calibrationStr}
${collectiveStr}

${objectiveInstruction}

Histórico recente:
${historyStr}

A última mensagem dela foi:
"${text}"

Gere APENAS 3 sugestões de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).
Calibre com base no histórico, tom detectado, e OBJETIVO definido acima.`;
                        const analysis = await (0, anthropic_1.analyzeMessage)({ text: richPrompt, tone });
                        return reply.code(200).send({ analysis, mode: 'pro' });
                    }
                }
            }
            catch (proError) {
                fastify.log.error('PRO mode error, falling back to BASIC:', proError);
                // Fall through to BASIC mode
            }
        }
        // BASIC MODE: Simple analysis without context
        const basicObjective = (0, prompts_1.getObjectivePrompt)(objective || 'automatico');
        const textWithObjective = `${basicObjective}\n\nMensagem recebida:\n"${text}"\n\nGere APENAS 3 sugestões de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).`;
        const analysis = await (0, anthropic_1.analyzeMessage)({ text: textWithObjective, tone });
        const response = {
            analysis,
            mode: 'basic',
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
// ═══════════════════════════════════════════════════════════════════
// ⌨️ KEYBOARD EXTENSION ENDPOINTS
// ═══════════════════════════════════════════════════════════════════
// Get keyboard context - returns profiles with photos and linked conversations
fastify.get('/keyboard/context', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const admin = require('firebase-admin');
        const db = admin.firestore();
        // Get profiles (unique per person, have photos)
        const profilesSnapshot = await db.collection('profiles')
            .where('userId', '==', userId)
            .orderBy('updatedAt', 'desc')
            .limit(15)
            .get();
        // Get active conversations to link with profiles
        const convsSnapshot = await db.collection('conversations')
            .where('userId', '==', userId)
            .where('status', '==', 'active')
            .get();
        // Build a map: matchName+platform -> conversationId
        const convMap = {};
        convsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            const key = `${(data.avatar?.matchName || '').toLowerCase()}_${data.avatar?.platform || ''}`;
            // Keep the most recent conversation for each match
            if (!convMap[key] || (data.lastMessageAt?.toDate?.() > convMap[key].lastMessageAt)) {
                convMap[key] = {
                    conversationId: doc.id,
                    lastMessageAt: data.lastMessageAt?.toDate?.() || new Date(0),
                };
            }
        });
        const conversations = profilesSnapshot.docs.map(doc => {
            const data = doc.data();
            const platforms = data.platforms || {};
            const firstPlatformKey = Object.keys(platforms)[0];
            const firstPlatform = firstPlatformKey ? platforms[firstPlatformKey] : {};
            // Find linked conversation
            const key = `${(data.name || '').toLowerCase()}_${firstPlatform.type || firstPlatformKey || ''}`;
            const linked = convMap[key] || null;
            return {
                conversationId: linked?.conversationId || null,
                profileId: doc.id,
                matchName: data.name || 'Sem nome',
                platform: firstPlatform.type || firstPlatformKey || 'instagram',
                faceImageBase64: data.faceImageBase64 || null,
            };
        });
        return reply.code(200).send({ conversations });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao buscar contexto do teclado',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// Save message sent via keyboard extension
fastify.post('/keyboard/send-message', {
    preHandler: auth_1.verifyAuth,
}, async (request, reply) => {
    try {
        const userId = request.user.uid;
        const { conversationId, content, wasAiSuggestion, tone, objective } = request.body;
        if (!conversationId || !content) {
            return reply.code(400).send({
                error: 'Missing required fields',
                message: 'conversationId and content are required',
            });
        }
        const admin = require('firebase-admin');
        const db = admin.firestore();
        // Verify conversation belongs to user
        const convRef = db.collection('conversations').doc(conversationId);
        const convDoc = await convRef.get();
        if (!convDoc.exists || convDoc.data().userId !== userId) {
            return reply.code(404).send({ error: 'Conversa não encontrada' });
        }
        // Add message to conversation
        const message = {
            id: `kb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            role: 'user',
            content,
            timestamp: new Date().toISOString(),
            wasAiSuggestion: wasAiSuggestion || false,
            tone: tone || null,
            objective: objective || null,
            source: 'keyboard',
        };
        await convRef.update({
            messages: admin.firestore.FieldValue.arrayUnion(message),
            lastMessageAt: admin.firestore.Timestamp.now(),
        });
        // Update analytics
        const analyticsField = wasAiSuggestion
            ? 'avatar.analytics.aiSuggestionsUsed'
            : 'avatar.analytics.customMessagesUsed';
        await convRef.update({
            [analyticsField]: admin.firestore.FieldValue.increment(1),
            'avatar.analytics.totalMessages': admin.firestore.FieldValue.increment(1),
        });
        // Update profile's lastActivityAt for sorting in profiles list
        const convData = convDoc.data();
        const profileId = convData.profileId;
        if (profileId) {
            try {
                await db.collection('profiles').doc(profileId).update({
                    lastActivityAt: admin.firestore.Timestamp.now(),
                    lastMessagePreview: content.substring(0, 80),
                    updatedAt: admin.firestore.Timestamp.now(),
                });
            }
            catch (profileErr) {
                // Non-critical - profile ordering won't update but message is saved
                fastify.log.warn('Failed to update profile lastActivityAt:', profileErr);
            }
        }
        return reply.code(200).send({ success: true, messageId: message.id });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Erro ao salvar mensagem',
            message: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});
// ═══════════════════════════════════════════════════════════════════
// 🍎 APPLE IN-APP PURCHASE ENDPOINTS
// ═══════════════════════════════════════════════════════════════════
fastify.post('/apple/activate-subscription', {
    preHandler: auth_1.verifyAuthOnly,
}, async (request, reply) => {
    try {
        const { productId, transactionId, plan, verificationData } = request.body;
        const user = request.user;
        if (!productId || !transactionId || !plan) {
            return reply.code(400).send({
                error: 'Missing required fields',
                message: 'productId, transactionId, and plan are required',
            });
        }
        const admin = require('firebase-admin');
        const db = admin.firestore();
        // Calculate expiration based on plan
        const now = new Date();
        let expiresAt;
        switch (plan) {
            case 'monthly':
                expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
                break;
            case 'quarterly':
                expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
                break;
            case 'yearly':
                expiresAt = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
                break;
            default:
                expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        }
        // Update user subscription in Firestore
        await db.collection('users').doc(user.uid).set({
            email: user.email,
            subscription: {
                status: 'active',
                plan,
                provider: 'apple',
                appleProductId: productId,
                appleTransactionId: transactionId,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                startedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
        }, { merge: true });
        console.log(`✅ Apple subscription activated for ${user.email}:`, {
            userId: user.uid,
            plan,
            productId,
            transactionId,
            expiresAt,
        });
        return reply.code(200).send({
            success: true,
            plan,
            expiresAt: expiresAt.toISOString(),
        });
    }
    catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({
            error: 'Failed to activate subscription',
            message: error instanceof Error ? error.message : 'Unknown error',
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

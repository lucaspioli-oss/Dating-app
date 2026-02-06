"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConversationManager = void 0;
const crypto_1 = require("crypto");
const admin = __importStar(require("firebase-admin"));
const collective_avatar_manager_1 = require("./collective-avatar-manager");
// Firestore reference
const getDb = () => admin.firestore();
class ConversationManager {
    /**
     * Criar nova conversa (com vínculo ao avatar coletivo)
     */
    static async createConversation(request) {
        const conversationId = (0, crypto_1.randomUUID)();
        const now = new Date();
        // Encontrar ou criar avatar coletivo
        const collectiveAvatar = await collective_avatar_manager_1.CollectiveAvatarManager.findOrCreateCollectiveAvatar({
            name: request.matchName,
            platform: request.platform,
            bio: request.bio,
            age: request.age,
            location: request.location,
            interests: request.interests,
        });
        const avatar = {
            matchName: request.matchName,
            platform: request.platform,
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
        const messages = [];
        // Se tiver primeira mensagem (opener), adicionar
        if (request.firstMessage) {
            messages.push({
                id: (0, crypto_1.randomUUID)(),
                role: 'user',
                content: request.firstMessage,
                timestamp: now,
                wasAiSuggestion: true,
                tone: request.tone,
            });
        }
        const conversation = {
            id: conversationId,
            userId: request.userId,
            avatar,
            messages,
            currentTone: request.tone || 'casual',
            status: 'active',
            createdAt: now,
            lastMessageAt: now,
        };
        // Salvar no Firestore (incluindo referência ao avatar coletivo)
        await getDb().collection('conversations').doc(conversationId).set({
            ...conversation,
            collectiveAvatarId: collectiveAvatar.id, // Link para inteligência coletiva
            createdAt: admin.firestore.Timestamp.fromDate(now),
            lastMessageAt: admin.firestore.Timestamp.fromDate(now),
        });
        return conversation;
    }
    /**
     * Adicionar mensagem à conversa
     */
    static async addMessage(request) {
        const conversation = await this.getConversation(request.conversationId, request.userId);
        if (!conversation) {
            throw new Error('Conversa não encontrada');
        }
        const message = {
            id: (0, crypto_1.randomUUID)(),
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
            }
            else {
                conversation.avatar.analytics.customMessagesUsed++;
            }
        }
        // Se for mensagem do match, analisar e atualizar calibragem
        if (request.role === 'match') {
            await this.updateCalibration(conversation, request.content);
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
     * Analisar mensagem e atualizar calibragem (local + contribuir para coletivo)
     */
    static async updateCalibration(conversation, message) {
        const avatar = conversation.avatar;
        // Detectar tamanho de resposta
        if (message.length < 50) {
            avatar.detectedPatterns.responseLength = 'short';
        }
        else if (message.length < 150) {
            avatar.detectedPatterns.responseLength = 'medium';
        }
        else {
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
        }
        else if (hasColdKeywords && !hasWarmKeywords) {
            avatar.detectedPatterns.emotionalTone = 'cold';
        }
        else {
            avatar.detectedPatterns.emotionalTone = 'neutral';
        }
        // Detectar nível de flerte (baseado em mensagens enviadas vs recebidas)
        const userMessages = conversation.messages.filter((m) => m.role === 'user').length;
        const matchMessages = conversation.messages.filter((m) => m.role === 'match').length;
        if (matchMessages > userMessages) {
            avatar.detectedPatterns.flirtLevel = 'high';
        }
        else if (matchMessages === userMessages) {
            avatar.detectedPatterns.flirtLevel = 'medium';
        }
        else {
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
        dislikesKeywords.forEach((keyword) => {
            if (lowerMessage.includes(keyword)) {
                const afterKeyword = lowerMessage.split(keyword)[1];
                if (afterKeyword) {
                    const dislike = afterKeyword.split(/[.,!?]/)[0].trim();
                    if (dislike && !avatar.learnedInfo.dislikes?.includes(dislike)) {
                        avatar.learnedInfo.dislikes = [...(avatar.learnedInfo.dislikes || []), dislike];
                    }
                }
            }
        });
        avatar.detectedPatterns.lastUpdated = new Date();
        // Avaliar qualidade da conversa
        if (matchMessages >= 5 && avatar.detectedPatterns.emotionalTone === 'warm') {
            avatar.analytics.conversationQuality = 'excellent';
        }
        else if (matchMessages >= 3) {
            avatar.analytics.conversationQuality = 'good';
        }
        else if (matchMessages >= 1) {
            avatar.analytics.conversationQuality = 'average';
        }
        else {
            avatar.analytics.conversationQuality = 'poor';
        }
    }
    /**
     * Obter conversa por ID (verificando ownership)
     */
    static async getConversation(conversationId, userId) {
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
        };
    }
    /**
     * Listar conversas do usuário
     */
    static async listConversations(userId) {
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
    static async updateTone(conversationId, userId, tone) {
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
    static async deleteConversation(conversationId, userId) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation) {
            return false;
        }
        await getDb().collection('conversations').doc(conversationId).delete();
        return true;
    }
    /**
     * Obter histórico formatado para o prompt da IA
     * Inclui: contexto individual + inteligência coletiva
     */
    static async getFormattedHistory(conversationId, userId) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation)
            return '';
        const { avatar, messages } = conversation;
        // Obter insights coletivos (de múltiplos usuários)
        const collectiveInsights = await collective_avatar_manager_1.CollectiveAvatarManager.getCollectiveInsightsForPrompt(avatar.matchName, avatar.platform);
        let history = '';
        // Se tiver insights coletivos, adicionar primeiro
        if (collectiveInsights) {
            history += collectiveInsights + '\n';
        }
        history += `═══════════════════════════════════════════════════════════════════
📋 CONTEXTO DA SUA CONVERSA ESPECÍFICA
═══════════════════════════════════════════════════════════════════

👤 PERFIL DO MATCH:
Nome: ${avatar.matchName}
Plataforma: ${avatar.platform.toUpperCase()}
${avatar.bio ? `Bio: ${avatar.bio}` : ''}
${avatar.age ? `Idade: ${avatar.age}` : ''}
${avatar.location ? `Localização: ${avatar.location}` : ''}
${avatar.interests && avatar.interests.length > 0 ? `Interesses: ${avatar.interests.join(', ')}` : ''}

📊 CALIBRAGEM DESTA CONVERSA:
- Tamanho de resposta: ${avatar.detectedPatterns.responseLength === 'short' ? 'CURTO (espelhe com respostas curtas!)' : avatar.detectedPatterns.responseLength === 'long' ? 'LONGO (pode investir mais)' : 'MÉDIO'}
- Tom emocional: ${avatar.detectedPatterns.emotionalTone === 'warm' ? '🔥 CALOROSO (ela/ele está receptivo!)' : avatar.detectedPatterns.emotionalTone === 'cold' ? '❄️ FRIO (reduza investimento)' : '😐 NEUTRO'}
- Usa emojis: ${avatar.detectedPatterns.useEmojis ? 'SIM (você pode usar também)' : 'NÃO (evite emojis)'}
- Nível de flerte: ${avatar.detectedPatterns.flirtLevel === 'high' ? '🔥 ALTO (ela/ele está muito interessado!)' : avatar.detectedPatterns.flirtLevel === 'low' ? '❄️ BAIXO (aumente atração gradualmente)' : '😊 MÉDIO'}

💡 INFORMAÇÕES APRENDIDAS NESTA CONVERSA:
${avatar.learnedInfo.hobbies && avatar.learnedInfo.hobbies.length > 0 ? `- Hobbies: ${avatar.learnedInfo.hobbies.join(', ')}` : '- Nenhum hobby descoberto ainda'}
${avatar.learnedInfo.dislikes && avatar.learnedInfo.dislikes.length > 0 ? `- Não gosta de: ${avatar.learnedInfo.dislikes.join(', ')}` : ''}
${avatar.learnedInfo.personality && avatar.learnedInfo.personality.length > 0 ? `- Personalidade: ${avatar.learnedInfo.personality.join(', ')}` : ''}

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

⚠️ INSTRUÇÕES DE CALIBRAGEM:
- ESPELHE o tamanho de resposta detectado (${avatar.detectedPatterns.responseLength})
- ADAPTE ao tom emocional (${avatar.detectedPatterns.emotionalTone})
- MANTENHA a qualidade da conversa (atualmente: ${avatar.analytics.conversationQuality})
${collectiveInsights ? '- USE os insights coletivos para evitar erros que outros cometeram' : ''}
${avatar.learnedInfo.dislikes && avatar.learnedInfo.dislikes.length > 0 ? `- EVITE mencionar: ${avatar.learnedInfo.dislikes.join(', ')}` : ''}
`;
        return history;
    }
    /**
     * Registrar feedback sobre mensagem enviada
     */
    static async submitMessageFeedback(conversationId, userId, messageId, gotResponse, responseQuality) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation) {
            throw new Error('Conversa não encontrada');
        }
        await collective_avatar_manager_1.CollectiveAvatarManager.submitFeedback({
            conversationId,
            messageId,
            gotResponse,
            responseQuality,
        }, conversation);
    }
}
exports.ConversationManager = ConversationManager;

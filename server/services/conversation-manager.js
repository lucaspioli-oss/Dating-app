"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConversationManager = void 0;
const crypto_1 = require("crypto");
const { supabaseAdmin } = require("../config/supabase");
const collective_avatar_manager_1 = require("./collective-avatar-manager");

class ConversationManager {
    /**
     * Criar nova conversa
     */
    static async createConversation(request) {
        const conversationId = (0, crypto_1.randomUUID)();
        const now = new Date().toISOString();

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
            user_id: request.userId,
            avatar,
            messages,
            platform: request.platform,
            current_tone: request.tone || 'casual',
            status: 'active',
            collective_avatar_id: collectiveAvatar.id,
            created_at: now,
            last_message_at: now,
        };

        const { error } = await supabaseAdmin
            .from('conversations')
            .insert(conversation);

        if (error) {
            console.error('Error creating conversation:', error);
            throw new Error('Erro ao criar conversa');
        }

        return {
            id: conversationId,
            userId: request.userId,
            avatar,
            messages,
            currentTone: request.tone || 'casual',
            status: 'active',
            createdAt: now,
            lastMessageAt: now,
        };
    }

    /**
     * Adicionar mensagem a conversa
     */
    static async addMessage(request) {
        const conversation = await this.getConversation(request.conversationId, request.userId);
        if (!conversation) {
            throw new Error('Conversa nao encontrada');
        }

        const message = {
            id: (0, crypto_1.randomUUID)(),
            role: request.role,
            content: request.content,
            timestamp: new Date().toISOString(),
            wasAiSuggestion: request.wasAiSuggestion,
            tone: request.tone,
        };

        conversation.messages.push(message);
        const now = new Date().toISOString();

        // Update analytics
        conversation.avatar.analytics.totalMessages++;
        if (request.role === 'user') {
            if (request.wasAiSuggestion) {
                conversation.avatar.analytics.aiSuggestionsUsed++;
            } else {
                conversation.avatar.analytics.customMessagesUsed++;
            }
        }

        // Calibrate on match messages
        if (request.role === 'match') {
            await this.updateCalibration(conversation, request.content);
        }

        const { error } = await supabaseAdmin
            .from('conversations')
            .update({
                messages: conversation.messages,
                last_message_at: now,
                avatar: conversation.avatar,
            })
            .eq('id', request.conversationId);

        if (error) {
            console.error('Error adding message:', error);
            throw new Error('Erro ao adicionar mensagem');
        }

        conversation.lastMessageAt = now;
        return conversation;
    }

    /**
     * Calibration analysis
     */
    static async updateCalibration(conversation, message) {
        const avatar = conversation.avatar;
        if (message.length < 50) {
            avatar.detectedPatterns.responseLength = 'short';
        } else if (message.length < 150) {
            avatar.detectedPatterns.responseLength = 'medium';
        } else {
            avatar.detectedPatterns.responseLength = 'long';
        }

        const emojiRegex = /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/u;
        avatar.detectedPatterns.useEmojis = emojiRegex.test(message);

        const warmKeywords = ['amor', 'querido', 'fofo', 'lindo', 'amei', 'adorei', 'haha', 'rsrs'];
        const coldKeywords = ['ok', 'sei', 'talvez', 'nao sei', 'depois', 'ocupado', 'ocupada'];
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

        const userMessages = conversation.messages.filter((m) => m.role === 'user').length;
        const matchMessages = conversation.messages.filter((m) => m.role === 'match').length;
        if (matchMessages > userMessages) {
            avatar.detectedPatterns.flirtLevel = 'high';
        } else if (matchMessages === userMessages) {
            avatar.detectedPatterns.flirtLevel = 'medium';
        } else {
            avatar.detectedPatterns.flirtLevel = 'low';
        }

        // Extract learned info
        const hobbiesKeywords = ['gosto de', 'adoro', 'amo', 'curto', 'vicio em'];
        const dislikesKeywords = ['odeio', 'nao gosto', 'detesto', 'nao curto'];
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

        avatar.detectedPatterns.lastUpdated = new Date().toISOString();

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
     * Get conversation by ID (with ownership check)
     */
    static async getConversation(conversationId, userId) {
        const { data, error } = await supabaseAdmin
            .from('conversations')
            .select('*')
            .eq('id', conversationId)
            .single();

        if (error || !data) return null;
        if (data.user_id !== userId) return null;

        return {
            ...data,
            userId: data.user_id,
            currentTone: data.current_tone,
            collectiveAvatarId: data.collective_avatar_id,
            createdAt: data.created_at,
            lastMessageAt: data.last_message_at,
            avatar: data.avatar || {},
            messages: data.messages || [],
        };
    }

    /**
     * List user conversations
     */
    static async listConversations(userId) {
        const { data, error } = await supabaseAdmin
            .from('conversations')
            .select('*')
            .eq('user_id', userId)
            .order('last_message_at', { ascending: false });

        if (error) {
            console.error('Error listing conversations:', error);
            return [];
        }

        return (data || []).map((row) => {
            const messages = row.messages || [];
            return {
                id: row.id,
                matchName: row.avatar?.matchName || 'Sem nome',
                platform: row.avatar?.platform || 'tinder',
                lastMessage: messages.length > 0
                    ? messages[messages.length - 1].content
                    : 'Sem mensagens',
                lastMessageAt: row.last_message_at,
                unreadCount: 0,
                avatar: {
                    emotionalTone: row.avatar?.detectedPatterns?.emotionalTone || 'neutral',
                    flirtLevel: row.avatar?.detectedPatterns?.flirtLevel || 'medium',
                },
            };
        });
    }

    /**
     * Update conversation tone
     */
    static async updateTone(conversationId, userId, tone) {
        const conversation = await this.getConversation(conversationId, userId);
        if (conversation) {
            await supabaseAdmin
                .from('conversations')
                .update({ current_tone: tone })
                .eq('id', conversationId);
        }
    }

    /**
     * Delete conversation
     */
    static async deleteConversation(conversationId, userId) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation) return false;

        const { error } = await supabaseAdmin
            .from('conversations')
            .delete()
            .eq('id', conversationId);

        return !error;
    }

    /**
     * Get formatted history for AI prompt
     */
    static async getFormattedHistory(conversationId, userId) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation) return '';
        const { avatar, messages } = conversation;

        const collectiveInsights = await collective_avatar_manager_1.CollectiveAvatarManager.getCollectiveInsightsForPrompt(avatar.matchName, avatar.platform);
        let history = '';
        if (collectiveInsights) {
            history += collectiveInsights + '\n';
        }

        history += `CONTEXTO DA SUA CONVERSA ESPECIFICA\n\n`;
        history += `PERFIL DO MATCH:\n`;
        history += `Nome: ${avatar.matchName}\n`;
        history += `Plataforma: ${(avatar.platform || '').toUpperCase()}\n`;
        if (avatar.bio) history += `Bio: ${avatar.bio}\n`;
        if (avatar.age) history += `Idade: ${avatar.age}\n`;
        if (avatar.location) history += `Localizacao: ${avatar.location}\n`;
        if (avatar.interests?.length > 0) history += `Interesses: ${avatar.interests.join(', ')}\n`;

        history += `\nCALIBRAGEM DESTA CONVERSA:\n`;
        history += `- Tamanho de resposta: ${avatar.detectedPatterns.responseLength}\n`;
        history += `- Tom emocional: ${avatar.detectedPatterns.emotionalTone}\n`;
        history += `- Usa emojis: ${avatar.detectedPatterns.useEmojis ? 'SIM' : 'NAO'}\n`;
        history += `- Nivel de flerte: ${avatar.detectedPatterns.flirtLevel}\n`;

        history += `\nINFORMACOES APRENDIDAS:\n`;
        if (avatar.learnedInfo?.hobbies?.length > 0) history += `- Hobbies: ${avatar.learnedInfo.hobbies.join(', ')}\n`;
        if (avatar.learnedInfo?.dislikes?.length > 0) history += `- Nao gosta de: ${avatar.learnedInfo.dislikes.join(', ')}\n`;

        history += `\nANALISE DE PERFORMANCE:\n`;
        history += `- Total de mensagens: ${avatar.analytics.totalMessages}\n`;
        history += `- Sugestoes da IA usadas: ${avatar.analytics.aiSuggestionsUsed}\n`;
        history += `- Mensagens customizadas: ${avatar.analytics.customMessagesUsed}\n`;
        history += `- Qualidade da conversa: ${(avatar.analytics.conversationQuality || '').toUpperCase()}\n`;

        history += `\nHISTORICO DA CONVERSA\n\n`;
        messages.forEach((msg, index) => {
            const roleLabel = msg.role === 'user' ? 'VOCE' : (avatar.matchName || '').toUpperCase();
            const suggestionLabel = msg.wasAiSuggestion ? ' [IA]' : '';
            history += `${index + 1}. ${roleLabel}${suggestionLabel}: "${msg.content}"\n`;
        });

        history += `\nINSTRUCOES DE CALIBRAGEM:\n`;
        history += `- ESPELHE o tamanho de resposta detectado (${avatar.detectedPatterns.responseLength})\n`;
        history += `- ADAPTE ao tom emocional (${avatar.detectedPatterns.emotionalTone})\n`;
        history += `- MANTENHA a qualidade da conversa (atualmente: ${avatar.analytics.conversationQuality})\n`;

        return history;
    }

    /**
     * Submit message feedback
     */
    static async submitMessageFeedback(conversationId, userId, messageId, gotResponse, responseQuality) {
        const conversation = await this.getConversation(conversationId, userId);
        if (!conversation) {
            throw new Error('Conversa nao encontrada');
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

"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CollectiveAvatarManager = void 0;
const crypto_1 = require("crypto");
const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));
const env_1 = require("../config/env");
const { supabaseAdmin } = require("../config/supabase");

const anthropic = new sdk_1.default({ apiKey: env_1.env.ANTHROPIC_API_KEY });

class CollectiveAvatarManager {
    static normalizeName(name) {
        return name
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-z0-9]/g, '')
            .trim();
    }

    static generateAvatarId(name, platform) {
        const normalizedName = this.normalizeName(name);
        const normalizedPlatform = platform.toLowerCase();
        return `${normalizedName}_${normalizedPlatform}`;
    }

    static async findOrCreateCollectiveAvatar(request) {
        const avatarId = this.generateAvatarId(request.name, request.platform);

        const { data: existing } = await supabaseAdmin
            .from('collective_avatars')
            .select('*')
            .eq('id', avatarId)
            .single();

        if (existing) {
            await this.mergeAvatarData(avatarId, request);
            return existing;
        }

        const now = new Date().toISOString();
        const newAvatar = {
            id: avatarId,
            normalized_name: this.normalizeName(request.name),
            platform: request.platform,
            profile_data: {
                possibleAges: request.age ? [request.age] : [],
                possibleLocations: request.location ? [request.location] : [],
                possibleBios: request.bio ? [request.bio] : [],
                commonInterests: request.interests || [],
            },
            collective_insights: {
                likes: [],
                dislikes: [],
                behaviorPatterns: [],
                whatWorks: [],
                whatDoesntWork: [],
                openerStats: [],
                personalityTraits: [],
            },
            metrics: {
                totalConversations: 1,
                totalMessages: 0,
                avgConversationLength: 0,
                successRate: 0,
                dateConversionRate: 0,
            },
            confidence_score: 10,
            last_updated: now,
            created_at: now,
        };

        const { error } = await supabaseAdmin
            .from('collective_avatars')
            .insert(newAvatar);

        if (error) console.error('Error creating collective avatar:', error);
        return newAvatar;
    }

    static async mergeAvatarData(avatarId, request) {
        const { data: doc } = await supabaseAdmin
            .from('collective_avatars')
            .select('*')
            .eq('id', avatarId)
            .single();

        if (!doc) return;

        const profileData = doc.profile_data || {};
        const metrics = doc.metrics || {};

        if (request.age && !profileData.possibleAges?.includes(request.age)) {
            profileData.possibleAges = [...(profileData.possibleAges || []), request.age];
        }
        if (request.location && !profileData.possibleLocations?.includes(request.location)) {
            profileData.possibleLocations = [...(profileData.possibleLocations || []), request.location];
        }
        if (request.bio && !profileData.possibleBios?.includes(request.bio)) {
            profileData.possibleBios = [...(profileData.possibleBios || []), request.bio];
        }
        if (request.interests) {
            for (const interest of request.interests) {
                if (!profileData.commonInterests?.includes(interest)) {
                    profileData.commonInterests = [...(profileData.commonInterests || []), interest];
                }
            }
        }

        metrics.totalConversations = (metrics.totalConversations || 0) + 1;

        await supabaseAdmin
            .from('collective_avatars')
            .update({
                profile_data: profileData,
                metrics,
                last_updated: new Date().toISOString(),
            })
            .eq('id', avatarId);
    }

    static async getCollectiveAvatar(avatarId) {
        const { data } = await supabaseAdmin
            .from('collective_avatars')
            .select('*')
            .eq('id', avatarId)
            .single();

        return data || null;
    }

    static async submitFeedback(request, conversation) {
        const avatarId = this.generateAvatarId(conversation.avatar.matchName, conversation.avatar.platform);
        const message = conversation.messages.find((m) => m.id === request.messageId);
        if (!message) return;

        const feedback = {
            id: (0, crypto_1.randomUUID)(),
            collective_avatar_id: avatarId,
            message_type: conversation.messages.length <= 2 ? 'opener' : 'reply',
            tone: message.tone || 'casual',
            message_sent: this.anonymizeMessage(message.content),
            got_response: request.gotResponse,
            response_quality: request.responseQuality,
            created_at: new Date().toISOString(),
        };

        await supabaseAdmin
            .from('message_feedback')
            .insert(feedback);

        await this.updateAvatarFromFeedback(avatarId, feedback);
        await this.checkAndTriggerAnalysis(avatarId);
    }

    static anonymizeMessage(message) {
        let anonymized = message
            .replace(/sou\s+\w+/gi, 'sou [nome]')
            .replace(/meu nome e\s+\w+/gi, 'meu nome e [nome]')
            .replace(/me chamo\s+\w+/gi, 'me chamo [nome]');
        anonymized = anonymized.replace(/\d{2,5}[-.\s]?\d{4,5}[-.\s]?\d{4}/g, '[telefone]');
        anonymized = anonymized.replace(/@\w+/g, '[@usuario]');
        return anonymized;
    }

    static async updateAvatarFromFeedback(avatarId, feedback) {
        const { data: doc } = await supabaseAdmin
            .from('collective_avatars')
            .select('*')
            .eq('id', avatarId)
            .single();

        if (!doc) return;

        const insights = doc.collective_insights || {};
        const metrics = doc.metrics || {};

        // Update opener stats
        if (feedback.message_type === 'opener') {
            const openerStats = insights.openerStats || [];
            const openerType = this.classifyOpener(feedback.message_sent);
            const existingStat = openerStats.find((s) => s.openerType === openerType);

            if (existingStat) {
                existingStat.totalSent++;
                if (feedback.got_response) {
                    existingStat.responseRate = (existingStat.responseRate * (existingStat.totalSent - 1) + 100) / existingStat.totalSent;
                } else {
                    existingStat.responseRate = (existingStat.responseRate * (existingStat.totalSent - 1)) / existingStat.totalSent;
                }
                if (existingStat.examples.length < 5) {
                    existingStat.examples.push({
                        opener: feedback.message_sent,
                        gotResponse: feedback.got_response,
                        responseQuality: feedback.response_quality,
                    });
                }
            } else {
                openerStats.push({
                    openerType,
                    responseRate: feedback.got_response ? 100 : 0,
                    avgResponseQuality: feedback.response_quality || 'neutral',
                    totalSent: 1,
                    examples: [{
                        opener: feedback.message_sent,
                        gotResponse: feedback.got_response,
                        responseQuality: feedback.response_quality,
                    }],
                });
            }
            insights.openerStats = openerStats;
        }

        // Update whatWorks / whatDoesntWork
        if (feedback.got_response && feedback.response_quality === 'warm') {
            const whatWorks = insights.whatWorks || [];
            const strategy = this.extractStrategy(feedback.message_sent, feedback.tone);
            const existing = whatWorks.find((s) => s.strategy === strategy);
            if (existing) {
                existing.successCount++;
                existing.successRate = (existing.successCount / (existing.successCount + existing.failCount)) * 100;
            } else {
                whatWorks.push({ strategy, successCount: 1, failCount: 0, successRate: 100, examples: [feedback.message_sent] });
            }
            insights.whatWorks = whatWorks;
        } else if (!feedback.got_response) {
            const whatDoesntWork = insights.whatDoesntWork || [];
            const strategy = this.extractStrategy(feedback.message_sent, feedback.tone);
            const existing = whatDoesntWork.find((s) => s.strategy === strategy);
            if (existing) {
                existing.failCount++;
            } else {
                whatDoesntWork.push({ strategy, successCount: 0, failCount: 1, successRate: 0, examples: [feedback.message_sent] });
            }
            insights.whatDoesntWork = whatDoesntWork;
        }

        metrics.totalMessages = (metrics.totalMessages || 0) + 1;

        await supabaseAdmin
            .from('collective_avatars')
            .update({
                collective_insights: insights,
                metrics,
                last_updated: new Date().toISOString(),
            })
            .eq('id', avatarId);
    }

    static classifyOpener(opener) {
        const lower = opener.toLowerCase();
        if (lower.match(/^(oi|ola|hey|e ai|eai|opa)\s*$/)) return 'oi_simples';
        if (lower.match(/^(oi|ola|hey).*(tudo bem|como vai|blz)/)) return 'oi_pergunta_generica';
        if (lower.includes('?')) return 'pergunta';
        if (lower.match(/(haha|kk|rs)/)) return 'humor';
        if (lower.includes('bio') || lower.includes('perfil')) return 'referencia_bio';
        if (lower.includes('foto')) return 'referencia_foto';
        if (lower.match(/(linda|lindo|gata|gato|bonita|bonito)/)) return 'elogio_direto';
        if (lower.length > 100) return 'mensagem_longa';
        return 'outro';
    }

    static extractStrategy(message, tone) {
        const lower = message.toLowerCase();
        if (lower.match(/(haha|kk|rs)/)) return `humor_${tone}`;
        if (lower.includes('?')) return `pergunta_${tone}`;
        if (lower.match(/(viagem|viajar|pais|cidade)/)) return 'tema_viagem';
        if (lower.match(/(comida|comer|restaurante|culinaria)/)) return 'tema_comida';
        if (lower.match(/(musica|show|banda|cantor)/)) return 'tema_musica';
        if (lower.match(/(filme|serie|netflix|cinema)/)) return 'tema_entretenimento';
        if (lower.match(/(academia|treino|esporte|correr)/)) return 'tema_fitness';
        return `geral_${tone}`;
    }

    static async checkAndTriggerAnalysis(avatarId) {
        const avatar = await this.getCollectiveAvatar(avatarId);
        if (!avatar) return;

        const lastAnalyzed = avatar.last_analyzed_at ? new Date(avatar.last_analyzed_at) : null;
        const totalMessages = avatar.metrics?.totalMessages || 0;

        const shouldAnalyze = !lastAnalyzed ||
            (new Date().getTime() - lastAnalyzed.getTime() > 24 * 60 * 60 * 1000 && totalMessages > 10);

        if (shouldAnalyze) {
            setImmediate(() => this.performDeepAnalysis(avatarId));
        }
    }

    static async performDeepAnalysis(avatarId) {
        console.log(`Iniciando analise profunda do avatar: ${avatarId}`);
        try {
            const avatar = await this.getCollectiveAvatar(avatarId);
            if (!avatar) return;

            const { data: feedbacks } = await supabaseAdmin
                .from('message_feedback')
                .select('*')
                .eq('collective_avatar_id', avatarId)
                .order('created_at', { ascending: false })
                .limit(50);

            const { data: conversations } = await supabaseAdmin
                .from('conversations')
                .select('*')
                .contains('avatar', { matchName: avatar.normalized_name })
                .order('last_message_at', { ascending: false })
                .limit(20);

            const analysisContext = this.prepareAnalysisContext(avatar, feedbacks || [], conversations || []);

            const response = await anthropic.messages.create({
                model: 'claude-sonnet-4-20250514',
                max_tokens: 2000,
                messages: [{
                    role: 'user',
                    content: `Voce e um analista de padroes de comportamento em conversas de dating apps.\n\nAnalise os dados abaixo e extraia insights sobre esta pessoa (${avatar.normalized_name}).\n\n${analysisContext}\n\nRetorne um JSON com: personalityTraits, likes, dislikes, behaviorPatterns, communicationStyle, bestApproaches, avoidThese.\n\nIMPORTANTE: Base suas conclusoes APENAS nos dados fornecidos. Atribua confidence scores realistas (0-100).`,
                }],
            });

            const content = response.content[0];
            if (content.type !== 'text') return;
            const jsonMatch = content.text.match(/\{[\s\S]*\}/);
            if (!jsonMatch) return;
            const analysis = JSON.parse(jsonMatch[0]);

            await this.updateAvatarWithAnalysis(avatarId, analysis);
            console.log(`Analise profunda concluida para: ${avatarId}`);
        } catch (error) {
            console.error(`Erro na analise profunda: ${error}`);
        }
    }

    static prepareAnalysisContext(avatar, feedbacks, conversations) {
        let context = `PERFIL BASE\nNome: ${avatar.normalized_name}\nPlataforma: ${avatar.platform}\n`;
        context += `Idades reportadas: ${(avatar.profile_data?.possibleAges || []).join(', ') || 'N/A'}\n`;
        context += `Interesses: ${(avatar.profile_data?.commonInterests || []).join(', ') || 'N/A'}\n`;
        context += `Total conversas: ${avatar.metrics?.totalConversations || 0}\n`;

        for (const stat of (avatar.collective_insights?.openerStats || [])) {
            context += `\nOpener ${stat.openerType}: ${stat.responseRate?.toFixed(1)}% resposta\n`;
        }

        for (const feedback of (feedbacks || []).slice(0, 20)) {
            context += `\n[${(feedback.message_type || '').toUpperCase()}] "${feedback.message_sent}" - ${feedback.got_response ? `Respondeu (${feedback.response_quality})` : 'Nao respondeu'}\n`;
        }

        for (const conv of (conversations || []).slice(0, 5)) {
            const messages = conv.messages || [];
            context += `\n--- Conversa ---\n`;
            for (const msg of messages.slice(0, 10)) {
                const role = msg.role === 'user' ? 'USUARIO' : (avatar.normalized_name || '').toUpperCase();
                context += `${role}: "${msg.content}"\n`;
            }
        }

        return context;
    }

    static async updateAvatarWithAnalysis(avatarId, analysis) {
        const updates = {
            last_analyzed_at: new Date().toISOString(),
            last_updated: new Date().toISOString(),
        };

        const { data: current } = await supabaseAdmin
            .from('collective_avatars')
            .select('collective_insights, metrics')
            .eq('id', avatarId)
            .single();

        const insights = current?.collective_insights || {};

        if (analysis.personalityTraits) {
            insights.personalityTraits = analysis.personalityTraits.map((t) => ({
                trait: t.trait, confidence: t.confidence, evidence: t.evidence || [],
            }));
        }
        if (analysis.likes) {
            insights.likes = analysis.likes.map((l) => ({
                content: l.content, confidence: l.confidence, source: l.source || 'inferred',
            }));
        }
        if (analysis.dislikes) {
            insights.dislikes = analysis.dislikes.map((d) => ({
                content: d.content, confidence: d.confidence, source: d.source || 'inferred',
            }));
        }
        if (analysis.behaviorPatterns) {
            insights.behaviorPatterns = analysis.behaviorPatterns.map((p) => ({
                pattern: p.pattern, frequency: p.frequency || 1, confidence: p.confidence,
            }));
        }

        const metrics = current?.metrics || {};
        const baseConfidence = Math.min(100, 10 + (metrics.totalConversations || 0) * 5 + (metrics.totalMessages || 0) * 0.5);

        await supabaseAdmin
            .from('collective_avatars')
            .update({
                ...updates,
                collective_insights: insights,
                confidence_score: baseConfidence,
            })
            .eq('id', avatarId);
    }

    static async getCollectiveInsightsForPrompt(matchName, platform) {
        const avatarId = this.generateAvatarId(matchName, platform);
        const avatar = await this.getCollectiveAvatar(avatarId);

        if (!avatar || (avatar.confidence_score || 0) < 20) return '';

        const ci = avatar.collective_insights || {};
        let insights = `\nINTELIGENCIA COLETIVA SOBRE ${matchName.toUpperCase()}\n`;
        insights += `(Baseado em ${avatar.metrics?.totalConversations || 0} conversas)\n`;
        insights += `Confianca: ${avatar.confidence_score}%\n\n`;

        if (ci.personalityTraits?.length > 0) {
            insights += `PERSONALIDADE:\n`;
            for (const trait of ci.personalityTraits.slice(0, 5)) {
                insights += `- ${trait.trait} (${trait.confidence}% certeza)\n`;
            }
        }
        if (ci.likes?.length > 0) {
            insights += `\nGOSTA DE:\n`;
            for (const like of ci.likes.slice(0, 5)) {
                insights += `- ${like.content}\n`;
            }
        }
        if (ci.dislikes?.length > 0) {
            insights += `\nNAO GOSTA DE (EVITE!):\n`;
            for (const dislike of ci.dislikes.slice(0, 5)) {
                insights += `- ${dislike.content}\n`;
            }
        }

        const whatWorks = ci.whatWorks?.filter((w) => w.successRate > 60) || [];
        if (whatWorks.length > 0) {
            insights += `\nO QUE FUNCIONA:\n`;
            for (const strategy of whatWorks.slice(0, 5)) {
                insights += `- ${strategy.strategy} (${strategy.successRate.toFixed(0)}% sucesso)\n`;
            }
        }

        const whatDoesntWork = ci.whatDoesntWork?.filter((w) => w.failCount > 2) || [];
        if (whatDoesntWork.length > 0) {
            insights += `\nO QUE NAO FUNCIONA (EVITE!):\n`;
            for (const strategy of whatDoesntWork.slice(0, 5)) {
                insights += `- ${strategy.strategy}\n`;
            }
        }

        return insights;
    }
}
exports.CollectiveAvatarManager = CollectiveAvatarManager;

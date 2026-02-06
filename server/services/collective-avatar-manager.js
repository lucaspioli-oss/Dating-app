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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CollectiveAvatarManager = void 0;
const crypto_1 = require("crypto");
const admin = __importStar(require("firebase-admin"));
const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));
const env_1 = require("../config/env");
const getDb = () => admin.firestore();
const anthropic = new sdk_1.default({ apiKey: env_1.env.ANTHROPIC_API_KEY });
// ═══════════════════════════════════════════════════════════════════
// 🧠 COLLECTIVE AVATAR MANAGER
// ═══════════════════════════════════════════════════════════════════
class CollectiveAvatarManager {
    /**
     * Normalizar nome para matching
     */
    static normalizeName(name) {
        return name
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '') // Remove acentos
            .replace(/[^a-z0-9]/g, '') // Remove caracteres especiais
            .trim();
    }
    /**
     * Gerar ID único para avatar coletivo
     */
    static generateAvatarId(name, platform) {
        const normalizedName = this.normalizeName(name);
        const normalizedPlatform = platform.toLowerCase();
        return `${normalizedName}_${normalizedPlatform}`;
    }
    /**
     * Encontrar ou criar avatar coletivo
     */
    static async findOrCreateCollectiveAvatar(request) {
        const avatarId = this.generateAvatarId(request.name, request.platform);
        const docRef = getDb().collection('collectiveAvatars').doc(avatarId);
        const doc = await docRef.get();
        if (doc.exists) {
            const data = doc.data();
            // Atualizar com novos dados se disponíveis
            await this.mergeAvatarData(avatarId, request);
            return {
                ...data,
                lastUpdated: data.lastUpdated?.toDate() || new Date(),
                lastAnalyzedAt: data.lastAnalyzedAt?.toDate(),
            };
        }
        // Criar novo avatar coletivo
        const now = new Date();
        const newAvatar = {
            id: avatarId,
            normalizedName: this.normalizeName(request.name),
            platform: request.platform,
            profileData: {
                possibleAges: request.age ? [request.age] : [],
                possibleLocations: request.location ? [request.location] : [],
                possibleBios: request.bio ? [request.bio] : [],
                commonInterests: request.interests || [],
            },
            collectiveInsights: {
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
            lastUpdated: now,
            confidenceScore: 10, // Começa baixo
        };
        await docRef.set({
            ...newAvatar,
            lastUpdated: admin.firestore.Timestamp.fromDate(now),
        });
        return newAvatar;
    }
    /**
     * Mesclar dados de perfil (quando vários usuários têm a mesma pessoa)
     */
    static async mergeAvatarData(avatarId, request) {
        const docRef = getDb().collection('collectiveAvatars').doc(avatarId);
        await getDb().runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            if (!doc.exists)
                return;
            const data = doc.data();
            const profileData = data.profileData || {};
            // Adicionar dados únicos
            const updates = {
                lastUpdated: admin.firestore.Timestamp.fromDate(new Date()),
                'metrics.totalConversations': admin.firestore.FieldValue.increment(1),
            };
            if (request.age && !profileData.possibleAges?.includes(request.age)) {
                updates['profileData.possibleAges'] = admin.firestore.FieldValue.arrayUnion(request.age);
            }
            if (request.location && !profileData.possibleLocations?.includes(request.location)) {
                updates['profileData.possibleLocations'] = admin.firestore.FieldValue.arrayUnion(request.location);
            }
            if (request.bio && !profileData.possibleBios?.includes(request.bio)) {
                updates['profileData.possibleBios'] = admin.firestore.FieldValue.arrayUnion(request.bio);
            }
            if (request.interests) {
                for (const interest of request.interests) {
                    if (!profileData.commonInterests?.includes(interest)) {
                        updates['profileData.commonInterests'] = admin.firestore.FieldValue.arrayUnion(interest);
                    }
                }
            }
            transaction.update(docRef, updates);
        });
    }
    /**
     * Obter avatar coletivo por ID
     */
    static async getCollectiveAvatar(avatarId) {
        const doc = await getDb().collection('collectiveAvatars').doc(avatarId).get();
        if (!doc.exists)
            return null;
        const data = doc.data();
        return {
            ...data,
            lastUpdated: data.lastUpdated?.toDate() || new Date(),
            lastAnalyzedAt: data.lastAnalyzedAt?.toDate(),
        };
    }
    /**
     * Submeter feedback sobre mensagem
     */
    static async submitFeedback(request, conversation) {
        const avatarId = this.generateAvatarId(conversation.avatar.matchName, conversation.avatar.platform);
        const message = conversation.messages.find((m) => m.id === request.messageId);
        if (!message)
            return;
        const feedback = {
            id: (0, crypto_1.randomUUID)(),
            collectiveAvatarId: avatarId,
            messageType: conversation.messages.length <= 2 ? 'opener' : 'reply',
            tone: message.tone || 'casual',
            messageSent: this.anonymizeMessage(message.content),
            gotResponse: request.gotResponse,
            responseTime: request.responseTime,
            responseQuality: request.responseQuality,
            timestamp: new Date(),
        };
        // Salvar feedback
        await getDb().collection('messageFeedback').doc(feedback.id).set({
            ...feedback,
            timestamp: admin.firestore.Timestamp.fromDate(feedback.timestamp),
        });
        // Atualizar métricas do avatar coletivo
        await this.updateAvatarFromFeedback(avatarId, feedback);
        // Verificar se precisa reanalisar
        await this.checkAndTriggerAnalysis(avatarId);
    }
    /**
     * Anonimizar mensagem (remover dados pessoais do remetente)
     */
    static anonymizeMessage(message) {
        // Remover possíveis nomes próprios no início (assumindo padrão "Oi, sou X")
        let anonymized = message
            .replace(/sou\s+\w+/gi, 'sou [nome]')
            .replace(/meu nome é\s+\w+/gi, 'meu nome é [nome]')
            .replace(/me chamo\s+\w+/gi, 'me chamo [nome]');
        // Remover números de telefone
        anonymized = anonymized.replace(/\d{2,5}[-.\s]?\d{4,5}[-.\s]?\d{4}/g, '[telefone]');
        // Remover possíveis @usernames
        anonymized = anonymized.replace(/@\w+/g, '[@usuario]');
        return anonymized;
    }
    /**
     * Atualizar avatar baseado em feedback
     */
    static async updateAvatarFromFeedback(avatarId, feedback) {
        const docRef = getDb().collection('collectiveAvatars').doc(avatarId);
        await getDb().runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);
            if (!doc.exists)
                return;
            const data = doc.data();
            const insights = data.collectiveInsights || {};
            // Atualizar estatísticas de opener
            if (feedback.messageType === 'opener') {
                const openerStats = insights.openerStats || [];
                const openerType = this.classifyOpener(feedback.messageSent);
                const existingStat = openerStats.find((s) => s.openerType === openerType);
                if (existingStat) {
                    existingStat.totalSent++;
                    if (feedback.gotResponse) {
                        existingStat.responseRate =
                            (existingStat.responseRate * (existingStat.totalSent - 1) + 100) /
                                existingStat.totalSent;
                    }
                    else {
                        existingStat.responseRate =
                            (existingStat.responseRate * (existingStat.totalSent - 1)) / existingStat.totalSent;
                    }
                    // Adicionar exemplo (max 5)
                    if (existingStat.examples.length < 5) {
                        existingStat.examples.push({
                            opener: feedback.messageSent,
                            gotResponse: feedback.gotResponse,
                            responseQuality: feedback.responseQuality,
                        });
                    }
                }
                else {
                    openerStats.push({
                        openerType,
                        responseRate: feedback.gotResponse ? 100 : 0,
                        avgResponseQuality: feedback.responseQuality || 'neutral',
                        totalSent: 1,
                        examples: [
                            {
                                opener: feedback.messageSent,
                                gotResponse: feedback.gotResponse,
                                responseQuality: feedback.responseQuality,
                            },
                        ],
                    });
                }
                transaction.update(docRef, {
                    'collectiveInsights.openerStats': openerStats,
                    lastUpdated: admin.firestore.Timestamp.fromDate(new Date()),
                });
            }
            // Atualizar o que funciona/não funciona
            if (feedback.gotResponse && feedback.responseQuality === 'warm') {
                const whatWorks = insights.whatWorks || [];
                const strategy = this.extractStrategy(feedback.messageSent, feedback.tone);
                const existing = whatWorks.find((s) => s.strategy === strategy);
                if (existing) {
                    existing.successCount++;
                    existing.successRate = (existing.successCount / (existing.successCount + existing.failCount)) * 100;
                }
                else {
                    whatWorks.push({
                        strategy,
                        successCount: 1,
                        failCount: 0,
                        successRate: 100,
                        examples: [feedback.messageSent],
                    });
                }
                transaction.update(docRef, {
                    'collectiveInsights.whatWorks': whatWorks,
                });
            }
            else if (!feedback.gotResponse) {
                const whatDoesntWork = insights.whatDoesntWork || [];
                const strategy = this.extractStrategy(feedback.messageSent, feedback.tone);
                const existing = whatDoesntWork.find((s) => s.strategy === strategy);
                if (existing) {
                    existing.failCount++;
                }
                else {
                    whatDoesntWork.push({
                        strategy,
                        successCount: 0,
                        failCount: 1,
                        successRate: 0,
                        examples: [feedback.messageSent],
                    });
                }
                transaction.update(docRef, {
                    'collectiveInsights.whatDoesntWork': whatDoesntWork,
                });
            }
            // Atualizar métricas
            transaction.update(docRef, {
                'metrics.totalMessages': admin.firestore.FieldValue.increment(1),
            });
        });
    }
    /**
     * Classificar tipo de opener
     */
    static classifyOpener(opener) {
        const lower = opener.toLowerCase();
        if (lower.match(/^(oi|olá|hey|e aí|eai|opa)\s*$/))
            return 'oi_simples';
        if (lower.match(/^(oi|olá|hey).*(tudo bem|como vai|blz)/))
            return 'oi_pergunta_generica';
        if (lower.includes('?'))
            return 'pergunta';
        if (lower.match(/(haha|kk|rs|😂|😄)/))
            return 'humor';
        if (lower.includes('bio') || lower.includes('perfil'))
            return 'referencia_bio';
        if (lower.includes('foto'))
            return 'referencia_foto';
        if (lower.match(/(linda|lindo|gata|gato|bonita|bonito)/))
            return 'elogio_direto';
        if (lower.length > 100)
            return 'mensagem_longa';
        return 'outro';
    }
    /**
     * Extrair estratégia de uma mensagem
     */
    static extractStrategy(message, tone) {
        const lower = message.toLowerCase();
        if (lower.match(/(haha|kk|rs|😂)/))
            return `humor_${tone}`;
        if (lower.includes('?'))
            return `pergunta_${tone}`;
        if (lower.match(/(viagem|viajar|país|cidade)/))
            return 'tema_viagem';
        if (lower.match(/(comida|comer|restaurante|culinária)/))
            return 'tema_comida';
        if (lower.match(/(música|show|banda|cantor)/))
            return 'tema_musica';
        if (lower.match(/(filme|série|netflix|cinema)/))
            return 'tema_entretenimento';
        if (lower.match(/(academia|treino|esporte|correr)/))
            return 'tema_fitness';
        return `geral_${tone}`;
    }
    /**
     * Verificar se precisa reanalisar o avatar
     */
    static async checkAndTriggerAnalysis(avatarId) {
        const doc = await getDb().collection('collectiveAvatars').doc(avatarId).get();
        if (!doc.exists)
            return;
        const data = doc.data();
        const lastAnalyzed = data.lastAnalyzedAt?.toDate();
        const totalMessages = data.metrics?.totalMessages || 0;
        // Reanalisar se: nunca analisou, ou passou 24h e tem +10 msgs novas
        const shouldAnalyze = !lastAnalyzed ||
            (new Date().getTime() - lastAnalyzed.getTime() > 24 * 60 * 60 * 1000 && totalMessages > 10);
        if (shouldAnalyze) {
            // Agendar análise (não bloquear a request)
            setImmediate(() => this.performDeepAnalysis(avatarId));
        }
    }
    /**
     * Análise profunda do avatar usando IA
     */
    static async performDeepAnalysis(avatarId) {
        console.log(`🧠 Iniciando análise profunda do avatar: ${avatarId}`);
        try {
            const avatar = await this.getCollectiveAvatar(avatarId);
            if (!avatar)
                return;
            // Buscar últimos feedbacks
            const feedbackSnapshot = await getDb()
                .collection('messageFeedback')
                .where('collectiveAvatarId', '==', avatarId)
                .orderBy('timestamp', 'desc')
                .limit(50)
                .get();
            const feedbacks = feedbackSnapshot.docs.map((doc) => doc.data());
            // Buscar conversas relacionadas (últimas 20)
            const conversationsSnapshot = await getDb()
                .collection('conversations')
                .where('avatar.matchName', '==', avatar.normalizedName)
                .orderBy('lastMessageAt', 'desc')
                .limit(20)
                .get();
            const conversations = conversationsSnapshot.docs.map((doc) => doc.data());
            // Preparar contexto para análise
            const analysisContext = this.prepareAnalysisContext(avatar, feedbacks, conversations);
            // Chamar Claude para análise
            const response = await anthropic.messages.create({
                model: 'claude-sonnet-4-20250514',
                max_tokens: 2000,
                messages: [
                    {
                        role: 'user',
                        content: `Você é um analista de padrões de comportamento em conversas de dating apps.

Analise os dados abaixo e extraia insights sobre esta pessoa (${avatar.normalizedName}).

${analysisContext}

Retorne um JSON com a seguinte estrutura:
{
  "personalityTraits": [
    {"trait": "string", "confidence": number, "evidence": ["string"]}
  ],
  "likes": [
    {"content": "string", "confidence": number, "source": "explicit|inferred"}
  ],
  "dislikes": [
    {"content": "string", "confidence": number, "source": "explicit|inferred"}
  ],
  "behaviorPatterns": [
    {"pattern": "string", "frequency": number, "confidence": number}
  ],
  "communicationStyle": {
    "preferredLength": "short|medium|long",
    "usesEmojis": boolean,
    "humor": "low|medium|high",
    "flirtiness": "low|medium|high"
  },
  "bestApproaches": ["string"],
  "avoidThese": ["string"]
}

IMPORTANTE:
- Base suas conclusões APENAS nos dados fornecidos
- Atribua confidence scores realistas (0-100)
- Seja específico nos insights
- Identifique padrões claros`,
                    },
                ],
            });
            // Parsear resposta
            const content = response.content[0];
            if (content.type !== 'text')
                return;
            const jsonMatch = content.text.match(/\{[\s\S]*\}/);
            if (!jsonMatch)
                return;
            const analysis = JSON.parse(jsonMatch[0]);
            // Atualizar avatar com insights da IA
            await this.updateAvatarWithAnalysis(avatarId, analysis);
            console.log(`✅ Análise profunda concluída para: ${avatarId}`);
        }
        catch (error) {
            console.error(`❌ Erro na análise profunda: ${error}`);
        }
    }
    /**
     * Preparar contexto para análise
     */
    static prepareAnalysisContext(avatar, feedbacks, conversations) {
        let context = `
═══════════════════════════════════════════════════════════════════
PERFIL BASE
═══════════════════════════════════════════════════════════════════
Nome: ${avatar.normalizedName}
Plataforma: ${avatar.platform}
Idades reportadas: ${avatar.profileData.possibleAges.join(', ') || 'N/A'}
Localizações: ${avatar.profileData.possibleLocations.join(', ') || 'N/A'}
Interesses comuns: ${avatar.profileData.commonInterests.join(', ') || 'N/A'}
Bios encontradas: ${avatar.profileData.possibleBios.slice(0, 3).join(' | ') || 'N/A'}

Total de conversas: ${avatar.metrics.totalConversations}
Total de mensagens: ${avatar.metrics.totalMessages}

═══════════════════════════════════════════════════════════════════
ESTATÍSTICAS DE OPENERS
═══════════════════════════════════════════════════════════════════
`;
        for (const stat of avatar.collectiveInsights.openerStats || []) {
            context += `
Tipo: ${stat.openerType}
- Taxa de resposta: ${stat.responseRate.toFixed(1)}%
- Qualidade média: ${stat.avgResponseQuality}
- Exemplos: ${stat.examples.slice(0, 2).map((e) => `"${e.opener}" (${e.gotResponse ? '✓' : '✗'})`).join(', ')}
`;
        }
        context += `
═══════════════════════════════════════════════════════════════════
MENSAGENS RECENTES E RESULTADOS
═══════════════════════════════════════════════════════════════════
`;
        for (const feedback of feedbacks.slice(0, 20)) {
            context += `
[${feedback.messageType.toUpperCase()}] "${feedback.messageSent}"
Resultado: ${feedback.gotResponse ? `Respondeu (${feedback.responseQuality})` : 'Não respondeu'}
`;
        }
        context += `
═══════════════════════════════════════════════════════════════════
TRECHOS DE CONVERSAS (anonimizados)
═══════════════════════════════════════════════════════════════════
`;
        for (const conv of conversations.slice(0, 5)) {
            const messages = conv.messages || [];
            context += `\n--- Conversa ${conv.id?.slice(0, 8)} ---\n`;
            for (const msg of messages.slice(0, 10)) {
                const role = msg.role === 'user' ? 'USUÁRIO' : avatar.normalizedName.toUpperCase();
                context += `${role}: "${msg.content}"\n`;
            }
        }
        return context;
    }
    /**
     * Atualizar avatar com resultados da análise
     */
    static async updateAvatarWithAnalysis(avatarId, analysis) {
        const docRef = getDb().collection('collectiveAvatars').doc(avatarId);
        const updates = {
            lastAnalyzedAt: admin.firestore.Timestamp.fromDate(new Date()),
            lastUpdated: admin.firestore.Timestamp.fromDate(new Date()),
        };
        // Mesclar personalityTraits
        if (analysis.personalityTraits) {
            updates['collectiveInsights.personalityTraits'] = analysis.personalityTraits.map((t) => ({
                trait: t.trait,
                confidence: t.confidence,
                evidence: t.evidence || [],
            }));
        }
        // Mesclar likes/dislikes
        if (analysis.likes) {
            updates['collectiveInsights.likes'] = analysis.likes.map((l) => ({
                content: l.content,
                confidence: l.confidence,
                source: l.source || 'inferred',
                firstDiscoveredAt: new Date(),
                confirmationCount: 1,
            }));
        }
        if (analysis.dislikes) {
            updates['collectiveInsights.dislikes'] = analysis.dislikes.map((d) => ({
                content: d.content,
                confidence: d.confidence,
                source: d.source || 'inferred',
                firstDiscoveredAt: new Date(),
                confirmationCount: 1,
            }));
        }
        // Padrões de comportamento
        if (analysis.behaviorPatterns) {
            updates['collectiveInsights.behaviorPatterns'] = analysis.behaviorPatterns.map((p) => ({
                pattern: p.pattern,
                frequency: p.frequency || 1,
                confidence: p.confidence,
                examples: [],
            }));
        }
        // Aumentar confidence score baseado na quantidade de dados
        const avatar = await this.getCollectiveAvatar(avatarId);
        if (avatar) {
            const baseConfidence = Math.min(100, 10 + avatar.metrics.totalConversations * 5 + avatar.metrics.totalMessages * 0.5);
            updates.confidenceScore = baseConfidence;
        }
        await docRef.update(updates);
    }
    /**
     * Obter insights formatados para o prompt
     */
    static async getCollectiveInsightsForPrompt(matchName, platform) {
        const avatarId = this.generateAvatarId(matchName, platform);
        const avatar = await this.getCollectiveAvatar(avatarId);
        if (!avatar || avatar.confidenceScore < 20) {
            return ''; // Não temos dados suficientes
        }
        let insights = `
═══════════════════════════════════════════════════════════════════
🧠 INTELIGÊNCIA COLETIVA SOBRE ${matchName.toUpperCase()}
(Baseado em ${avatar.metrics.totalConversations} conversas de múltiplos usuários)
Confiança: ${avatar.confidenceScore}%
═══════════════════════════════════════════════════════════════════

`;
        // Personalidade
        if (avatar.collectiveInsights.personalityTraits?.length > 0) {
            insights += `🎭 PERSONALIDADE DETECTADA:\n`;
            for (const trait of avatar.collectiveInsights.personalityTraits.slice(0, 5)) {
                insights += `- ${trait.trait} (${trait.confidence}% certeza)\n`;
            }
            insights += '\n';
        }
        // Likes
        if (avatar.collectiveInsights.likes?.length > 0) {
            insights += `💚 GOSTA DE:\n`;
            for (const like of avatar.collectiveInsights.likes.slice(0, 5)) {
                insights += `- ${like.content} (${like.source === 'explicit' ? 'ela disse' : 'inferido'})\n`;
            }
            insights += '\n';
        }
        // Dislikes
        if (avatar.collectiveInsights.dislikes?.length > 0) {
            insights += `🚫 NÃO GOSTA DE (EVITE!):\n`;
            for (const dislike of avatar.collectiveInsights.dislikes.slice(0, 5)) {
                insights += `- ${dislike.content} (${dislike.source === 'explicit' ? 'ela disse' : 'inferido'})\n`;
            }
            insights += '\n';
        }
        // Padrões de comportamento
        if (avatar.collectiveInsights.behaviorPatterns?.length > 0) {
            insights += `📊 PADRÕES DE COMPORTAMENTO:\n`;
            for (const pattern of avatar.collectiveInsights.behaviorPatterns.slice(0, 5)) {
                insights += `- ${pattern.pattern}\n`;
            }
            insights += '\n';
        }
        // O que funciona
        const whatWorks = avatar.collectiveInsights.whatWorks?.filter((w) => w.successRate > 60) || [];
        if (whatWorks.length > 0) {
            insights += `✅ O QUE FUNCIONA COM ELA:\n`;
            for (const strategy of whatWorks.slice(0, 5)) {
                insights += `- ${strategy.strategy} (${strategy.successRate.toFixed(0)}% sucesso)\n`;
            }
            insights += '\n';
        }
        // O que não funciona
        const whatDoesntWork = avatar.collectiveInsights.whatDoesntWork?.filter((w) => w.failCount > 2) || [];
        if (whatDoesntWork.length > 0) {
            insights += `❌ O QUE NÃO FUNCIONA (EVITE!):\n`;
            for (const strategy of whatDoesntWork.slice(0, 5)) {
                insights += `- ${strategy.strategy}\n`;
            }
            insights += '\n';
        }
        // Estatísticas de openers
        const goodOpeners = avatar.collectiveInsights.openerStats?.filter((o) => o.responseRate > 50) || [];
        const badOpeners = avatar.collectiveInsights.openerStats?.filter((o) => o.responseRate < 30) || [];
        if (goodOpeners.length > 0) {
            insights += `🎯 OPENERS QUE FUNCIONAM:\n`;
            for (const opener of goodOpeners.slice(0, 3)) {
                insights += `- ${opener.openerType}: ${opener.responseRate.toFixed(0)}% de resposta\n`;
            }
            insights += '\n';
        }
        if (badOpeners.length > 0) {
            insights += `⚠️ OPENERS A EVITAR:\n`;
            for (const opener of badOpeners.slice(0, 3)) {
                insights += `- ${opener.openerType}: apenas ${opener.responseRate.toFixed(0)}% de resposta\n`;
            }
            insights += '\n';
        }
        insights += `═══════════════════════════════════════════════════════════════════\n`;
        return insights;
    }
}
exports.CollectiveAvatarManager = CollectiveAvatarManager;

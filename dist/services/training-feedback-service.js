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
exports.TrainingFeedbackService = void 0;
const crypto_1 = require("crypto");
const admin = __importStar(require("firebase-admin"));
const getDb = () => admin.firestore();
const COLLECTION = 'trainingFeedback';
class TrainingFeedbackService {
    /**
     * Criar novo feedback de treinamento
     */
    static async create(request) {
        const id = (0, crypto_1.randomUUID)();
        const now = new Date();
        const feedback = {
            id,
            category: request.category,
            subcategory: request.subcategory,
            instruction: request.instruction,
            examples: request.examples || [],
            tags: request.tags || [],
            priority: request.priority || 'medium',
            isActive: true,
            createdAt: now,
            updatedAt: now,
            usageCount: 0,
        };
        await getDb().collection(COLLECTION).doc(id).set({
            ...feedback,
            createdAt: admin.firestore.Timestamp.fromDate(now),
            updatedAt: admin.firestore.Timestamp.fromDate(now),
        });
        return feedback;
    }
    /**
     * Atualizar feedback existente
     */
    static async update(request) {
        const docRef = getDb().collection(COLLECTION).doc(request.id);
        const doc = await docRef.get();
        if (!doc.exists)
            return null;
        const updates = {
            updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
        };
        if (request.instruction !== undefined)
            updates.instruction = request.instruction;
        if (request.examples !== undefined)
            updates.examples = request.examples;
        if (request.tags !== undefined)
            updates.tags = request.tags;
        if (request.priority !== undefined)
            updates.priority = request.priority;
        if (request.isActive !== undefined)
            updates.isActive = request.isActive;
        await docRef.update(updates);
        const updated = await docRef.get();
        return this.docToFeedback(updated);
    }
    /**
     * Deletar feedback
     */
    static async delete(id) {
        const docRef = getDb().collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists)
            return false;
        await docRef.delete();
        return true;
    }
    /**
     * Buscar todos os feedbacks ativos
     */
    static async getAllActive() {
        const snapshot = await getDb()
            .collection(COLLECTION)
            .where('isActive', '==', true)
            .orderBy('priority')
            .orderBy('createdAt', 'desc')
            .get();
        return snapshot.docs.map(this.docToFeedback);
    }
    /**
     * Buscar feedbacks por categoria
     */
    static async getByCategory(category) {
        const snapshot = await getDb()
            .collection(COLLECTION)
            .where('category', '==', category)
            .where('isActive', '==', true)
            .orderBy('priority')
            .get();
        return snapshot.docs.map(this.docToFeedback);
    }
    /**
     * Buscar todos os feedbacks (incluindo inativos)
     */
    static async getAll() {
        const snapshot = await getDb()
            .collection(COLLECTION)
            .orderBy('createdAt', 'desc')
            .get();
        return snapshot.docs.map(this.docToFeedback);
    }
    /**
     * Incrementar contador de uso
     */
    static async incrementUsage(id) {
        const docRef = getDb().collection(COLLECTION).doc(id);
        await docRef.update({
            usageCount: admin.firestore.FieldValue.increment(1),
        });
    }
    /**
     * Obter contexto de treinamento para os prompts
     */
    static async getTrainingContext() {
        const all = await this.getAllActive();
        return {
            openers: all.filter(f => f.category === 'opener'),
            replies: all.filter(f => f.category === 'reply'),
            calibration: all.filter(f => f.category === 'calibration'),
            general: all.filter(f => f.category === 'general'),
            whatWorks: all.filter(f => f.category === 'what_works'),
            whatDoesntWork: all.filter(f => f.category === 'what_doesnt_work'),
        };
    }
    /**
     * Gerar texto de contexto para incluir nos prompts
     */
    static async generatePromptContext(category) {
        const feedbacks = category
            ? await this.getByCategory(category)
            : await this.getAllActive();
        if (feedbacks.length === 0)
            return '';
        let context = `
═══════════════════════════════════════════════════════════════════
📚 INSTRUÇÕES DE TREINAMENTO PERSONALIZADAS
═══════════════════════════════════════════════════════════════════

`;
        // Agrupar por categoria
        const grouped = feedbacks.reduce((acc, f) => {
            if (!acc[f.category])
                acc[f.category] = [];
            acc[f.category].push(f);
            return acc;
        }, {});
        const categoryLabels = {
            opener: '🎯 ABRIDORES',
            reply: '💬 RESPOSTAS',
            calibration: '🔥 CALIBRAGEM',
            general: '📋 GERAL',
            what_works: '✅ O QUE FUNCIONA',
            what_doesnt_work: '❌ O QUE NÃO FUNCIONA',
        };
        for (const [cat, items] of Object.entries(grouped)) {
            context += `${categoryLabels[cat] || cat.toUpperCase()}:\n`;
            for (const item of items) {
                // Marcar para incrementar uso
                this.incrementUsage(item.id).catch(() => { });
                context += `• ${item.instruction}\n`;
                if (item.examples && item.examples.length > 0) {
                    context += `  Exemplos: ${item.examples.map(e => `"${e}"`).join(', ')}\n`;
                }
            }
            context += '\n';
        }
        return context;
    }
    /**
     * Converter documento Firestore para TrainingFeedback
     */
    static docToFeedback(doc) {
        const data = doc.data();
        return {
            id: doc.id,
            category: data.category,
            subcategory: data.subcategory,
            instruction: data.instruction,
            examples: data.examples || [],
            tags: data.tags || [],
            priority: data.priority || 'medium',
            isActive: data.isActive ?? true,
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate() || new Date(),
            usageCount: data.usageCount || 0,
        };
    }
}
exports.TrainingFeedbackService = TrainingFeedbackService;

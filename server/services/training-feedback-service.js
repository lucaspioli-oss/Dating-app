"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TrainingFeedbackService = void 0;
const crypto_1 = require("crypto");
const { supabaseAdmin } = require("../config/supabase");

const TABLE = 'training_feedback';

class TrainingFeedbackService {
    static async create(request) {
        const id = (0, crypto_1.randomUUID)();
        const now = new Date().toISOString();
        const feedback = {
            id,
            user_id: request.userId || null,
            category: request.category,
            subcategory: request.subcategory,
            instruction: request.instruction,
            examples: request.examples || [],
            tags: request.tags || [],
            priority: request.priority || 'medium',
            is_active: true,
            usage_count: 0,
            created_at: now,
            updated_at: now,
        };

        const { error } = await supabaseAdmin.from(TABLE).insert(feedback);
        if (error) throw new Error(error.message);

        return {
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
    }

    static async update(request) {
        const updates = { updated_at: new Date().toISOString() };
        if (request.instruction !== undefined) updates.instruction = request.instruction;
        if (request.examples !== undefined) updates.examples = request.examples;
        if (request.tags !== undefined) updates.tags = request.tags;
        if (request.priority !== undefined) updates.priority = request.priority;
        if (request.isActive !== undefined) updates.is_active = request.isActive;

        const { data, error } = await supabaseAdmin
            .from(TABLE)
            .update(updates)
            .eq('id', request.id)
            .select()
            .single();

        if (error || !data) return null;
        return this.rowToFeedback(data);
    }

    static async delete(id) {
        const { error } = await supabaseAdmin.from(TABLE).delete().eq('id', id);
        return !error;
    }

    static async getAllActive() {
        const { data } = await supabaseAdmin
            .from(TABLE)
            .select('*')
            .eq('is_active', true)
            .order('priority')
            .order('created_at', { ascending: false });

        return (data || []).map(this.rowToFeedback);
    }

    static async getByCategory(category) {
        const { data } = await supabaseAdmin
            .from(TABLE)
            .select('*')
            .eq('category', category)
            .eq('is_active', true)
            .order('priority');

        return (data || []).map(this.rowToFeedback);
    }

    static async getAll() {
        const { data } = await supabaseAdmin
            .from(TABLE)
            .select('*')
            .order('created_at', { ascending: false });

        return (data || []).map(this.rowToFeedback);
    }

    static async incrementUsage(id) {
        // Use RPC if available, otherwise manual increment
        const { data } = await supabaseAdmin
            .from(TABLE)
            .select('usage_count')
            .eq('id', id)
            .single();

        if (data) {
            await supabaseAdmin
                .from(TABLE)
                .update({ usage_count: (data.usage_count || 0) + 1 })
                .eq('id', id);
        }
    }

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

    static async generatePromptContext(category) {
        const feedbacks = category
            ? await this.getByCategory(category)
            : await this.getAllActive();

        if (feedbacks.length === 0) return '';

        let context = `\nINSTRUCOES DE TREINAMENTO PERSONALIZADAS\n\n`;
        const grouped = feedbacks.reduce((acc, f) => {
            if (!acc[f.category]) acc[f.category] = [];
            acc[f.category].push(f);
            return acc;
        }, {});

        const categoryLabels = {
            opener: 'ABRIDORES',
            reply: 'RESPOSTAS',
            calibration: 'CALIBRAGEM',
            general: 'GERAL',
            what_works: 'O QUE FUNCIONA',
            what_doesnt_work: 'O QUE NAO FUNCIONA',
        };

        for (const [cat, items] of Object.entries(grouped)) {
            context += `${categoryLabels[cat] || cat.toUpperCase()}:\n`;
            for (const item of items) {
                this.incrementUsage(item.id).catch(() => {});
                context += `- ${item.instruction}\n`;
                if (item.examples?.length > 0) {
                    context += `  Exemplos: ${item.examples.map(e => `"${e}"`).join(', ')}\n`;
                }
            }
            context += '\n';
        }

        return context;
    }

    static rowToFeedback(row) {
        return {
            id: row.id,
            category: row.category,
            subcategory: row.subcategory,
            instruction: row.instruction,
            examples: row.examples || [],
            tags: row.tags || [],
            priority: row.priority || 'medium',
            isActive: row.is_active ?? true,
            createdAt: row.created_at,
            updatedAt: row.updated_at,
            usageCount: row.usage_count || 0,
        };
    }
}
exports.TrainingFeedbackService = TrainingFeedbackService;

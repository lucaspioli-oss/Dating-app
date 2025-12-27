import { randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import {
  TrainingFeedback,
  CreateTrainingFeedbackRequest,
  UpdateTrainingFeedbackRequest,
  TrainingContext,
} from '../types/training-feedback';

const getDb = () => admin.firestore();
const COLLECTION = 'trainingFeedback';

export class TrainingFeedbackService {
  /**
   * Criar novo feedback de treinamento
   */
  static async create(request: CreateTrainingFeedbackRequest): Promise<TrainingFeedback> {
    const id = randomUUID();
    const now = new Date();

    const feedback: TrainingFeedback = {
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
  static async update(request: UpdateTrainingFeedbackRequest): Promise<TrainingFeedback | null> {
    const docRef = getDb().collection(COLLECTION).doc(request.id);
    const doc = await docRef.get();

    if (!doc.exists) return null;

    const updates: any = {
      updatedAt: admin.firestore.Timestamp.fromDate(new Date()),
    };

    if (request.instruction !== undefined) updates.instruction = request.instruction;
    if (request.examples !== undefined) updates.examples = request.examples;
    if (request.tags !== undefined) updates.tags = request.tags;
    if (request.priority !== undefined) updates.priority = request.priority;
    if (request.isActive !== undefined) updates.isActive = request.isActive;

    await docRef.update(updates);

    const updated = await docRef.get();
    return this.docToFeedback(updated);
  }

  /**
   * Deletar feedback
   */
  static async delete(id: string): Promise<boolean> {
    const docRef = getDb().collection(COLLECTION).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) return false;

    await docRef.delete();
    return true;
  }

  /**
   * Buscar todos os feedbacks ativos
   */
  static async getAllActive(): Promise<TrainingFeedback[]> {
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
  static async getByCategory(category: TrainingFeedback['category']): Promise<TrainingFeedback[]> {
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
  static async getAll(): Promise<TrainingFeedback[]> {
    const snapshot = await getDb()
      .collection(COLLECTION)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs.map(this.docToFeedback);
  }

  /**
   * Incrementar contador de uso
   */
  static async incrementUsage(id: string): Promise<void> {
    const docRef = getDb().collection(COLLECTION).doc(id);
    await docRef.update({
      usageCount: admin.firestore.FieldValue.increment(1),
    });
  }

  /**
   * Obter contexto de treinamento para os prompts
   */
  static async getTrainingContext(): Promise<TrainingContext> {
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
  static async generatePromptContext(category?: TrainingFeedback['category']): Promise<string> {
    const feedbacks = category
      ? await this.getByCategory(category)
      : await this.getAllActive();

    if (feedbacks.length === 0) return '';

    let context = `
═══════════════════════════════════════════════════════════════════
📚 INSTRUÇÕES DE TREINAMENTO PERSONALIZADAS
═══════════════════════════════════════════════════════════════════

`;

    // Agrupar por categoria
    const grouped = feedbacks.reduce((acc, f) => {
      if (!acc[f.category]) acc[f.category] = [];
      acc[f.category].push(f);
      return acc;
    }, {} as Record<string, TrainingFeedback[]>);

    const categoryLabels: Record<string, string> = {
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
        this.incrementUsage(item.id).catch(() => {});

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
  private static docToFeedback(doc: admin.firestore.DocumentSnapshot): TrainingFeedback {
    const data = doc.data()!;
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

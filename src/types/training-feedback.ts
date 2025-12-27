// Tipos para o sistema de feedback de treinamento

export interface TrainingFeedback {
  id: string;
  category: 'opener' | 'reply' | 'calibration' | 'general' | 'what_works' | 'what_doesnt_work';
  subcategory?: string; // Ex: "humor", "direct", "flirty", etc.
  instruction: string; // O texto do feedback/instrução
  examples?: string[]; // Exemplos relacionados
  tags?: string[]; // Tags para classificação
  priority: 'high' | 'medium' | 'low';
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
  usageCount: number; // Quantas vezes foi usado nos prompts
}

export interface CreateTrainingFeedbackRequest {
  category: TrainingFeedback['category'];
  subcategory?: string;
  instruction: string;
  examples?: string[];
  tags?: string[];
  priority?: TrainingFeedback['priority'];
}

export interface UpdateTrainingFeedbackRequest {
  id: string;
  instruction?: string;
  examples?: string[];
  tags?: string[];
  priority?: TrainingFeedback['priority'];
  isActive?: boolean;
}

export interface TrainingContext {
  openers: TrainingFeedback[];
  replies: TrainingFeedback[];
  calibration: TrainingFeedback[];
  general: TrainingFeedback[];
  whatWorks: TrainingFeedback[];
  whatDoesntWork: TrainingFeedback[];
}

export interface AnalyzeRequest {
  text: string;
  tone: 'engraçado' | 'ousado' | 'romântico' | 'casual' | 'confiante' | 'expert';
}

export interface AnalyzeResponse {
  analysis: string;
  suggestions?: string[];
  score?: number;
}

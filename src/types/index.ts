export interface AnalyzeRequest {
  text: string;
  tone: 'engraçado' | 'ousado' | 'romântico' | 'casual' | 'confiante';
}

export interface AnalyzeResponse {
  analysis: string;
  suggestions?: string[];
  score?: number;
}

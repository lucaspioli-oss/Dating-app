export interface Question {
  id: number
  text: string
  options: { text: string; points: number }[]
}

export interface Profile {
  id: string
  name: string
  minScore: number
  maxScore: number
  description: string
  recommendations: string[]
}

export const questions: Question[] = [
  {
    id: 1,
    text: "Como voce se descreve em conversas?",
    options: [
      { text: "Sou o cara que faz ela rir", points: 15 },
      { text: "Sou timido, mas tenho qualidades", points: 5 },
      { text: "Sou estrategico e calculista", points: 20 },
      { text: "Sou autentico e genuino", points: 10 },
      { text: "Sou iniciante, estou aprendendo", points: 3 },
      { text: "Gosto de analisar padroes", points: 18 },
    ],
  },
  {
    id: 2,
    text: "Qual e seu maior desafio?",
    options: [
      { text: "A conversa morre depois de pouco tempo", points: 15 },
      { text: "Tenho medo de ser rejeitado", points: 5 },
      { text: "Quero otimizar meus resultados", points: 20 },
      { text: "Quero criar conexao real", points: 10 },
      { text: "Nao sei nem como comecar", points: 3 },
      { text: "Quero entender a psicologia por tras", points: 18 },
    ],
  },
  {
    id: 3,
    text: "Qual e seu objetivo principal?",
    options: [
      { text: "Virar melhor em conversas", points: 15 },
      { text: "Ganhar confianca", points: 5 },
      { text: "Maximizar taxa de encontros", points: 20 },
      { text: "Encontrar alguem especial", points: 10 },
      { text: "Ter meu primeiro encontro", points: 3 },
      { text: "Entender o que funciona", points: 18 },
    ],
  },
  {
    id: 4,
    text: "Como voce reage a rejeicao?",
    options: [
      { text: "Fico frustrado, mas continuo", points: 15 },
      { text: "Fico desanimado", points: 5 },
      { text: "Analiso o que deu errado", points: 20 },
      { text: "Entendo que nem sempre vai funcionar", points: 10 },
      { text: "Fico com muito medo", points: 3 },
      { text: "Busco dados sobre por que falhou", points: 18 },
    ],
  },
  {
    id: 5,
    text: "Qual e seu nivel de experiencia?",
    options: [
      { text: "Tenho experiencia, mas quero melhorar", points: 15 },
      { text: "Tenho pouca experiencia", points: 5 },
      { text: "Sou experiente e quero dominar", points: 20 },
      { text: "Tenho experiencia, mas busco autenticidade", points: 10 },
      { text: "Sou totalmente iniciante", points: 3 },
      { text: "Tenho experiencia e gosto de dados", points: 18 },
    ],
  },
  {
    id: 6,
    text: "O que mais te atrai no Desenrola AI?",
    options: [
      { text: "Respostas prontas para usar", points: 15 },
      { text: "Seguranca e confianca", points: 5 },
      { text: "Estrategia avancada", points: 20 },
      { text: "Conexao autentica", points: 10 },
      { text: "Comecar do zero", points: 3 },
      { text: "Analise e dados", points: 18 },
    ],
  },
  {
    id: 7,
    text: "Qual e seu estilo de aprendizado?",
    options: [
      { text: "Pratico, quero resultados rapido", points: 15 },
      { text: "Passo a passo, com seguranca", points: 5 },
      { text: "Estrategico e otimizado", points: 20 },
      { text: "Emocional e significativo", points: 10 },
      { text: "Basico, do zero", points: 3 },
      { text: "Analitico e baseado em dados", points: 18 },
    ],
  },
]

// Score ranges recalculados:
// Min possivel: 7 x 3 = 21
// Max possivel: 7 x 20 = 140
export const profiles: Profile[] = [
  {
    id: "iniciante",
    name: "O Iniciante",
    minScore: 0,
    maxScore: 35,
    description: "Voce esta comecando sua jornada e precisa de fundamentos solidos. Voce pode se sentir perdido as vezes, mas tem muita vontade de aprender.",
    recommendations: [
      "Foque no basico de iniciar conversas",
      "Construa confianca aos poucos",
      "Nao tenha medo de errar, faz parte do aprendizado",
    ],
  },
  {
    id: "timido",
    name: "O Timido",
    minScore: 36,
    maxScore: 55,
    description: "Voce tem otimas qualidades, mas sua timidez impede que os outros vejam isso. Voce pensa muito antes de falar e acaba perdendo oportunidades.",
    recommendations: [
      "Use a IA para quebrar o gelo inicial",
      "Pratique em ambientes de baixa pressao",
      "Valorize suas qualidades de ouvinte",
    ],
  },
  {
    id: "romantico",
    name: "O Romantico",
    minScore: 56,
    maxScore: 75,
    description: "Voce busca conexoes profundas e verdadeiras. Valoriza a autenticidade e quer encontrar alguem especial, nao apenas encontros casuais.",
    recommendations: [
      "Mostre sua intencao genuina",
      "Crie conversas emocionais",
      "Nao tenha pressa, qualidade > quantidade",
    ],
  },
  {
    id: "conversador-trava",
    name: "O Conversador Que Trava",
    minScore: 76,
    maxScore: 95,
    description: "Voce sabe chamar atencao e iniciar conversas, mas tem dificuldade em manter o ritmo. A conversa morre depois de pouco tempo.",
    recommendations: [
      "Aprenda a manter o ritmo da conversa",
      "Domine respostas que criam curiosidade",
      "Transforme conversas em encontros",
    ],
  },
  {
    id: "conquistador",
    name: "O Conquistador",
    minScore: 96,
    maxScore: 115,
    description: "Voce ja tem bons resultados e confianca, mas quer refinar sua tecnica para atingir a excelencia e ter mais opcoes.",
    recommendations: [
      "Otimize seu tempo com as melhores respostas",
      "Aprenda tecnicas avancadas de persuasao",
      "Escale seus resultados",
    ],
  },
  {
    id: "analitico",
    name: "O Analitico",
    minScore: 116,
    maxScore: 150,
    description: "Voce ve as interacoes sociais como sistemas que podem ser otimizados. Gosta de entender a psicologia e os dados por tras de cada interacao.",
    recommendations: [
      "Use dados para melhorar sua performance",
      "Teste diferentes abordagens (A/B testing)",
      "Domine a psicologia da atracao",
    ],
  },
]

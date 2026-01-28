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

export const questionsES: Question[] = [
  {
    id: 1,
    text: "¿Cómo te describes en las conversaciones?",
    options: [
      { text: "Soy el que la hace reír", points: 15 },
      { text: "Soy tímido, pero tengo cualidades", points: 5 },
      { text: "Soy estratégico y calculador", points: 20 },
      { text: "Soy auténtico y genuino", points: 10 },
      { text: "Soy principiante, estoy aprendiendo", points: 3 },
      { text: "Me gusta analizar patrones", points: 18 },
    ],
  },
  {
    id: 2,
    text: "¿Cuál es tu mayor desafío?",
    options: [
      { text: "La conversación muere después de poco tiempo", points: 15 },
      { text: "Tengo miedo de ser rechazado", points: 5 },
      { text: "Quiero optimizar mis resultados", points: 20 },
      { text: "Quiero crear conexión real", points: 10 },
      { text: "No sé ni cómo empezar", points: 3 },
      { text: "Quiero entender la psicología detrás", points: 18 },
    ],
  },
  {
    id: 3,
    text: "¿Cuál es tu objetivo principal?",
    options: [
      { text: "Ser mejor en conversaciones", points: 15 },
      { text: "Ganar confianza", points: 5 },
      { text: "Maximizar tasa de citas", points: 20 },
      { text: "Encontrar a alguien especial", points: 10 },
      { text: "Tener mi primera cita", points: 3 },
      { text: "Entender qué funciona", points: 18 },
    ],
  },
  {
    id: 4,
    text: "¿Cómo reaccionas al rechazo?",
    options: [
      { text: "Me frustro, pero sigo adelante", points: 15 },
      { text: "Me desanimo", points: 5 },
      { text: "Analizo qué salió mal", points: 20 },
      { text: "Entiendo que no siempre funcionará", points: 10 },
      { text: "Me da mucho miedo", points: 3 },
      { text: "Busco datos sobre por qué falló", points: 18 },
    ],
  },
  {
    id: 5,
    text: "¿Cuál es tu nivel de experiencia?",
    options: [
      { text: "Tengo experiencia, pero quiero mejorar", points: 15 },
      { text: "Tengo poca experiencia", points: 5 },
      { text: "Soy experimentado y quiero dominar", points: 20 },
      { text: "Tengo experiencia, pero busco autenticidad", points: 10 },
      { text: "Soy totalmente principiante", points: 3 },
      { text: "Tengo experiencia y me gustan los datos", points: 18 },
    ],
  },
  {
    id: 6,
    text: "¿Qué te atrae más de Desenrola AI?",
    options: [
      { text: "Respuestas listas para usar", points: 15 },
      { text: "Seguridad y confianza", points: 5 },
      { text: "Estrategia avanzada", points: 20 },
      { text: "Conexión auténtica", points: 10 },
      { text: "Empezar desde cero", points: 3 },
      { text: "Análisis y datos", points: 18 },
    ],
  },
  {
    id: 7,
    text: "¿Cuál es tu estilo de aprendizaje?",
    options: [
      { text: "Práctico, quiero resultados rápidos", points: 15 },
      { text: "Paso a paso, con seguridad", points: 5 },
      { text: "Estratégico y optimizado", points: 20 },
      { text: "Emocional y significativo", points: 10 },
      { text: "Básico, desde cero", points: 3 },
      { text: "Analítico y basado en datos", points: 18 },
    ],
  },
]

export const profilesES: Profile[] = [
  {
    id: "iniciante",
    name: "El Principiante",
    minScore: 0,
    maxScore: 35,
    description: "Estás comenzando tu viaje y necesitas fundamentos sólidos. Puedes sentirte perdido a veces, pero tienes mucha voluntad de aprender.",
    recommendations: [
      "Enfócate en lo básico de iniciar conversaciones",
      "Construye confianza poco a poco",
      "No tengas miedo de equivocarte, es parte del aprendizaje",
    ],
  },
  {
    id: "timido",
    name: "El Tímido",
    minScore: 36,
    maxScore: 55,
    description: "Tienes excelentes cualidades, pero tu timidez impide que los demás las vean. Piensas mucho antes de hablar y terminas perdiendo oportunidades.",
    recommendations: [
      "Usa la IA para romper el hielo inicial",
      "Practica en ambientes de baja presión",
      "Valora tus cualidades de oyente",
    ],
  },
  {
    id: "romantico",
    name: "El Romántico",
    minScore: 56,
    maxScore: 75,
    description: "Buscas conexiones profundas y verdaderas. Valoras la autenticidad y quieres encontrar a alguien especial, no solo citas casuales.",
    recommendations: [
      "Muestra tu intención genuina",
      "Crea conversaciones emocionales",
      "No tengas prisa, calidad > cantidad",
    ],
  },
  {
    id: "conversador-trava",
    name: "El Conversador Que Se Traba",
    minScore: 76,
    maxScore: 95,
    description: "Sabes llamar la atención e iniciar conversaciones, pero tienes dificultad en mantener el ritmo. La conversación muere después de poco tiempo.",
    recommendations: [
      "Aprende a mantener el ritmo de la conversación",
      "Domina respuestas que crean curiosidad",
      "Transforma conversaciones en citas",
    ],
  },
  {
    id: "conquistador",
    name: "El Conquistador",
    minScore: 96,
    maxScore: 115,
    description: "Ya tienes buenos resultados y confianza, pero quieres refinar tu técnica para alcanzar la excelencia y tener más opciones.",
    recommendations: [
      "Optimiza tu tiempo con las mejores respuestas",
      "Aprende técnicas avanzadas de persuasión",
      "Escala tus resultados",
    ],
  },
  {
    id: "analitico",
    name: "El Analítico",
    minScore: 116,
    maxScore: 150,
    description: "Ves las interacciones sociales como sistemas que pueden ser optimizados. Te gusta entender la psicología y los datos detrás de cada interacción.",
    recommendations: [
      "Usa datos para mejorar tu rendimiento",
      "Prueba diferentes enfoques (A/B testing)",
      "Domina la psicología de la atracción",
    ],
  },
]

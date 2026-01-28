/**
 * Script completo do Chat
 * Sequência de mensagens com timings e comportamentos
 */

export interface ChatMessage {
  id: string;
  sender: "ana" | "mina" | "user" | "system";
  type: "text" | "image" | "options" | "button" | "suggestion" | "transition";
  content: string;
  delay: number; // ms antes de mostrar
  typingDuration?: number; // ms de "digitando..."
  options?: ChatOption[];
  imageUrl?: string;
}

export interface ChatOption {
  id: string;
  label: string;
}

export const chatScript: ChatMessage[] = [
  // ============================================
  // PARTE 1: ABERTURA
  // ============================================
  {
    id: "ana_1",
    sender: "ana",
    type: "text",
    content: "Você atendeu. Isso já diz algo sobre você.",
    delay: 1000,
    typingDuration: 1500
  },
  {
    id: "ana_2",
    sender: "ana",
    type: "text",
    content: "Agora eu preciso entender uma coisa.",
    delay: 1500,
    typingDuration: 1200
  },
  {
    id: "ana_3",
    sender: "ana",
    type: "text",
    content: "Por que você quer isso?",
    delay: 1000,
    typingDuration: 800
  },
  {
    id: "options_1",
    sender: "system",
    type: "options",
    content: "",
    delay: 500,
    options: [
      { id: "opt_vacuo", label: "Cansei de tomar vacuo" },
      { id: "opt_travar", label: "Quero parar de travar nas conversas" },
      { id: "opt_resultados", label: "Quero ter mais resultados" }
    ]
  },
  // [USUÁRIO RESPONDE - inserido dinamicamente]
  {
    id: "ana_4",
    sender: "ana",
    type: "text",
    content: "Entendi.",
    delay: 800,
    typingDuration: 500
  },
  {
    id: "ana_5",
    sender: "ana",
    type: "text",
    content: "Vou te mostrar o que o Code criou. Mas não vou só FALAR. Vou te fazer SENTIR.",
    delay: 1000,
    typingDuration: 2000
  },
  {
    id: "ana_6",
    sender: "ana",
    type: "text",
    content: "Faz o seguinte. Imagina que eu sou uma mina que você acabou de dar match. Vou te mandar uma mensagem como ela mandaria. Você responde como você responderia normalmente.",
    delay: 1200,
    typingDuration: 3000
  },
  {
    id: "ana_7",
    sender: "ana",
    type: "text",
    content: "Preparado?",
    delay: 1000,
    typingDuration: 500
  },
  {
    id: "btn_bora",
    sender: "system",
    type: "button",
    content: "BORA",
    delay: 500
  },

  // ============================================
  // PARTE 2: SIMULAÇÃO
  // ============================================
  {
    id: "transition_mina",
    sender: "system",
    type: "transition",
    content: "mina", // indica mudança de personagem
    delay: 800
  },
  {
    id: "mina_1",
    sender: "mina",
    type: "text",
    content: "oi",
    delay: 1500,
    typingDuration: 800
  },
  {
    id: "options_2",
    sender: "system",
    type: "options",
    content: "",
    delay: 500,
    options: [
      { id: "resp_1a", label: "Oi, tudo bem?" },
      { id: "resp_1b", label: "E aí, beleza?" }
    ]
  },
  // [USUÁRIO RESPONDE]
  {
    id: "mina_2",
    sender: "mina",
    type: "text",
    content: "bem e vc",
    delay: 2000,
    typingDuration: 600
  },
  {
    id: "options_3",
    sender: "system",
    type: "options",
    content: "",
    delay: 500,
    options: [
      { id: "resp_2a", label: "Também, de boa" },
      { id: "resp_2b", label: "Tranquilo, trabalhando" }
    ]
  },
  // [USUÁRIO RESPONDE]
  {
    id: "mina_3",
    sender: "mina",
    type: "text",
    content: "legal",
    delay: 2500,
    typingDuration: 400
  },
  // SILÊNCIO - conversa morre
  {
    id: "silence",
    sender: "system",
    type: "transition",
    content: "silence", // indica pausa dramática
    delay: 4000 // 4 segundos de nada
  },

  // ============================================
  // PARTE 3: ANÁLISE
  // ============================================
  {
    id: "transition_ana",
    sender: "system",
    type: "transition",
    content: "ana", // volta pra Ana
    delay: 500
  },
  {
    id: "ana_8",
    sender: "ana",
    type: "text",
    content: "Morreu né?",
    delay: 1000,
    typingDuration: 600
  },
  {
    id: "ana_9",
    sender: "ana",
    type: "text",
    content: "Essa é a realidade de 90% dos caras. A conversa simplesmente... morre.",
    delay: 1500,
    typingDuration: 2000
  },
  {
    id: "ana_10",
    sender: "ana",
    type: "text",
    content: "Agora olha o que o sistema do Code sugeriria nesse momento exato:",
    delay: 1200,
    typingDuration: 1800
  },
  {
    id: "suggestion_1",
    sender: "system",
    type: "suggestion",
    content: "Legal é fichinha. Me conta algo sobre você que eu não ia adivinhar nem em 10 tentativas",
    delay: 800
  },
  {
    id: "ana_11",
    sender: "ana",
    type: "text",
    content: "Percebe? Não é forçado. Não é cantada brega. É só... a coisa certa na hora certa.",
    delay: 2000,
    typingDuration: 2200
  },
  {
    id: "ana_12",
    sender: "ana",
    type: "text",
    content: "Quer ver o que acontece quando você usa isso consistentemente?",
    delay: 1500,
    typingDuration: 1800
  },
  {
    id: "btn_mostra",
    sender: "system",
    type: "button",
    content: "MOSTRA",
    delay: 500
  },

  // ============================================
  // PARTE 4: PROVA SOCIAL
  // ============================================
  {
    id: "ana_13",
    sender: "ana",
    type: "text",
    content: "Olha esses resultados reais:",
    delay: 1000,
    typingDuration: 1000
  },
  {
    id: "proof_1",
    sender: "ana",
    type: "image",
    content: "Conversa que virou date",
    imageUrl: "/assets/images/proofs/print_conversa_01.png",
    delay: 1500
  },
  {
    id: "proof_2",
    sender: "ana",
    type: "image",
    content: "Recuperou conversa fria",
    imageUrl: "/assets/images/proofs/print_conversa_02.png",
    delay: 2000
  },
  {
    id: "proof_3",
    sender: "ana",
    type: "image",
    content: "Conseguiu o número",
    imageUrl: "/assets/images/proofs/print_conversa_03.png",
    delay: 2000
  },
  {
    id: "ana_14",
    sender: "ana",
    type: "text",
    content: "Isso é o que acontece quando você para de adivinhar e começa a SABER o que funciona.",
    delay: 2000,
    typingDuration: 2500
  },

  // ============================================
  // PARTE 5: REVELAÇÃO
  // ============================================
  {
    id: "ana_15",
    sender: "ana",
    type: "text",
    content: "Agora a parte que o Code não queria que eu contasse...",
    delay: 2500,
    typingDuration: 1800
  },
  {
    id: "ana_16",
    sender: "ana",
    type: "text",
    content: "Tudo que eu te mandei até agora...",
    delay: 2000,
    typingDuration: 1200
  },
  {
    id: "ana_17",
    sender: "ana",
    type: "text",
    content: "O tom. As respostas. O timing.",
    delay: 1500,
    typingDuration: 1000
  },
  {
    id: "ana_18",
    sender: "ana",
    type: "text",
    content: "Foi o sistema dele me guiando.",
    delay: 1500,
    typingDuration: 1000
  },
  {
    id: "ana_19",
    sender: "ana",
    type: "text",
    content: "Você acabou de conversar com a ferramenta sem perceber.",
    delay: 2500,
    typingDuration: 1800
  },
  {
    id: "ana_20",
    sender: "ana",
    type: "text",
    content: "E funcionou, não funcionou?",
    delay: 2000,
    typingDuration: 1200
  },
  {
    id: "ana_21",
    sender: "ana",
    type: "text",
    content: "Você respondeu. Você engajou. Você ficou até aqui.",
    delay: 2000,
    typingDuration: 1500
  },
  {
    id: "ana_22",
    sender: "ana",
    type: "text",
    content: "Imagina ter isso em TODA conversa. Todo match. Toda oportunidade.",
    delay: 2500,
    typingDuration: 2000
  },
  {
    id: "ana_23",
    sender: "ana",
    type: "text",
    content: "O Code me autorizou a liberar o acesso pra quem chegasse até aqui.",
    delay: 2000,
    typingDuration: 2000
  },
  {
    id: "ana_24",
    sender: "ana",
    type: "text",
    content: "Você chegou. 🔓",
    delay: 1500,
    typingDuration: 800
  },
  {
    id: "btn_final",
    sender: "system",
    type: "button",
    content: "QUERO MEU ACESSO",
    delay: 1000
  }
];

// Configurações do chat
export const chatConfig = {
  // Avatar da Ana
  anaAvatar: "/assets/images/avatars/ana_avatar.png",
  anaName: "Ana",

  // Avatar da Mina (simulação)
  minaAvatar: "/assets/images/avatars/mina_tinder.png",
  minaName: "Mina do Tinder 🔥",

  // Delays padrão
  defaultTypingDuration: 1000,
  defaultMessageDelay: 1000,

  // Som de notificação
  notificationSound: "/assets/audios/effects/notificacao_msg.mp3",

  // Cores
  anaBubbleColor: "#075E54", // Verde WhatsApp
  minaBubbleColor: "#128C7E",
  userBubbleColor: "#DCF8C6",
  suggestionColor: "#A855F7" // Roxo Desenrola
};

export default chatScript;

/**
 * Script do áudio do Code
 * Duração estimada: 45-60 segundos
 *
 * TOM: Urgente mas genuíno. Não forçado. Como um amigo te ligando com pressa.
 * AMBIENTE: Leve ruído de fundo (parece ligação real)
 * QUALIDADE: Levemente comprimido (128kbps) para parecer telefone
 */

export const codeScript = {
  duracao: "45-60 segundos",
  tom: "Urgente, genuíno, como amigo com pressa",

  texto: `
[Som de conexão - 1s]

E aí... que bom que atendeu.

Preciso falar rápido, não tenho muito tempo.

[Pausa 1s]

Eu desenvolvi uma tecnologia... algo diferente de tudo que você já viu.
Vai ser uma verdadeira revolução.

E os coaches de relacionamento, os apps de namoro...
eles tão fazendo de TUDO pra me derrubar.
Chegaram até a contratar hackers pra me atacar.

Por isso essa ligação pode cair a qualquer hora.

Se isso acontecer, preciso que você ligue pra Ana.

O número é 345 9450-4335. Anota.

[Pausa 2s - dar tempo de "anotar"]

Eu tava cansado, mano.
Cansado de tomar vacuo.
Cansado de joguinho.
Cansado de me sentir REFÉM desses apps,
pagando e nunca conseguindo resultado nenhum.

Aí eu criei uma coisa que--

[Estática começa sutil, aumenta]

Merda. A ligação tá caindo.

Lembra, rápido. Liga pra Ana.

O número é 345 9450-4335.

Liga pra ela que ela te expli--

[Pi... pi... pi... - corte abrupto]
`,

  // Marcações de tempo para edição
  timestamps: {
    inicio: "0:00",
    conexao: "0:00 - 0:01",
    abertura: "0:01 - 0:04",
    tecnologia: "0:05 - 0:12",
    inimigos: "0:12 - 0:22",
    numero_ana: "0:22 - 0:28",
    pausa_anotar: "0:28 - 0:30",
    dor: "0:30 - 0:42",
    interrupcao: "0:42 - 0:45",
    estatica_inicio: "0:42",
    despedida: "0:45 - 0:50",
    corte: "0:50"
  },

  // Efeitos necessários
  efeitos: [
    { tempo: "0:00", efeito: "Som de conexão de chamada" },
    { tempo: "0:42", efeito: "Estática/interferência começa sutil" },
    { tempo: "0:45", efeito: "Estática aumenta" },
    { tempo: "0:50", efeito: "Pi pi pi - chamada cai" }
  ],

  // Dicas de gravação
  dicasGravacao: [
    "Gravar em ambiente silencioso",
    "Usar pop filter para evitar estalos",
    "Manter tom de urgência sem parecer forçado",
    "Pausas são importantes - não correr",
    "A parte 'Merda' pode ser mais intensa",
    "Final deve soar cortado abruptamente"
  ]
};

export default codeScript;

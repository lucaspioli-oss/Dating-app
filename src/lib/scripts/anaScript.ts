/**
 * Script do áudio da Ana
 * Duração estimada: 90-120 segundos
 *
 * TOM: Começa confusa/desconfiada, depois confiante e misteriosa
 * AMBIENTE: Mais limpo que o Code, mas ainda parecer ligação
 * EMOÇÃO: Transmitir que ela SABE algo importante
 */

export const anaScript = {
  duracao: "90-120 segundos",
  tom: "Confusa → Confiante → Misteriosa",

  texto: `
[Tu... tu... tu... - som de chamando - 3 toques]

[Atende]

Alô?... Alôou?...

[Pausa 2s - como se estivesse processando]

Interessante.

Só uma pessoa tinha esse número.

E eu sei que se você tá ligando agora...
é porque atacaram o Code de novo.

[Suspiro]

Espero que dessa vez ele esteja bem.

[Pausa 1s]

Vamos lá.

Aqui é a Ana.

E você acabou de entrar em algo que não tem mais volta.

[Tom muda - mais sério, mais intenso]

Presta muita atenção.

Nos últimos meses, o Code hackeou toda a psicologia de relacionamentos.

Ele transformou milhares de conversas e perfis em dados.

Identificou padrões que são ocultos aos olhos humanos.

Mapeou estratégias específicas pra cada padrão.

[Pausa 1s - deixar absorver]

Quando ele testou... aí veio a surpresa.

2 mulheres.
Pedindo pra SAIR COM ELE.
Em menos de 1 semana.

[Tom de revelação]

Ele percebeu que tinha uma chave dourada nas mãos.

Algo que não podia guardar só pra ele.

[Tom mais pesado]

Mas também...
algo que podia ser uma arma na mão da pessoa errada.

Ele pensou muito se deveria disponibilizar.

Considerou os estragos que isso poderia gerar.

[Pausa dramática 2s]

Mas ele decidiu que o cara certo merecia ter acesso.

[Tom mais leve, quase acolhedor]

E se você chegou até aqui...

talvez você seja esse cara.

[Pausa 1s]

Mas antes de eu te mostrar qualquer coisa,
preciso saber se você tá pronto pra isso.

Vou te mandar uma mensagem.

Me responde lá.

[Tom final - confiante]

[Chamada encerra suavemente - não abrupto como o Code]
`,

  // Marcações de tempo para edição
  timestamps: {
    chamando: "0:00 - 0:05",
    atende_confusa: "0:05 - 0:10",
    reconhecimento: "0:10 - 0:20",
    suspiro: "0:20 - 0:22",
    apresentacao: "0:22 - 0:30",
    tom_serio: "0:30 - 0:32",
    explicacao_code: "0:32 - 0:55",
    resultado: "0:55 - 1:05",
    chave_dourada: "1:05 - 1:15",
    dilema: "1:15 - 1:25",
    pausa_dramatica: "1:25 - 1:27",
    decisao: "1:27 - 1:35",
    voce_e_o_cara: "1:35 - 1:45",
    proximo_passo: "1:45 - 1:55",
    encerra: "1:55 - 2:00"
  },

  // Mudanças de tom
  mudancasTom: [
    { tempo: "0:05", tom: "Confusa, desconfiada" },
    { tempo: "0:22", tom: "Mais séria, misteriosa" },
    { tempo: "0:32", tom: "Intensa, importante" },
    { tempo: "0:55", tom: "Revelação, impacto" },
    { tempo: "1:05", tom: "Peso, responsabilidade" },
    { tempo: "1:27", tom: "Decisão tomada" },
    { tempo: "1:35", tom: "Acolhedor, confiante" },
    { tempo: "1:45", tom: "Direcionamento claro" }
  ],

  // Dicas de gravação
  dicasGravacao: [
    "O 'Alô?... Alôou?' deve soar genuinamente confuso",
    "O suspiro é importante - transmite preocupação real",
    "Pausas dramáticas são essenciais - não pular",
    "A parte '2 mulheres pedindo pra sair' deve ter impacto",
    "O dilema moral deve soar pesado, não dramático demais",
    "Final deve ser confiante mas não vendedor",
    "Encerrar de forma suave, não abrupta"
  ],

  // Palavras com ênfase
  enfases: [
    "não tem mais volta",
    "hackeou",
    "ocultos aos olhos humanos",
    "2 mulheres",
    "SAIR COM ELE",
    "chave dourada",
    "arma",
    "o cara certo"
  ]
};

export default anaScript;

/// Pre-made conversation templates for common dating scenarios.
///
/// Each template is a sequence of objectives the user can follow
/// step-by-step, with tips and example messages per step.

class ConversationTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<TemplateStep> steps;

  const ConversationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.steps,
  });
}

class TemplateStep {
  final int order;
  final String title;
  final String objective;
  final String tip;
  final String exampleMessage;

  const TemplateStep({
    required this.order,
    required this.title,
    required this.objective,
    required this.tip,
    required this.exampleMessage,
  });
}

const List<ConversationTemplate> kTemplates = [
  ConversationTemplate(
    id: 'get_number',
    name: 'Pegar o Numero',
    icon: '\u{1F4F1}',
    description: 'Saia do app de dating pro WhatsApp em 3 passos',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Criar conexao',
        objective: 'criar_conexao',
        tip: 'Encontre algo em comum no perfil dela e puxe assunto sobre isso',
        exampleMessage: 'Vi que vc curte trilha! Qual foi a melhor que vc ja fez?',
      ),
      TemplateStep(
        order: 2,
        title: 'Gerar conforto',
        objective: 'automatico',
        tip: 'Mantenha a conversa fluindo por 3-5 mensagens antes de pedir o numero',
        exampleMessage: 'Kkk demais, eu tambem sou assim. A gente devia trocar umas dicas',
      ),
      TemplateStep(
        order: 3,
        title: 'Pedir o numero',
        objective: 'pegar_numero',
        tip: 'Seja direto e natural. Sugira continuar a conversa no WhatsApp',
        exampleMessage: 'Bora continuar essa conversa no whats? Manda teu numero ai',
      ),
    ],
  ),
  ConversationTemplate(
    id: 'first_date',
    name: 'Marcar o Encontro',
    icon: '\u{2615}',
    description: 'Do match ao primeiro date em 4 passos',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Abrir a conversa',
        objective: 'automatico',
        tip: 'Primeira mensagem criativa baseada no perfil, nao so "oi"',
        exampleMessage: 'Aquela foto no Japao ficou demais! Vc foi sozinha ou em grupo?',
      ),
      TemplateStep(
        order: 2,
        title: 'Criar conexao',
        objective: 'criar_conexao',
        tip: 'Descubra interesses em comum e construa rapport',
        exampleMessage: 'Serio que vc curte comida japonesa? Eu sou viciado em ramen',
      ),
      TemplateStep(
        order: 3,
        title: 'Mudar pra WhatsApp',
        objective: 'mudar_plataforma',
        tip: 'Antes de marcar o encontro, migre pro WhatsApp pra facilitar',
        exampleMessage: 'Melhor a gente continuar no whats ne? La eh mais facil combinar',
      ),
      TemplateStep(
        order: 4,
        title: 'Marcar o date',
        objective: 'marcar_encontro',
        tip: 'Sugira lugar e horario especificos. Nao deixe em aberto',
        exampleMessage: 'Bora naquele ramen da Liberdade sabado? Tipo 19h?',
      ),
    ],
  ),
  ConversationTemplate(
    id: 'revive_cold',
    name: 'Reacender Conversa',
    icon: '\u{1F525}',
    description: 'Resgate uma conversa que esfriou',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Callback criativo',
        objective: 'reacender',
        tip: 'Referencie algo que vcs conversaram antes. Mostra que vc lembra',
        exampleMessage: 'E ai, conseguiu terminar aquela serie que vc tava vendo?',
      ),
      TemplateStep(
        order: 2,
        title: 'Manter o ritmo',
        objective: 'automatico',
        tip: 'Se ela responder, mantenha leve e nao cobre a demora',
        exampleMessage: 'Kkk sabia que vc ia gostar do final. E essa semana, muita correria?',
      ),
      TemplateStep(
        order: 3,
        title: 'Escalar rapido',
        objective: 'marcar_encontro',
        tip: 'Nao deixe esfriar de novo. Sugira algo logo',
        exampleMessage: 'Bora tomar um cafe essa semana? Quarta ou quinta vc consegue?',
      ),
    ],
  ),
  ConversationTemplate(
    id: 'instagram_to_date',
    name: 'Instagram pro Date',
    icon: '\u{1F4F8}',
    description: 'Da DM do Instagram ate o encontro',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Responder story',
        objective: 'automatico',
        tip: 'Responda um story de forma especifica, nao generica',
        exampleMessage: 'Esse lugar parece incrivel! Onde eh isso?',
      ),
      TemplateStep(
        order: 2,
        title: 'Desenvolver conversa',
        objective: 'criar_conexao',
        tip: 'Aprofunde no assunto do story e descubra coisas em comum',
        exampleMessage: 'Ah eu amo praia tambem! Qual a melhor que vc ja foi?',
      ),
      TemplateStep(
        order: 3,
        title: 'Pegar o numero',
        objective: 'pegar_numero',
        tip: 'Migre pro WhatsApp antes de propor encontro',
        exampleMessage: 'To curtindo demais essa conversa. Me passa teu whats?',
      ),
      TemplateStep(
        order: 4,
        title: 'Marcar de sair',
        objective: 'marcar_encontro',
        tip: 'Proponha algo relacionado ao que vcs conversaram',
        exampleMessage: 'Ja que a gente curte praia, bora no Guaruja esse fds?',
      ),
    ],
  ),
  ConversationTemplate(
    id: 'video_call',
    name: 'Marcar Video Call',
    icon: '\u{1F4F9}',
    description: 'Proponha uma chamada de video antes de se encontrar',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Criar conforto',
        objective: 'criar_conexao',
        tip: 'Garanta que a conversa esta fluindo bem antes de propor video',
        exampleMessage: 'Cara, to adorando conversar contigo. Vc eh muito gente boa',
      ),
      TemplateStep(
        order: 2,
        title: 'Propor o video',
        objective: 'video_call',
        tip: 'Sugira de forma leve, sem pressao. Diga que quer "ver o sorriso"',
        exampleMessage: 'Bora fazer uma call? Quero ver se vc eh tao legal ao vivo quanto por msg kkk',
      ),
    ],
  ),
  ConversationTemplate(
    id: 'apologize',
    name: 'Pedir Desculpas',
    icon: '\u{1F64F}',
    description: 'Recupere apos uma gafe ou resposta ruim',
    steps: [
      TemplateStep(
        order: 1,
        title: 'Reconhecer o erro',
        objective: 'pedir_desculpas',
        tip: 'Seja sincero e breve. Nao se justifique demais',
        exampleMessage: 'Mals por aquela mensagem, saiu errado. Quis dizer outra coisa',
      ),
      TemplateStep(
        order: 2,
        title: 'Mudar o assunto',
        objective: 'automatico',
        tip: 'Depois de pedir desculpas, mude pra um assunto leve',
        exampleMessage: 'Enfim kkk me conta, como foi seu fds?',
      ),
    ],
  ),
];

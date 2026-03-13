import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desenrola AI'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu assistente inteligente de conversas'**
  String get appSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Desenrola AI!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu assistente inteligente para conversas'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Vamos te mostrar como usar o app para nunca mais ficar sem assunto nas suas conversas.'**
  String get welcomeDescription;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta!'**
  String get welcomeBackTitle;

  /// No description provided for @createProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie um Perfil'**
  String get createProfileTitle;

  /// No description provided for @createProfileSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Para cada pessoa que você conversa'**
  String get createProfileSubtitle;

  /// No description provided for @createProfileDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicione informações sobre quem você está conversando para receber sugestões mais personalizadas.'**
  String get createProfileDescription;

  /// No description provided for @tutorialStep1.
  ///
  /// In pt, this message translates to:
  /// **'Toque no botão + na tela de Contatos'**
  String get tutorialStep1;

  /// No description provided for @tutorialStep2.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a plataforma (Tinder, Bumble, Instagram, WhatsApp...)'**
  String get tutorialStep2;

  /// No description provided for @tutorialStep3.
  ///
  /// In pt, this message translates to:
  /// **'Preencha o nome e as informações do perfil'**
  String get tutorialStep3;

  /// No description provided for @addConversationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione a Conversa'**
  String get addConversationTitle;

  /// No description provided for @addConversationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou importe suas mensagens'**
  String get addConversationSubtitle;

  /// No description provided for @addConversationDescription.
  ///
  /// In pt, this message translates to:
  /// **'Para a IA entender o contexto, você precisa adicionar as mensagens da sua conversa.'**
  String get addConversationDescription;

  /// No description provided for @addConvStep1.
  ///
  /// In pt, this message translates to:
  /// **'Abra o perfil do contato e vá em \"Conversas\"'**
  String get addConvStep1;

  /// No description provided for @addConvStep2.
  ///
  /// In pt, this message translates to:
  /// **'Tire um print da conversa ou importe do WhatsApp'**
  String get addConvStep2;

  /// No description provided for @addConvStep3.
  ///
  /// In pt, this message translates to:
  /// **'A IA analisa o histórico e entende o contexto'**
  String get addConvStep3;

  /// No description provided for @useKeyboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Use o Teclado Inteligente'**
  String get useKeyboardTitle;

  /// No description provided for @useKeyboardSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O segredo está aqui!'**
  String get useKeyboardSubtitle;

  /// No description provided for @useKeyboardDescription.
  ///
  /// In pt, this message translates to:
  /// **'O teclado Desenrola AI funciona dentro de qualquer app de mensagens. Ele é o jeito mais rápido de receber sugestões.'**
  String get useKeyboardDescription;

  /// No description provided for @keyboardStep1.
  ///
  /// In pt, this message translates to:
  /// **'Troque para o teclado Desenrola (globo 🌐)'**
  String get keyboardStep1;

  /// No description provided for @keyboardStep2.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o contato certo no teclado'**
  String get keyboardStep2;

  /// No description provided for @keyboardStep3.
  ///
  /// In pt, this message translates to:
  /// **'Copie as mensagens novas que você recebeu'**
  String get keyboardStep3;

  /// No description provided for @keyboardStep4.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma sugestão e toque em \"Inserir\"'**
  String get keyboardStep4;

  /// No description provided for @keyboardTip.
  ///
  /// In pt, this message translates to:
  /// **'Sempre envie suas respostas pelo teclado Desenrola! Assim a IA registra o que você enviou e melhora as sugestões futuras.'**
  String get keyboardTip;

  /// No description provided for @multipleMessagesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Várias Mensagens?'**
  String get multipleMessagesTitle;

  /// No description provided for @multipleMessagesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole uma por uma!'**
  String get multipleMessagesSubtitle;

  /// No description provided for @multipleMessagesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Se a pessoa mandou várias mensagens seguidas, use o modo de múltiplas mensagens do teclado.'**
  String get multipleMessagesDescription;

  /// No description provided for @multiMsgStep1.
  ///
  /// In pt, this message translates to:
  /// **'No teclado, toque em \"Recebeu várias mensagens?\"'**
  String get multiMsgStep1;

  /// No description provided for @multiMsgStep2.
  ///
  /// In pt, this message translates to:
  /// **'Copie a 1ª mensagem no app e toque em \"Mensagem 1\" para colar'**
  String get multiMsgStep2;

  /// No description provided for @multiMsgStep3.
  ///
  /// In pt, this message translates to:
  /// **'Repita para cada mensagem. Use o \"+\" se precisar de mais campos'**
  String get multiMsgStep3;

  /// No description provided for @multiMsgStep4.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Gerar Respostas\" para receber sugestões'**
  String get multiMsgStep4;

  /// No description provided for @multiMsgTip.
  ///
  /// In pt, this message translates to:
  /// **'A IA recebe todas as mensagens de uma vez e entende o contexto completo para gerar a melhor resposta!'**
  String get multiMsgTip;

  /// No description provided for @readyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo Pronto!'**
  String get readyTitle;

  /// No description provided for @readySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Comece a desenrolar'**
  String get readySubtitle;

  /// No description provided for @readyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Agora você já sabe o básico. Adicione seu primeiro contato e comece a receber sugestões personalizadas!'**
  String get readyDescription;

  /// No description provided for @readyTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica: você pode rever este tutorial a qualquer momento nas Configurações do app.'**
  String get readyTip;

  /// No description provided for @skipButton.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get skipButton;

  /// No description provided for @backButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get backButton;

  /// No description provided for @nextButton.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get nextButton;

  /// No description provided for @cancelButton.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

  /// No description provided for @saveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get saveButton;

  /// No description provided for @startUsingButton.
  ///
  /// In pt, this message translates to:
  /// **'Começar a usar!'**
  String get startUsingButton;

  /// No description provided for @letsGoButton.
  ///
  /// In pt, this message translates to:
  /// **'Vamos lá!'**
  String get letsGoButton;

  /// No description provided for @retryButton.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retryButton;

  /// No description provided for @featureAdvancedAI.
  ///
  /// In pt, this message translates to:
  /// **'IA Avançada'**
  String get featureAdvancedAI;

  /// No description provided for @featureFastResponses.
  ///
  /// In pt, this message translates to:
  /// **'Respostas Rápidas'**
  String get featureFastResponses;

  /// No description provided for @featureCustomTones.
  ///
  /// In pt, this message translates to:
  /// **'Tons Personalizados'**
  String get featureCustomTones;

  /// No description provided for @featureMultiPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Multi-plataforma'**
  String get featureMultiPlatform;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Faça login para continuar'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In pt, this message translates to:
  /// **'seu@email.com'**
  String get emailHint;

  /// No description provided for @emailValidationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu email'**
  String get emailValidationEmpty;

  /// No description provided for @emailValidationInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get emailValidationInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha'**
  String get passwordHint;

  /// No description provided for @passwordValidationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha'**
  String get passwordValidationEmpty;

  /// No description provided for @passwordValidationMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Senha deve ter no mínimo 6 caracteres'**
  String get passwordValidationMinLength;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a senha?'**
  String get forgotPasswordButton;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// No description provided for @orDivider.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get orDivider;

  /// No description provided for @noAccountText.
  ///
  /// In pt, this message translates to:
  /// **'Não tem uma conta?'**
  String get noAccountText;

  /// No description provided for @signupLink.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get signupLink;

  /// No description provided for @emailRequiredInfo.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu email primeiro'**
  String get emailRequiredInfo;

  /// No description provided for @passwordResetSent.
  ///
  /// In pt, this message translates to:
  /// **'Email enviado para'**
  String get passwordResetSent;

  /// No description provided for @loginSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Login realizado com sucesso!'**
  String get loginSuccess;

  /// No description provided for @createAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Comece sua jornada no Desenrola AI'**
  String get signupSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In pt, this message translates to:
  /// **'Como podemos te chamar?'**
  String get nameHint;

  /// No description provided for @nameValidationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu nome'**
  String get nameValidationEmpty;

  /// No description provided for @nameValidationMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Nome muito curto'**
  String get nameValidationMinLength;

  /// No description provided for @passwordHintMinChars.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordHintMinChars;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite a senha novamente'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordValidationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha'**
  String get confirmPasswordValidationEmpty;

  /// No description provided for @passwordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get passwordMismatch;

  /// No description provided for @acceptTermsError.
  ///
  /// In pt, this message translates to:
  /// **'Aceite os termos de uso'**
  String get acceptTermsError;

  /// No description provided for @termsPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Aceito os'**
  String get termsPrefix;

  /// No description provided for @termsLink.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get termsLink;

  /// No description provided for @andConjunction.
  ///
  /// In pt, this message translates to:
  /// **'e'**
  String get andConjunction;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicyLink;

  /// No description provided for @createAccountButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get createAccountButton;

  /// No description provided for @hasAccountText.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get hasAccountText;

  /// No description provided for @loginLink.
  ///
  /// In pt, this message translates to:
  /// **'Fazer login'**
  String get loginLink;

  /// No description provided for @signupSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta criada com sucesso!'**
  String get signupSuccess;

  /// No description provided for @conversationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conversas'**
  String get conversationsTitle;

  /// No description provided for @yesterdayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get yesterdayLabel;

  /// No description provided for @daysAgoLabel.
  ///
  /// In pt, this message translates to:
  /// **'d atrás'**
  String get daysAgoLabel;

  /// No description provided for @noConversationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conversa ainda'**
  String get noConversationsTitle;

  /// No description provided for @noConversationsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Vá para \"Contatos\" e gere uma sugestão para começar!'**
  String get noConversationsDescription;

  /// No description provided for @messageInputQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer informar a mensagem dela?'**
  String get messageInputQuestion;

  /// No description provided for @messageInputInfo.
  ///
  /// In pt, this message translates to:
  /// **'A IA vai analisar e sugerir respostas'**
  String get messageInputInfo;

  /// No description provided for @uploadScreenshotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Upload do print'**
  String get uploadScreenshotTitle;

  /// No description provided for @uploadScreenshotSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Envie um screenshot da conversa'**
  String get uploadScreenshotSubtitle;

  /// No description provided for @typeMessageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Digitar a mensagem'**
  String get typeMessageTitle;

  /// No description provided for @typeMessageSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite o que ela enviou'**
  String get typeMessageSubtitle;

  /// No description provided for @importWhatsAppTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar WhatsApp'**
  String get importWhatsAppTitle;

  /// No description provided for @importWhatsAppSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole o texto exportado da conversa'**
  String get importWhatsAppSubtitle;

  /// No description provided for @ocrFailureMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível extrair o texto'**
  String get ocrFailureMessage;

  /// No description provided for @analyzingImageText.
  ///
  /// In pt, this message translates to:
  /// **'Analisando imagem...'**
  String get analyzingImageText;

  /// No description provided for @extractingTextInfo.
  ///
  /// In pt, this message translates to:
  /// **'Extraindo texto da conversa'**
  String get extractingTextInfo;

  /// No description provided for @confirmMessageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirme a mensagem'**
  String get confirmMessageTitle;

  /// No description provided for @herMessageTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que ela disse?'**
  String get herMessageTitle;

  /// No description provided for @herMessageInfo.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite a última mensagem que ela enviou'**
  String get herMessageInfo;

  /// No description provided for @herMessageHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: \"Haha verdade! E você, o que gosta de fazer?\"'**
  String get herMessageHint;

  /// No description provided for @messageInputHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite a mensagem...'**
  String get messageInputHint;

  /// No description provided for @importConversationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar conversa do WhatsApp'**
  String get importConversationTitle;

  /// No description provided for @whatsappInstructions.
  ///
  /// In pt, this message translates to:
  /// **'No WhatsApp: Abra a conversa > Menu (⋮) > Mais > Exportar conversa > Sem mídia > Copie o texto e cole aqui.'**
  String get whatsappInstructions;

  /// No description provided for @pasteConversationHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole a conversa exportada aqui...'**
  String get pasteConversationHint;

  /// No description provided for @generateSuggestionsButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Sugestões'**
  String get generateSuggestionsButton;

  /// No description provided for @whatsappParseError.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma mensagem encontrada. Verifique o formato.'**
  String get whatsappParseError;

  /// No description provided for @messagesImportedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'mensagens importadas!'**
  String get messagesImportedSuccess;

  /// No description provided for @importError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao importar:'**
  String get importError;

  /// No description provided for @messageSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem registrada!'**
  String get messageSavedSuccess;

  /// No description provided for @copiedNotification.
  ///
  /// In pt, this message translates to:
  /// **'Copiado!'**
  String get copiedNotification;

  /// No description provided for @loadingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loadingTitle;

  /// No description provided for @errorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get errorTitle;

  /// No description provided for @conversationNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Conversa não encontrada'**
  String get conversationNotFound;

  /// No description provided for @emptyConversationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comece a conversa!'**
  String get emptyConversationTitle;

  /// No description provided for @emptyConversationInfo.
  ///
  /// In pt, this message translates to:
  /// **'Clique no botão 💫 para gerar\nsugestões de resposta'**
  String get emptyConversationInfo;

  /// No description provided for @sheSaidLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ela disse:'**
  String get sheSaidLabel;

  /// No description provided for @aiSuggestionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão IA'**
  String get aiSuggestionLabel;

  /// No description provided for @messageInputPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Sua mensagem...'**
  String get messageInputPlaceholder;

  /// No description provided for @suggestionsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões de resposta'**
  String get suggestionsHeader;

  /// No description provided for @copyButtonText.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get copyButtonText;

  /// No description provided for @useButtonText.
  ///
  /// In pt, this message translates to:
  /// **'Usar'**
  String get useButtonText;

  /// No description provided for @deleteConversationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conversa'**
  String get deleteConversationTitle;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conversa com'**
  String get deleteConversationConfirm;

  /// No description provided for @bioLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @analyticsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Analytics'**
  String get analyticsLabel;

  /// No description provided for @messagesAnalytic.
  ///
  /// In pt, this message translates to:
  /// **'Mensagens'**
  String get messagesAnalytic;

  /// No description provided for @aiSuggestionsAnalytic.
  ///
  /// In pt, this message translates to:
  /// **'IA usadas'**
  String get aiSuggestionsAnalytic;

  /// No description provided for @qualityAnalytic.
  ///
  /// In pt, this message translates to:
  /// **'Qualidade'**
  String get qualityAnalytic;

  /// No description provided for @developerFeedbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Feedback das sugestões'**
  String get developerFeedbackTitle;

  /// No description provided for @feedbackGood.
  ///
  /// In pt, this message translates to:
  /// **'Bom'**
  String get feedbackGood;

  /// No description provided for @feedbackPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get feedbackPartial;

  /// No description provided for @feedbackBad.
  ///
  /// In pt, this message translates to:
  /// **'Ruim'**
  String get feedbackBad;

  /// No description provided for @feedbackSentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Feedback enviado!'**
  String get feedbackSentSuccess;

  /// No description provided for @feedbackSentError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar'**
  String get feedbackSentError;

  /// No description provided for @newProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Perfil'**
  String get newProfileTitle;

  /// No description provided for @analyzingProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Analisando perfil...'**
  String get analyzingProfileTitle;

  /// No description provided for @extractingInfoMessage.
  ///
  /// In pt, this message translates to:
  /// **'Extraindo informações das imagens'**
  String get extractingInfoMessage;

  /// No description provided for @selectPlatformTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a rede social'**
  String get selectPlatformTitle;

  /// No description provided for @platformQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Onde você conheceu essa pessoa?'**
  String get platformQuestion;

  /// No description provided for @profileScreenshotMode.
  ///
  /// In pt, this message translates to:
  /// **'Print do Perfil'**
  String get profileScreenshotMode;

  /// No description provided for @profileScreenshotDesc.
  ///
  /// In pt, this message translates to:
  /// **'Um print geral\ndo perfil dela'**
  String get profileScreenshotDesc;

  /// No description provided for @profilePhotosMode.
  ///
  /// In pt, this message translates to:
  /// **'Fotos Individuais'**
  String get profilePhotosMode;

  /// No description provided for @profilePhotosDesc.
  ///
  /// In pt, this message translates to:
  /// **'Adicione as fotos\numa por uma'**
  String get profilePhotosDesc;

  /// No description provided for @changeMode.
  ///
  /// In pt, this message translates to:
  /// **'Trocar modo'**
  String get changeMode;

  /// No description provided for @addProfileScreenshot.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar print do perfil'**
  String get addProfileScreenshot;

  /// No description provided for @screenshotInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Tire um print da página do perfil dela no Instagram'**
  String get screenshotInstructions;

  /// No description provided for @screenshotAutoFillHint.
  ///
  /// In pt, this message translates to:
  /// **'A IA extrai nome, bio, idade e interesses automaticamente'**
  String get screenshotAutoFillHint;

  /// No description provided for @croppedProfilePicLabel.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil\n(recorte automático)'**
  String get croppedProfilePicLabel;

  /// No description provided for @profilePhotosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fotos do Perfil'**
  String get profilePhotosTitle;

  /// No description provided for @profilePhotosDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicione as fotos do perfil dela (pode adicionar várias)'**
  String get profilePhotosDescription;

  /// No description provided for @storiesOptionalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Stories (opcional)'**
  String get storiesOptionalTitle;

  /// No description provided for @storiesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicione stories para usar como contexto nas sugestões'**
  String get storiesDescription;

  /// No description provided for @openingMoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Opening Move (opcional)'**
  String get openingMoveTitle;

  /// No description provided for @openingMoveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Print da pergunta que ela escolheu'**
  String get openingMoveSubtitle;

  /// No description provided for @nameInputHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome dela'**
  String get nameInputHint;

  /// No description provided for @bioInputHint.
  ///
  /// In pt, this message translates to:
  /// **'Bio / descrição do perfil'**
  String get bioInputHint;

  /// No description provided for @storiesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Stories'**
  String get storiesLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'(opcional)'**
  String get optionalLabel;

  /// No description provided for @firstPhotoAvatarInfo.
  ///
  /// In pt, this message translates to:
  /// **'A 1ª foto vira avatar'**
  String get firstPhotoAvatarInfo;

  /// No description provided for @instagramFirstDM.
  ///
  /// In pt, this message translates to:
  /// **'Primeira DM'**
  String get instagramFirstDM;

  /// No description provided for @instagramReplyStory.
  ///
  /// In pt, this message translates to:
  /// **'Responder Story'**
  String get instagramReplyStory;

  /// No description provided for @continueChat.
  ///
  /// In pt, this message translates to:
  /// **'Continuar Conversa'**
  String get continueChat;

  /// No description provided for @respondOpeningMove.
  ///
  /// In pt, this message translates to:
  /// **'Responder Opening Move'**
  String get respondOpeningMove;

  /// No description provided for @firstMessage.
  ///
  /// In pt, this message translates to:
  /// **'Primeira Mensagem'**
  String get firstMessage;

  /// No description provided for @firstDMDescription.
  ///
  /// In pt, this message translates to:
  /// **'Enviar mensagem direta pela primeira vez'**
  String get firstDMDescription;

  /// No description provided for @replyStoryDescription.
  ///
  /// In pt, this message translates to:
  /// **'Responder ao story dela'**
  String get replyStoryDescription;

  /// No description provided for @continueChatDescription.
  ///
  /// In pt, this message translates to:
  /// **'Dar continuidade na conversa'**
  String get continueChatDescription;

  /// No description provided for @respondQuestionDescription.
  ///
  /// In pt, this message translates to:
  /// **'Responder a pergunta dela'**
  String get respondQuestionDescription;

  /// No description provided for @firstMessageBumbleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Ela fez match e você envia primeiro'**
  String get firstMessageBumbleDescription;

  /// No description provided for @firstMessageDescription.
  ///
  /// In pt, this message translates to:
  /// **'Enviar a primeira mensagem'**
  String get firstMessageDescription;

  /// No description provided for @selectPlatformTitle2.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a Plataforma'**
  String get selectPlatformTitle2;

  /// No description provided for @actionSelectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que você quer fazer?'**
  String get actionSelectionTitle;

  /// No description provided for @selectStoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o Story'**
  String get selectStoryTitle;

  /// No description provided for @lastMessageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Última Mensagem Dela'**
  String get lastMessageTitle;

  /// No description provided for @suggestionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões'**
  String get suggestionsTitle;

  /// No description provided for @newSuggestionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Sugestão'**
  String get newSuggestionTitle;

  /// No description provided for @socialNetworksSection.
  ///
  /// In pt, this message translates to:
  /// **'REDES SOCIAIS'**
  String get socialNetworksSection;

  /// No description provided for @datingAppsSection.
  ///
  /// In pt, this message translates to:
  /// **'APPS DE RELACIONAMENTO'**
  String get datingAppsSection;

  /// No description provided for @storiesBadge.
  ///
  /// In pt, this message translates to:
  /// **'stories'**
  String get storiesBadge;

  /// No description provided for @selectStoryInfo.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o story para responder:'**
  String get selectStoryInfo;

  /// No description provided for @storyNoDescription.
  ///
  /// In pt, this message translates to:
  /// **'Story sem descrição'**
  String get storyNoDescription;

  /// No description provided for @openingMoveLabel.
  ///
  /// In pt, this message translates to:
  /// **'Opening Move dela:'**
  String get openingMoveLabel;

  /// No description provided for @questionNotExtracted.
  ///
  /// In pt, this message translates to:
  /// **'Pergunta não extraída'**
  String get questionNotExtracted;

  /// No description provided for @howToInputMessage.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer informar a mensagem dela?'**
  String get howToInputMessage;

  /// No description provided for @screenshotTab.
  ///
  /// In pt, this message translates to:
  /// **'Print'**
  String get screenshotTab;

  /// No description provided for @typeTab.
  ///
  /// In pt, this message translates to:
  /// **'Digitar'**
  String get typeTab;

  /// No description provided for @messageInputHint2.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite a mensagem aqui...'**
  String get messageInputHint2;

  /// No description provided for @customMessageHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua mensagem personalizada...'**
  String get customMessageHint;

  /// No description provided for @selectStoryToReply.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o story para responder:'**
  String get selectStoryToReply;

  /// No description provided for @whatDoYouWant.
  ///
  /// In pt, this message translates to:
  /// **'O que você quer fazer?'**
  String get whatDoYouWant;

  /// No description provided for @howToInformMessage.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer informar a mensagem dela?'**
  String get howToInformMessage;

  /// No description provided for @typeLastMessageSent.
  ///
  /// In pt, this message translates to:
  /// **'Digite a última mensagem que ela enviou:'**
  String get typeLastMessageSent;

  /// No description provided for @pasteOrTypeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite a mensagem aqui...'**
  String get pasteOrTypeMessage;

  /// No description provided for @tapToUploadScreenshot.
  ///
  /// In pt, this message translates to:
  /// **'Toque para enviar print da conversa'**
  String get tapToUploadScreenshot;

  /// No description provided for @aiWillAnalyzeAuto.
  ///
  /// In pt, this message translates to:
  /// **'A IA vai analisar automaticamente'**
  String get aiWillAnalyzeAuto;

  /// No description provided for @generatingSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Gerando sugestões...'**
  String get generatingSuggestions;

  /// No description provided for @analyzingProfileContext.
  ///
  /// In pt, this message translates to:
  /// **'Analisando perfil e contexto'**
  String get analyzingProfileContext;

  /// No description provided for @chooseSuggestion.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma sugestão ou escreva a sua:'**
  String get chooseSuggestion;

  /// No description provided for @generateNewSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Novas Sugestões'**
  String get generateNewSuggestions;

  /// No description provided for @writeOwnMessage.
  ///
  /// In pt, this message translates to:
  /// **'Escrever minha própria mensagem'**
  String get writeOwnMessage;

  /// No description provided for @yourMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua mensagem'**
  String get yourMessage;

  /// No description provided for @useButton.
  ///
  /// In pt, this message translates to:
  /// **'Usar'**
  String get useButton;

  /// No description provided for @copyButton.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get copyButton;

  /// No description provided for @copiedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Copiado!'**
  String get copiedMessage;

  /// No description provided for @myAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha Conta'**
  String get myAccountTitle;

  /// No description provided for @menuTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// No description provided for @myProfileTab.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get myProfileTab;

  /// No description provided for @subscriptionTab.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura'**
  String get subscriptionTab;

  /// No description provided for @basicInfoSection.
  ///
  /// In pt, this message translates to:
  /// **'Informações Básicas'**
  String get basicInfoSection;

  /// No description provided for @interestsSection.
  ///
  /// In pt, this message translates to:
  /// **'Meus Interesses'**
  String get interestsSection;

  /// No description provided for @selectInterestsInfo.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o que você gosta'**
  String get selectInterestsInfo;

  /// No description provided for @selectInterestError.
  ///
  /// In pt, this message translates to:
  /// **'Selecione pelo menos um interesse!'**
  String get selectInterestError;

  /// No description provided for @dislikesSection.
  ///
  /// In pt, this message translates to:
  /// **'Não Gosto de'**
  String get dislikesSection;

  /// No description provided for @avoidTopicsInfo.
  ///
  /// In pt, this message translates to:
  /// **'Evitar esses tópicos nas conversas'**
  String get avoidTopicsInfo;

  /// No description provided for @humorStyleSection.
  ///
  /// In pt, this message translates to:
  /// **'Estilo de Humor'**
  String get humorStyleSection;

  /// No description provided for @relationshipGoalSection.
  ///
  /// In pt, this message translates to:
  /// **'O que você busca?'**
  String get relationshipGoalSection;

  /// No description provided for @aboutYouSection.
  ///
  /// In pt, this message translates to:
  /// **'Sobre Você'**
  String get aboutYouSection;

  /// No description provided for @saveProfileButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Perfil'**
  String get saveProfileButton;

  /// No description provided for @profileSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Perfil salvo com sucesso!'**
  String get profileSavedSuccess;

  /// No description provided for @activeSubscriptionStatus.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura Ativa'**
  String get activeSubscriptionStatus;

  /// No description provided for @inactiveSubscriptionStatus.
  ///
  /// In pt, this message translates to:
  /// **'Sem Assinatura'**
  String get inactiveSubscriptionStatus;

  /// No description provided for @planDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Plano'**
  String get planDetailsTitle;

  /// No description provided for @planLabel.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get planLabel;

  /// No description provided for @statusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @nextBillingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Próxima cobrança'**
  String get nextBillingLabel;

  /// No description provided for @manageSubscriptionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Assinatura'**
  String get manageSubscriptionTitle;

  /// No description provided for @manageSubscriptionButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Assinatura'**
  String get manageSubscriptionButton;

  /// No description provided for @subscribeNowButton.
  ///
  /// In pt, this message translates to:
  /// **'Assinar Agora'**
  String get subscribeNowButton;

  /// No description provided for @subscriptionManagementInfo.
  ///
  /// In pt, this message translates to:
  /// **'Abra Ajustes > Apple ID > Assinaturas para gerenciar.'**
  String get subscriptionManagementInfo;

  /// No description provided for @notLoggedIn.
  ///
  /// In pt, this message translates to:
  /// **'Não logado'**
  String get notLoggedIn;

  /// No description provided for @accountConnected.
  ///
  /// In pt, this message translates to:
  /// **'Conta conectada'**
  String get accountConnected;

  /// No description provided for @genderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gênero'**
  String get genderLabel;

  /// No description provided for @goalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get goalLabel;

  /// No description provided for @bioOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bio (opcional)'**
  String get bioOptionalLabel;

  /// No description provided for @bioAboutYouHint.
  ///
  /// In pt, this message translates to:
  /// **'Conte um pouco sobre você...'**
  String get bioAboutYouHint;

  /// No description provided for @nameInputRequired.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, digite seu nome'**
  String get nameInputRequired;

  /// No description provided for @nameInputQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você gostaria de ser chamado?'**
  String get nameInputQuestion;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @smartKeyboardSection.
  ///
  /// In pt, this message translates to:
  /// **'Teclado Inteligente'**
  String get smartKeyboardSection;

  /// No description provided for @keyboardStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status do Teclado'**
  String get keyboardStatusLabel;

  /// No description provided for @keyboardStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativado'**
  String get keyboardStatusActive;

  /// No description provided for @keyboardStatusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get keyboardStatusInactive;

  /// No description provided for @activateButton.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get activateButton;

  /// No description provided for @viewActivationGuideTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ver guia de ativação'**
  String get viewActivationGuideTitle;

  /// No description provided for @viewActivationGuideDesc.
  ///
  /// In pt, this message translates to:
  /// **'Reveja os passos para configurar o teclado'**
  String get viewActivationGuideDesc;

  /// No description provided for @viewAppTutorialTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ver tutorial do app'**
  String get viewAppTutorialTitle;

  /// No description provided for @viewAppTutorialDesc.
  ///
  /// In pt, this message translates to:
  /// **'Como usar o Desenrola AI passo a passo'**
  String get viewAppTutorialDesc;

  /// No description provided for @aiTrainingSection.
  ///
  /// In pt, this message translates to:
  /// **'Treinamento da IA'**
  String get aiTrainingSection;

  /// No description provided for @devBadge.
  ///
  /// In pt, this message translates to:
  /// **'DEV'**
  String get devBadge;

  /// No description provided for @trainingInstructionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Instruções de Treinamento'**
  String get trainingInstructionsTitle;

  /// No description provided for @trainingInstructionsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Personalize como a IA responde'**
  String get trainingInstructionsDesc;

  /// No description provided for @aboutSection.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get aboutSection;

  /// No description provided for @loggedAsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Logado como'**
  String get loggedAsLabel;

  /// No description provided for @notLoggedInLabel.
  ///
  /// In pt, this message translates to:
  /// **'Não logado'**
  String get notLoggedInLabel;

  /// No description provided for @versionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get versionLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicyLabel;

  /// No description provided for @logoutLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get logoutLabel;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Deletar conta'**
  String get deleteAccountLabel;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In pt, this message translates to:
  /// **'Remove sua conta e todos os dados permanentemente'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Conta'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja deletar sua conta? Esta ação é permanente e todos os seus dados serão removidos. Esta ação não pode ser desfeita.'**
  String get deleteAccountConfirmation;

  /// No description provided for @deletePermanentlyButton.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Permanentemente'**
  String get deletePermanentlyButton;

  /// No description provided for @logoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja sair?'**
  String get logoutConfirmation;

  /// No description provided for @logoutButton.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logoutButton;

  /// No description provided for @trainingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Treinamento IA'**
  String get trainingTitle;

  /// No description provided for @newInstructionButton.
  ///
  /// In pt, this message translates to:
  /// **'Nova Instrução'**
  String get newInstructionButton;

  /// No description provided for @instructionSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Instrução salva com sucesso!'**
  String get instructionSavedSuccess;

  /// No description provided for @instructionSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar instrução'**
  String get instructionSaveError;

  /// No description provided for @categoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get categoryLabel;

  /// No description provided for @instructionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Instrução'**
  String get instructionLabel;

  /// No description provided for @instructionHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Use humor sutil ao invés de elogios diretos'**
  String get instructionHint;

  /// No description provided for @examplesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Exemplos (um por linha, opcional)'**
  String get examplesLabel;

  /// No description provided for @examplesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: \"quer roubar meu moletom?\"\n\"tô no mercado, quer algo?\"'**
  String get examplesHint;

  /// No description provided for @priorityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get priorityLabel;

  /// No description provided for @instructionUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Instrução atualizada!'**
  String get instructionUpdatedSuccess;

  /// No description provided for @instructionUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar'**
  String get instructionUpdateError;

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão'**
  String get deleteConfirmationTitle;

  /// No description provided for @instructionDeletedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Instrução excluída'**
  String get instructionDeletedSuccess;

  /// No description provided for @newTrainingInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Nova Instrução de Treinamento'**
  String get newTrainingInstruction;

  /// No description provided for @instructionRequired.
  ///
  /// In pt, this message translates to:
  /// **'A instrução é obrigatória'**
  String get instructionRequired;

  /// No description provided for @errorSavingInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar instrução'**
  String get errorSavingInstruction;

  /// No description provided for @instructionUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Instrução atualizada!'**
  String get instructionUpdated;

  /// No description provided for @errorUpdating.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar'**
  String get errorUpdating;

  /// No description provided for @confirmDelete.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta instrução?'**
  String get confirmDeleteInstruction;

  /// No description provided for @instructionDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Instrução excluída'**
  String get instructionDeleted;

  /// No description provided for @activeStatus.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get activeStatus;

  /// No description provided for @instructionActiveMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta instrução está sendo usada pela IA'**
  String get instructionActiveMessage;

  /// No description provided for @instructionInactiveMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta instrução está desativada'**
  String get instructionInactiveMessage;

  /// No description provided for @usedCount.
  ///
  /// In pt, this message translates to:
  /// **'Usado'**
  String get usedCount;

  /// No description provided for @usesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Usos'**
  String get usesLabel;

  /// No description provided for @createdAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get createdAtLabel;

  /// No description provided for @editInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Editar Instrução'**
  String get editInstruction;

  /// No description provided for @examplesEditLabel.
  ///
  /// In pt, this message translates to:
  /// **'Exemplos (um por linha)'**
  String get examplesEditLabel;

  /// No description provided for @allFilter.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get allFilter;

  /// No description provided for @newInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Nova Instrução'**
  String get newInstruction;

  /// No description provided for @noTrainingInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma instrução de treinamento'**
  String get noTrainingInstructions;

  /// No description provided for @addInstructionsToImprove.
  ///
  /// In pt, this message translates to:
  /// **'Adicione instruções para melhorar a IA'**
  String get addInstructionsToImprove;

  /// No description provided for @activateKeyboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ative o Teclado Desenrola AI'**
  String get activateKeyboardTitle;

  /// No description provided for @fullAccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ative o Acesso Completo'**
  String get fullAccessTitle;

  /// No description provided for @switchKeyboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Troque para o Teclado'**
  String get switchKeyboardTitle;

  /// No description provided for @loginToSeeContacts.
  ///
  /// In pt, this message translates to:
  /// **'Faça login para ver seus contatos'**
  String get loginToSeeContacts;

  /// No description provided for @contactsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contatos'**
  String get contactsTitle;

  /// No description provided for @contactsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas conversas e conexões'**
  String get contactsSubtitle;

  /// No description provided for @noContactFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum contato encontrado'**
  String get noContactFound;

  /// No description provided for @addFirstMatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione seu primeiro match'**
  String get addFirstMatchTitle;

  /// No description provided for @addFirstMatchDescription.
  ///
  /// In pt, this message translates to:
  /// **'Crie um perfil para quem você está\nconversando e receba sugestões\npersonalizadas via teclado'**
  String get addFirstMatchDescription;

  /// No description provided for @addContactButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Contato'**
  String get addContactButton;

  /// No description provided for @searchProfilesHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome...'**
  String get searchProfilesHint;

  /// No description provided for @loadContactsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar contatos'**
  String get loadContactsError;

  /// No description provided for @loadingPlansMessage.
  ///
  /// In pt, this message translates to:
  /// **'Carregando planos...'**
  String get loadingPlansMessage;

  /// No description provided for @planDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get planDaily;

  /// No description provided for @planWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get planMonthly;

  /// No description provided for @planQuarterly.
  ///
  /// In pt, this message translates to:
  /// **'Trimestral'**
  String get planQuarterly;

  /// No description provided for @planYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get planYearly;

  /// No description provided for @whatSheSaid.
  ///
  /// In pt, this message translates to:
  /// **'O que ela disse?'**
  String get whatSheSaid;

  /// No description provided for @pasteOrTypeLastMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite a última mensagem que ela enviou'**
  String get pasteOrTypeLastMessage;

  /// No description provided for @messageExampleHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: \"Haha verdade! E você, o que gosta de fazer?\"'**
  String get messageExampleHint;

  /// No description provided for @importButton.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get importButton;

  /// No description provided for @confirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar mensagem'**
  String get confirmMessage;

  /// No description provided for @typeTheMessage.
  ///
  /// In pt, this message translates to:
  /// **'Digite a mensagem'**
  String get typeTheMessage;

  /// No description provided for @textExtractedAutomatically.
  ///
  /// In pt, this message translates to:
  /// **'Texto extraído automaticamente'**
  String get textExtractedAutomatically;

  /// No description provided for @typeManually.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível extrair. Digite manualmente.'**
  String get typeManually;

  /// No description provided for @editIfNeeded.
  ///
  /// In pt, this message translates to:
  /// **'Edite se necessário:'**
  String get editIfNeeded;

  /// No description provided for @activateKeyboardDesc.
  ///
  /// In pt, this message translates to:
  /// **'Para usar sugestões inteligentes direto no WhatsApp, Tinder e outros apps, você precisa ativar nosso teclado personalizado.'**
  String get activateKeyboardDesc;

  /// No description provided for @activateKeyboardInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Vá em:\nAjustes → Geral → Teclado → Teclados → Adicionar'**
  String get activateKeyboardInstruction;

  /// No description provided for @fullAccessDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ao ativar, a Apple exibe um aviso de segurança padrão que pode parecer assustador — mas fique tranquilo! Esse aviso aparece para TODOS os teclados com IA. No nosso caso, o acesso completo é necessário apenas para conectar o teclado à inteligência artificial e gerar sugestões personalizadas.'**
  String get fullAccessDesc;

  /// No description provided for @fullAccessInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Selecione \"Desenrola AI\" e ative \"Permitir Acesso Completo\"'**
  String get fullAccessInstruction;

  /// No description provided for @fullAccessTip.
  ///
  /// In pt, this message translates to:
  /// **'Para proteger dados sensíveis como senhas e cartões de crédito, basta trocar para o teclado padrão do iPhone (toque no globo 🌐) antes de digitar essas informações.'**
  String get fullAccessTip;

  /// No description provided for @switchKeyboardDesc.
  ///
  /// In pt, this message translates to:
  /// **'Em qualquer app de mensagens, toque no ícone do globo (🌐) no canto inferior esquerdo do teclado para trocar para o Desenrola AI.'**
  String get switchKeyboardDesc;

  /// No description provided for @switchKeyboardInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Toque no globo 🌐 para alternar entre teclados'**
  String get switchKeyboardInstruction;

  /// No description provided for @keyboardEnabledStatus.
  ///
  /// In pt, this message translates to:
  /// **'Teclado ativado!'**
  String get keyboardEnabledStatus;

  /// No description provided for @keyboardNotEnabledStatus.
  ///
  /// In pt, this message translates to:
  /// **'Teclado não ativado'**
  String get keyboardNotEnabledStatus;

  /// No description provided for @openSettingsButton.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Configurações'**
  String get openSettingsButton;

  /// No description provided for @continueWithoutKeyboard.
  ///
  /// In pt, this message translates to:
  /// **'Continuar sem o teclado'**
  String get continueWithoutKeyboard;

  /// No description provided for @followStepsToActivate.
  ///
  /// In pt, this message translates to:
  /// **'Siga o passo a passo para ativar o teclado'**
  String get followStepsToActivate;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta deletada com sucesso.'**
  String get accountDeletedSuccess;

  /// No description provided for @accountDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao deletar conta:'**
  String get accountDeleteError;

  /// No description provided for @howToAddQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer adicionar?'**
  String get howToAddQuestion;

  /// No description provided for @addButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get addButton;

  /// No description provided for @multipleLabel.
  ///
  /// In pt, this message translates to:
  /// **'(várias)'**
  String get multipleLabel;

  /// No description provided for @mainPhotoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Principal'**
  String get mainPhotoLabel;

  /// No description provided for @addAnotherPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar outra rede social'**
  String get addAnotherPlatform;

  /// No description provided for @analyzeAndCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Analisar e Criar Perfil'**
  String get analyzeAndCreateButton;

  /// No description provided for @importFromContacts.
  ///
  /// In pt, this message translates to:
  /// **'Importar da Agenda'**
  String get importFromContacts;

  /// No description provided for @contactAutoFill.
  ///
  /// In pt, this message translates to:
  /// **'Nome e telefone vem automaticamente'**
  String get contactAutoFill;

  /// No description provided for @contactNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do contato'**
  String get contactNameHint;

  /// No description provided for @bioContextLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bio / contexto (opcional)'**
  String get bioContextLabel;

  /// No description provided for @bioContextHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: conheceu na balada, amigo da faculdade...'**
  String get bioContextHint;

  /// No description provided for @profilePhotosOptionalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fotos do Perfil (opcional)'**
  String get profilePhotosOptionalLabel;

  /// No description provided for @contactPermissionError.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de contatos necessária para importar do WhatsApp'**
  String get contactPermissionError;

  /// No description provided for @loadImageError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar imagem:'**
  String get loadImageError;

  /// No description provided for @loadImagesError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar imagens:'**
  String get loadImagesError;

  /// No description provided for @loadStoriesError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar stories:'**
  String get loadStoriesError;

  /// No description provided for @addImageOrContactError.
  ///
  /// In pt, this message translates to:
  /// **'Adicione pelo menos uma imagem de perfil ou importe um contato'**
  String get addImageOrContactError;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não autenticado'**
  String get userNotAuthenticated;

  /// No description provided for @createProfileError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar perfil:'**
  String get createProfileError;

  /// No description provided for @addSocialNetworkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Rede Social'**
  String get addSocialNetworkTitle;

  /// No description provided for @noValidPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma plataforma válida encontrada'**
  String get noValidPlatform;

  /// No description provided for @otherLabel.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get otherLabel;

  /// No description provided for @phonePrefix.
  ///
  /// In pt, this message translates to:
  /// **'Telefone:'**
  String get phonePrefix;

  /// No description provided for @imageAnalysisError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao analisar imagem'**
  String get imageAnalysisError;

  /// No description provided for @noNameFallback.
  ///
  /// In pt, this message translates to:
  /// **'Sem nome'**
  String get noNameFallback;

  /// No description provided for @profileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Perfil não encontrado'**
  String get profileNotFound;

  /// No description provided for @deleteProfileOption.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Perfil'**
  String get deleteProfileOption;

  /// No description provided for @storyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Story'**
  String get storyLabel;

  /// No description provided for @datingAppsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Apps de Relacionamento'**
  String get datingAppsLabel;

  /// No description provided for @addAppButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar App'**
  String get addAppButton;

  /// No description provided for @conversationsSectionLabel.
  ///
  /// In pt, this message translates to:
  /// **'CONVERSAS'**
  String get conversationsSectionLabel;

  /// No description provided for @allLabel.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get allLabel;

  /// No description provided for @startConversationText.
  ///
  /// In pt, this message translates to:
  /// **'Comece a conversa'**
  String get startConversationText;

  /// No description provided for @askSuggestionText.
  ///
  /// In pt, this message translates to:
  /// **'Peça uma sugestão ou use o teclado'**
  String get askSuggestionText;

  /// No description provided for @tapToSeeConversation.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver a conversa'**
  String get tapToSeeConversation;

  /// No description provided for @deleteStoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Story?'**
  String get deleteStoryTitle;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get actionCannotBeUndone;

  /// No description provided for @removePlatformConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Os dados desta plataforma serão removidos.'**
  String get removePlatformConfirm;

  /// No description provided for @removeButton.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get removeButton;

  /// No description provided for @deleteProfileQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Perfil?'**
  String get deleteProfileQuestion;

  /// No description provided for @deleteProfileMessage.
  ///
  /// In pt, this message translates to:
  /// **'O perfil e todas as conversas serão excluídos permanentemente.'**
  String get deleteProfileMessage;

  /// No description provided for @addPlatformDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Plataforma'**
  String get addPlatformDialogTitle;

  /// No description provided for @allPlatformsAddedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Todas as plataformas já foram adicionadas'**
  String get allPlatformsAddedMessage;

  /// No description provided for @addStoryError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar story:'**
  String get addStoryError;

  /// No description provided for @addPlatformError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar plataforma:'**
  String get addPlatformError;

  /// No description provided for @conversationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conversa'**
  String get conversationLabel;

  /// No description provided for @passwordValidationEnter.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma senha'**
  String get passwordValidationEnter;

  /// No description provided for @activateKeyboardDescAndroid.
  ///
  /// In pt, this message translates to:
  /// **'Para usar sugestões inteligentes direto no WhatsApp, Tinder e outros apps, você precisa ativar nosso teclado personalizado nas configurações do Android.'**
  String get activateKeyboardDescAndroid;

  /// No description provided for @activateKeyboardInstructionAndroid.
  ///
  /// In pt, this message translates to:
  /// **'Vá em:\nConfigurações → Idioma e entrada → Teclado virtual → Gerenciar teclados → Ative \"Desenrola AI\"'**
  String get activateKeyboardInstructionAndroid;

  /// No description provided for @switchKeyboardDescAndroid.
  ///
  /// In pt, this message translates to:
  /// **'Em qualquer app de mensagens, toque no ícone do teclado na barra de navegação ou mantenha pressionada a barra de espaço para trocar para o Desenrola AI.'**
  String get switchKeyboardDescAndroid;

  /// No description provided for @switchKeyboardInstructionAndroid.
  ///
  /// In pt, this message translates to:
  /// **'Toque no ícone do teclado ou mantenha pressionada a barra de espaço'**
  String get switchKeyboardInstructionAndroid;

  /// No description provided for @accessibilityServiceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ative a Leitura Automática'**
  String get accessibilityServiceTitle;

  /// No description provided for @accessibilityServiceDesc.
  ///
  /// In pt, this message translates to:
  /// **'O Desenrola AI pode ler automaticamente as conversas dos apps de dating e WhatsApp, eliminando a necessidade de copiar e colar mensagens manualmente.'**
  String get accessibilityServiceDesc;

  /// No description provided for @accessibilityServiceInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Vá em:\nConfigurações → Acessibilidade → Serviços instalados → Ative \"Desenrola AI\"'**
  String get accessibilityServiceInstruction;

  /// No description provided for @accessibilityServiceTip.
  ///
  /// In pt, this message translates to:
  /// **'O serviço só monitora apps de dating e WhatsApp. Nenhum dado de outros apps é acessado.'**
  String get accessibilityServiceTip;

  /// No description provided for @accessibilityServiceEnabledStatus.
  ///
  /// In pt, this message translates to:
  /// **'Serviço ativado!'**
  String get accessibilityServiceEnabledStatus;

  /// No description provided for @accessibilityServiceNotEnabledStatus.
  ///
  /// In pt, this message translates to:
  /// **'Serviço não ativado'**
  String get accessibilityServiceNotEnabledStatus;

  /// No description provided for @openAccessibilitySettingsButton.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Acessibilidade'**
  String get openAccessibilitySettingsButton;

  /// No description provided for @continueWithoutAccessibility.
  ///
  /// In pt, this message translates to:
  /// **'Continuar sem leitura automática'**
  String get continueWithoutAccessibility;

  /// No description provided for @aiConsentSetupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Uso de Inteligência Artificial'**
  String get aiConsentSetupTitle;

  /// No description provided for @aiConsentSetupDesc.
  ///
  /// In pt, this message translates to:
  /// **'Para gerar sugestões de mensagens, o Desenrola AI envia alguns dos seus dados para um serviço de inteligência artificial de terceiros (Anthropic Claude AI).'**
  String get aiConsentSetupDesc;

  /// No description provided for @aiConsentSetupInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados são usados apenas para gerar sugestões, não são armazenados permanentemente e são transmitidos com criptografia.'**
  String get aiConsentSetupInstruction;

  /// No description provided for @agreeAndStartButton.
  ///
  /// In pt, this message translates to:
  /// **'Concordo e Começar!'**
  String get agreeAndStartButton;

  /// No description provided for @accessibilityStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Leitura Automática'**
  String get accessibilityStatusLabel;

  /// No description provided for @accessibilityStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativado'**
  String get accessibilityStatusActive;

  /// No description provided for @accessibilityStatusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get accessibilityStatusInactive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

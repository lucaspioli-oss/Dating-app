# Publicar Desenrola AI na Google Play Store

## Etapa 1 — Criar conta no Google Play Console

1. Acesse https://play.google.com/console
2. Pague a taxa unica de **$25 USD**
3. Complete a verificacao de identidade (pode levar 1-2 dias)
4. Na pergunta sobre experiencia, use o texto abaixo:

### Texto para "Experiencia com Play Console e Android"

> Sou desenvolvedor mobile com experiencia em Flutter e desenvolvimento nativo Android (Kotlin).
> Desenvolvi o Desenrola AI, um aplicativo de assistente inteligente para mensagens que inclui
> um teclado customizado (IME - Input Method Editor) para Android e iOS. O app utiliza Firebase
> (Auth, Firestore), integracao com APIs de IA, e compras in-app. A versao iOS ja esta publicada
> na App Store via TestFlight/App Store Connect, com builds automatizados pelo Codemagic CI/CD.
> Agora estou expandindo a distribuicao para Android via Google Play Store. Tenho experiencia com
> o ecossistema Android incluindo configuracao de signing, build com Gradle, e gerenciamento de
> dependencias nativas (OkHttp, Kotlin Coroutines).

---

## Etapa 2 — Gerar Keystore de Release

No terminal, rode:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Ele vai pedir:
- **Senha do keystore** — guarde bem, nao tem como recuperar
- **Senha da key** — pode ser a mesma
- Nome, organizacao, etc.

IMPORTANTE: Mova o arquivo para um local seguro fora do repositorio git.
O .gitignore ja bloqueia *.jks e *.keystore.

---

## Etapa 3 — Criar key.properties

Crie o arquivo `flutter_keyboard/android/key.properties` com:

```properties
storePassword=SUA_SENHA_AQUI
keyPassword=SUA_SENHA_AQUI
keyAlias=upload
storeFile=CAMINHO_ABSOLUTO/upload-keystore.jks
```

IMPORTANTE: Este arquivo NAO deve ser commitado no git.
Adicione ao .gitignore se necessario: `**/key.properties`

---

## Etapa 4 — Configurar signing no build.gradle.kts

O arquivo `flutter_keyboard/android/app/build.gradle.kts` ja deve estar configurado
para ler o key.properties e usar a keystore de release (ja feito pelo Claude).

Verifique que o bloco `signingConfigs` e `buildTypes` estao corretos.

---

## Etapa 5 — Gerar o App Bundle

```bash
cd flutter_keyboard
flutter build appbundle --release
```

O .aab sera gerado em:
`build/app/outputs/bundle/release/app-release.aab`

---

## Etapa 6 — Criar o app no Google Play Console

1. No Play Console, clique em "Criar app"
2. Preencha:
   - Nome: **Desenrola AI**
   - Idioma padrao: **Portugues (Brasil)**
   - Tipo: **App**
   - Gratuito ou pago: conforme seu modelo
3. Aceite as declaracoes

---

## Etapa 7 — Configurar a ficha da loja

### Textos obrigatorios

**Descricao curta (max 80 chars):**
> Assistente IA para mensagens de dating. Respostas inteligentes no teclado.

**Descricao completa (max 4000 chars):**
> Desenrola AI e o seu assistente inteligente para conversas em apps de dating.
> Com o teclado integrado, voce recebe sugestoes de respostas personalizadas
> diretamente enquanto conversa no Tinder, Bumble, Happn ou qualquer app.
>
> COMO FUNCIONA:
> 1. Crie perfis para cada conversa
> 2. Cole a mensagem que recebeu
> 3. Receba 3 sugestoes inteligentes de resposta
> 4. Toque para inserir direto na conversa
>
> RECURSOS:
> - Teclado customizado com IA integrada
> - Multiplos perfis de conversa
> - Escolha de tom (casual, romantico, ousado, engracado)
> - Objetivos personalizaveis (primeiro encontro, manter interesse, etc.)
> - Modo rapido sem perfil
> - Escreva sua propria resposta com assistencia IA
>
> O Desenrola AI analisa o contexto da conversa e gera respostas naturais
> e personalizadas, ajudando voce a manter conversas interessantes e
> aumentar suas chances de match.

### Assets graficos obrigatorios

| Asset | Tamanho | Formato |
|-------|---------|---------|
| Icone do app | 512x512 px | PNG 32-bit, sem transparencia |
| Feature graphic | 1024x500 px | PNG ou JPG |
| Screenshots celular | min 2, 320-3840 px | PNG ou JPG |
| Screenshots tablet | min 2 (se compativel) | PNG ou JPG |

### Dicas para screenshots
- Use um celular real ou emulador com resolucao alta
- Mostre: tela de perfis, teclado com sugestoes, modo busca, escrever resposta
- Adicione textos explicativos sobre cada tela

---

## Etapa 8 — Classificacao de conteudo

1. Va em "Politica do app" > "Classificacao de conteudo"
2. Preencha o questionario do IARC
3. Respostas provaveis para o Desenrola AI:
   - Violencia: Nao
   - Sexualidade: Nao (e assistente de mensagens, nao conteudo explicito)
   - Linguagem: Possivelmente suave
   - Substancias: Nao
   - Interacao entre usuarios: Nao (o app nao tem chat proprio)
4. Resultado esperado: **Livre** ou **12+**

---

## Etapa 9 — Declaracoes obrigatorias

### Politica de privacidade
- OBRIGATORIO: URL de uma politica de privacidade valida
- Deve cobrir: dados coletados, uso de IA, Firebase, dados de teclado
- Pode usar geradores como Termly, Iubenda, ou escrever manualmente

### Seguranca dos dados
Preencha o formulario declarando:
- **Dados coletados**: Email, nome, mensagens (para analise IA)
- **Dados compartilhados**: Mensagens enviadas ao backend para processamento IA
- **Criptografia**: Sim (HTTPS)
- **Exclusao de dados**: Oferecer opcao de exclusao de conta

### Permissoes sensveis
O app usa INPUT_METHOD_SERVICE — o Google pode pedir justificativa:
> O Desenrola AI oferece um teclado customizado (IME) que permite ao usuario
> receber sugestoes de resposta com IA diretamente enquanto conversa em
> qualquer app de mensagens. O servico de input method e essencial para a
> funcionalidade principal do app.

---

## Etapa 10 — Upload e publicacao

1. Va em **Producao** > **Criar nova release**
2. Faca upload do `.aab` gerado na Etapa 5
3. Preencha as notas da versao:
   > Lancamento inicial do Desenrola AI para Android.
   > Teclado inteligente com sugestoes de resposta por IA para apps de dating.
4. Revise e envie para analise

Prazo de revisao: **1-3 dias** (primeira vez pode levar mais).

---

## Etapa 11 (Opcional) — Automatizar via Codemagic

Apos o primeiro upload manual, podemos adicionar um workflow Android no codemagic.yaml:

1. Crie uma **Service Account** no Google Cloud Console
2. Ative a **Google Play Developer API**
3. Adicione a Service Account como usuario no Play Console
4. Configure o JSON key no Codemagic
5. Adicione o workflow Android no codemagic.yaml

---

## Checklist Final

- [ ] Conta no Google Play Console criada e verificada
- [ ] Keystore de release gerada
- [ ] key.properties configurado
- [ ] build.gradle.kts com signing de release
- [ ] App bundle gerado com sucesso
- [ ] App criado no Play Console
- [ ] Ficha da loja preenchida (textos + imagens)
- [ ] Classificacao de conteudo preenchida
- [ ] Politica de privacidade publicada
- [ ] Declaracao de seguranca dos dados preenchida
- [ ] Justificativa de permissao INPUT_METHOD enviada
- [ ] Release enviada para revisao

# Publicar Desenrola AI na Google Play Store

## Passo 1: Gerar o AAB de Release

### 1.1 Keystore (JA FEITO)
Arquivo: `flutter_keyboard/android/upload-keystore.jks`
Config: `flutter_keyboard/android/key.properties`

### 1.2 Gerar App Bundle
```bash
cd flutter_keyboard
flutter build appbundle --release
```
Arquivo gerado em: `build/app/outputs/bundle/release/app-release.aab`

---

## Passo 2: Acessar o Google Play Console

1. Ir em https://play.google.com/console
2. Login com conta Google verificada
3. Clicar em **"Criar app"**

---

## Passo 3: Criar o App

- **Nome do app**: Desenrola AI
- **Idioma padrao**: Portugues (Brasil)
- **App ou jogo**: App
- **Gratuito ou pago**: Gratuito (com compras no app)
- Aceitar as declaracoes

---

## Passo 4: Ficha da Loja (Dashboard > Ficha da loja principal)

- **Descricao curta** (80 chars): "Teclado AI para dating — gera respostas perfeitas direto no chat"
- **Descricao completa**: Usar a descricao de marketing do app (ver abaixo)
- **Icone do app**: 512x512 PNG sem transparencia
- **Grafico de recursos**: 1024x500 PNG (banner)
- **Screenshots**: Minimo 2 (recomendado 4-6), tamanho minimo 320px
- **Categoria**: Social / Comunicacao
- **Email de contato**: Seu email

### Descricao completa sugerida:
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
> - Analise de screenshots de conversas
> - Geracao de aberturas de conversa
> - Modo rapido sem perfil
> - Escreva sua propria resposta com assistencia IA

### Assets graficos obrigatorios

| Asset | Tamanho | Formato |
|-------|---------|---------|
| Icone do app | 512x512 px | PNG 32-bit, sem transparencia |
| Feature graphic | 1024x500 px | PNG ou JPG |
| Screenshots celular | min 2, 320-3840 px | PNG ou JPG |

---

## Passo 5: Classificacao de Conteudo (Dashboard > Classificacao de conteudo)

1. Clicar "Iniciar questionario"
2. Preencher email de contato
3. Selecionar categoria: Utilidade / Comunicacao
4. Respostas:
   - Violencia: Nao
   - Sexualidade: Nao
   - Linguagem: Possivelmente suave
   - Substancias: Nao
   - Interacao entre usuarios: Nao
5. Resultado esperado: **Livre** ou **12+**

---

## Passo 6: Preco e Distribuicao

- Gratuito
- Selecionar paises (Brasil, ou todos)
- Sem anuncios
- Declaracoes de conformidade (LGPD)

---

## Passo 7: Politica de Privacidade

- URL: `https://desenrola-ia.web.app/privacy`

---

## Passo 8: Seguranca dos Dados (Dashboard > Seguranca dos dados)

Declarar:
- **Dados coletados**: Email, nome, fotos de perfil (de apps de dating)
- **Dados compartilhados**: Textos enviados para AI (Anthropic Claude)
- **Criptografia**: Sim (HTTPS/TLS)
- **Exclusao de dados**: Usuario pode solicitar

---

## Passo 9: Permissoes Especiais — Teclado (IME)

**IMPORTANTE**: O app usa `BIND_INPUT_METHOD` (teclado customizado).

1. Ir em **Politica > Permissoes do app**
2. Declarar uso de IME (Input Method Editor)
3. Justificativa:
> O Desenrola AI oferece um teclado customizado (IME) que permite ao usuario
> receber sugestoes de resposta com IA diretamente enquanto conversa em
> qualquer app de mensagens. O servico de input method e essencial para a
> funcionalidade principal do app.
4. Google pode pedir video demonstrativo

---

## Passo 10: Criar Release (Dashboard > Producao)

1. Ir em **Producao > Criar nova versao**
2. Configurar **App Signing by Google Play** (aceitar, e obrigatorio)
3. Upload do `.aab` gerado no Passo 1
4. Notas da versao:
```
Primeira versao do Desenrola AI para Android.
- Teclado AI integrado para apps de dating
- Sugestoes inteligentes de resposta
- Analise de screenshots
- Geracao de aberturas de conversa
```
5. Clicar **"Revisar versao"** > **"Iniciar distribuicao para producao"**

---

## Passo 11: Assinaturas (Monetizacao > Produtos > Assinaturas)

1. Criar grupo: "Desenrola AI Premium"
2. Criar 3 planos:
   - **Mensal**: ID `desenrola_monthly`
   - **Trimestral**: ID `desenrola_quarterly`
   - **Anual**: ID `desenrola_yearly`
3. Product IDs devem bater com `AppConfig`

---

## Passo 12: Aguardar Revisao

- Primeira revisao: **1-3 dias** (pode ser ate 7)
- Apps com teclado customizado podem ter revisao mais rigorosa
- Se rejeitado, Google informa o motivo para correcao

---

## Checklist Final

- [x] Keystore de release gerada
- [x] key.properties configurado
- [x] build.gradle.kts com signing de release
- [ ] App bundle gerado com sucesso
- [ ] App criado no Play Console
- [ ] Ficha da loja preenchida (textos + imagens)
- [ ] Classificacao de conteudo preenchida
- [x] Politica de privacidade publicada
- [ ] Declaracao de seguranca dos dados preenchida
- [ ] Justificativa de permissao INPUT_METHOD enviada
- [ ] Assinaturas criadas
- [ ] Release enviada para revisao

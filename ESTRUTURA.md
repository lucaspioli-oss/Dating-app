# Funil Ligação Game - Desenrola AI

## Conceito
Funil gamificado com storytelling cinematográfico. A pessoa vive uma experiência imersiva através de ligações e chat, descobrindo o produto de forma natural. Cada interação gera curiosidade e engajamento dopaminérgico.

---

## Fluxo Principal

```
[ANÚNCIO]
    ↓
[1. LANDING] "Preparado?" + Aumentar som
    ↓
[2. LIGAÇÃO CODE] Celular vibrando → Atende → Áudio urgente → Cai
    ↓
[3. DISCAR] Tela de telefone com número já digitado
    ↓
[4. LIGAÇÃO ANA] Chamando → Atende → História completa
    ↓
[5. CHAT] Conversa interativa + demonstração
    ↓
[6. REVELAÇÃO] Plot twist - "Isso foi o Desenrola AI"
    ↓
[7. CHECKOUT] Acesso liberado
```

**Tempo total estimado: 5-7 minutos**

---

# TELAS DETALHADAS

---

## 1. Landing Page (`/`)

### Objetivo
Preparar a pessoa, criar expectativa, garantir som ligado.

### Visual
- Fundo: preto ou gradiente escuro
- Centralizado na tela
- Minimalista, sem distrações

### Conteúdo
```
"Você está preparado para viver uma experiência
diferente de tudo que já viu?"

🔊 Aumente o som para uma melhor experiência

[ESTOU PRONTO]
```

### Elementos
- Texto principal: branco, fonte clean, tamanho grande
- Ícone de volume: animado (pulsando ou ondas)
- Botão: destaque, pulsando levemente
- Possível: partículas ou efeito sutil no fundo

### Ação
- Click no botão → redireciona para `/ligacao`

---

## 2. Ligação Recebendo (`/ligacao`)

### Objetivo
Simular celular recebendo ligação real. Criar urgência imediata.

### Visual
- Tela CHEIA imitando interface de chamada iOS/Android
- Escuro com elementos de chamada

### Elementos
- **Foto**: silhueta masculina ou avatar misterioso
- **Nome**: "Número Desconhecido" ou "Code"
- **Número**: número genérico
- **Botão Atender**: verde, grande, pulsando
- **Botão Recusar**: vermelho, menor
- **Som**: toque de telefone tocando
- **Vibração**: usar Vibration API em mobile

### Comportamento
- Página carrega → espera 1s → começa tocar/vibrar
- Som de toque em loop até atender
- Se recusar: tela "Chamada perdida" → botão "Ligar de volta"
- Se atender: vai para `/ligacao/code`

---

## 3. Ligação Code (`/ligacao/code`)

### Objetivo
Contar história, criar tensão, urgência real, passar próximo passo.

### Visual
- Interface de chamada em andamento
- Timer rodando (00:00 → incrementa)
- Waveform ou indicador de áudio
- Foto/avatar do Code

### Áudio (~45-60 segundos)
```
[Som de conexão]

"E aí... que bom que atendeu.

Preciso falar rápido, não tenho muito tempo.

Eu desenvolvi uma tecnologia... algo diferente de tudo que
você já viu. Vai ser uma verdadeira revolução.

E os coaches de relacionamento, os apps de namoro... eles
tão fazendo de TUDO pra me derrubar. Chegaram até a
contratar hackers pra me atacar.

Por isso essa ligação pode cair a qualquer hora.

Se isso acontecer, preciso que você ligue pra Ana.

O número é 345 9450-4335. Anota.

[Pausa 2s]

Eu tava cansado, mano. Cansado de tomar vacuo. Cansado de
joguinho. Cansado de me sentir REFÉM desses apps, pagando
e nunca conseguindo resultado nenhum.

Aí eu criei uma coisa que--

[Estática, interferência crescente]

Merda. A ligação tá caindo.

Lembra, rápido. Liga pra Ana.

O número é 345 9450-4335.

Liga pra ela que ela te expli--

[Pi... pi... pi... - chamada cai]"
```

### Efeitos de Áudio
- Qualidade: levemente comprimida (parecer ligação real)
- Estática: começa sutil aos ~40s, aumenta
- Final: corte abrupto + tom de chamada caindo

### Comportamento
- Áudio toca automaticamente
- Timer sincroniza com áudio
- Quando áudio termina → tela "Chamada Encerrada" por 2s
- Redirect automático para `/discar`

---

## 4. Tela Discar (`/discar`)

### Objetivo
Usuário "liga" para Ana. Ação simples e direta.

### Visual
- Interface de telefone/discador
- Número JÁ DIGITADO na tela
- Sem texto explicativo, sem "missão"

### Elementos
- **Display numérico**: 345 9450-4335
- **Nome do contato**: Ana
- **Teclado numérico**: visível mas decorativo
- **Botão ligar**: verde, grande, centralizado embaixo
- **Fundo**: escuro, interface de telefone

### Comportamento
- Click em ligar → animação de "Chamando..."
- Som de chamando (tu... tu... tu...)
- Após 3-4 "tu" → vai para `/ligacao/ana`

---

## 5. Ligação Ana (`/ligacao/ana`)

### Objetivo
Continuar história, explicar o que Code criou, criar mistério, mandar pro chat.

### Visual
- Interface de chamada
- Foto feminina (Ana)
- Timer rodando

### Áudio (~90-120 segundos)
```
[Tu... tu... tu... - chamando]

[Atende]

"Alô?... Alôou?...

[Pausa 2s]

Interessante. Só uma pessoa tinha esse número. E eu sei
que se você tá ligando agora... é porque atacaram o Code
de novo.

Espero que dessa vez ele esteja bem.

[Suspiro]

Vamos lá.

Aqui é a Ana. E você acabou de entrar em algo que não
tem mais volta.

Presta muita atenção.

Nos últimos meses, o Code hackeou toda a psicologia de
relacionamentos. Ele transformou milhares de conversas
e perfis em dados. Identificou padrões que são ocultos
aos olhos humanos. Mapeou estratégias específicas pra
cada padrão.

Quando ele testou... aí veio a surpresa.

2 mulheres. Pedindo pra SAIR COM ELE. Em menos de 1 semana.

Ele percebeu que tinha uma chave dourada nas mãos. Algo
que não podia guardar só pra ele.

Mas também... algo que podia ser uma arma na mão da
pessoa errada.

Ele pensou muito se deveria disponibilizar. Considerou
os estragos que isso poderia gerar.

[Pausa dramática 2s]

Mas ele decidiu que o cara certo merecia ter acesso.

E se você chegou até aqui... talvez você seja esse cara.

Mas antes de eu te mostrar qualquer coisa, preciso saber
se você tá pronto pra isso.

Vou te mandar uma mensagem. Me responde lá.

[Chamada encerra suavemente]"
```

### Comportamento
- Áudio toca automaticamente
- Quando termina → tela "Chamada Encerrada" por 1s
- Redirect para `/chat`

---

## 6. Chat (`/chat`)

### Objetivo
Interação direta, demonstração ao vivo do produto, criar conexão.

### Visual
- Interface estilo WhatsApp
- Fundo: cinza escuro ou tema dark
- Bolhas de mensagem
- Typing indicator realista
- Área de input (funcional para respostas)

### Fluxo do Chat

#### Parte 1: Abertura
```
[Ana digitando...]

Ana: "Você atendeu. Isso já diz algo sobre você."

[Pausa 1.5s]

Ana: "Agora eu preciso entender uma coisa."

[Pausa 1s]

Ana: "Por que você quer isso?"

[Opções aparecem como botões]
├─ "Cansei de tomar vacuo"
├─ "Quero parar de travar nas conversas"
├─ "Quero ter mais resultados"
└─ [Campo para digitar]

[Usuário escolhe]

Ana: "Entendi."

[Pausa 1s]

Ana: "Vou te mostrar o que o Code criou. Mas não vou só
FALAR. Vou te fazer SENTIR."

Ana: "Faz o seguinte. Imagina que eu sou uma mina que
você acabou de dar match. Vou te mandar uma mensagem
como ela mandaria. Você responde como você responderia
normalmente."

Ana: "Preparado?"

[Botão único: "BORA"]
```

#### Parte 2: Simulação
```
[Transição visual - Ana "vira" outra pessoa]
[Nome muda para "Mina do Tinder 🔥" ou similar]

Mina: "oi"

[Campo de resposta aparece]
[Opções sugeridas + campo livre]
├─ "Oi, tudo bem?"
├─ "E aí, beleza?"
└─ [Digitar]

[Usuário responde]

Mina: "bem e vc"

[Opções + campo livre]

[Usuário responde]

Mina: "legal"

[Nenhuma opção aparece]
[Silêncio... 3-4 segundos]
[Typing indicator aparece e some]
[Nada acontece]
```

#### Parte 3: Análise
```
[Transição - volta pra Ana]

Ana: "Morreu né?"

[Pausa 1s]

Ana: "Essa é a realidade de 90% dos caras. A conversa
simplesmente... morre."

Ana: "Agora olha o que o sistema do Code sugeriria
nesse momento exato:"

[Caixa destacada aparece]
┌────────────────────────────────────────┐
│ 💡 SUGESTÃO DO DESENROLA AI            │
│                                        │
│ "Legal é fichinha. Me conta algo       │
│ sobre você que eu não ia adivinhar     │
│ nem em 10 tentativas"                  │
└────────────────────────────────────────┘

Ana: "Percebe? Não é forçado. Não é cantada brega.
É só... a coisa certa na hora certa."

Ana: "Quer ver o que acontece quando você usa isso
consistentemente?"

[Botão: "MOSTRA"]
```

#### Parte 4: Prova Social
```
Ana: "Olha esses resultados reais:"

[Imagem: Print de conversa 1 - match → date]

[Pausa 2s]

[Imagem: Print de conversa 2 - recuperou conversa fria]

[Pausa 2s]

[Imagem: Print de conversa 3 - pediu número]

Ana: "Isso é o que acontece quando você para de
adivinhar e começa a SABER o que funciona."
```

#### Parte 5: Revelação
```
[Pausa 2s]

Ana: "Agora a parte que o Code não queria que eu
contasse..."

[Pausa 1.5s]

Ana: "Tudo que eu te mandei até agora..."

Ana: "O tom. As respostas. O timing."

Ana: "Foi o sistema dele me guiando."

[Pausa 2s]

Ana: "Você acabou de conversar com a ferramenta
sem perceber."

Ana: "E funcionou, não funcionou?"

Ana: "Você respondeu. Você engajou. Você ficou
até aqui."

[Pausa 2s]

Ana: "Imagina ter isso em TODA conversa. Todo match.
Toda oportunidade."

[Pausa 1s]

Ana: "O Code me autorizou a liberar o acesso pra
quem chegasse até aqui."

Ana: "Você chegou. 🔓"

[Botão grande pulsando: "QUERO MEU ACESSO"]
```

### Comportamento
- Mensagens aparecem com delay realista
- Typing indicator antes de cada mensagem
- Scroll automático para última mensagem
- Respostas do usuário aparecem como bolha do lado direito

---

## 7. Checkout (`/checkout`)

### Objetivo
Conversão. Pessoa já está engajada e convencida.

### Visual
- Transição suave do chat
- Header: "Acesso Autorizado" ou "🔓 Desbloqueado"
- Layout limpo de checkout

### Elementos
- Resumo do que recebe
- Planos de preço (mensal/trimestral/anual)
- Garantia 7 dias destacada
- Formulário: nome + email
- Botão de pagamento
- Badges de segurança

### Planos
```
┌─────────────────────────────────────────┐
│ MENSAL           R$ 29,90/mês          │
│ Acesso completo ao Desenrola AI         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ TRIMESTRAL ⭐ MAIS POPULAR              │
│ R$ 69,90 (R$ 23,30/mês)                │
│ Economize 22%                           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ ANUAL 💎 MELHOR VALOR                   │
│ R$ 199,90 (R$ 16,66/mês)               │
│ Economize 44%                           │
└─────────────────────────────────────────┘
```

---

# ASSETS NECESSÁRIOS

## Áudios

### Efeitos Sonoros
```
/assets/audios/effects/
├── toque_celular.mp3       # Som de telefone tocando (loop)
├── chamando.mp3            # Tu... tu... tu...
├── conectando.mp3          # Som de conexão de chamada
├── estatica.mp3            # Interferência/estática
├── chamada_caindo.mp3      # Pi... pi... pi...
├── chamada_encerrada.mp3   # Som de desligar
├── notificacao_msg.mp3     # Som de mensagem recebida
└── desbloqueio.mp3         # Som de conquista/unlock
```

### Vozes
```
/assets/audios/voices/
├── code_ligacao.mp3        # Áudio completo do Code (~45-60s)
└── ana_ligacao.mp3         # Áudio completo da Ana (~90-120s)
```

### Especificações de Áudio
- Formato: MP3 ou AAC
- Qualidade vozes: 128kbps (levemente comprimido = parecer ligação)
- Qualidade efeitos: 192kbps
- Normalização: -14 LUFS

---

## Imagens

### Avatares
```
/assets/images/avatars/
├── code_avatar.png         # Silhueta ou avatar misterioso masculino
├── code_avatar_blur.png    # Versão desfocada/escura
├── ana_avatar.png          # Foto feminina realista
└── mina_tinder.png         # Avatar genérico feminino pro chat
```

### Especificações Avatares
- Tamanho: 200x200px (ou maior, será redimensionado)
- Formato: PNG com transparência
- Estilo: Realista ou silhueta misteriosa

### Backgrounds
```
/assets/images/backgrounds/
├── bg_landing.png          # Fundo da landing (escuro, sutil)
├── bg_call.png             # Fundo tela de ligação
└── bg_chat.png             # Fundo do chat (estilo WhatsApp dark)
```

### Prints de Prova Social
```
/assets/images/proofs/
├── print_conversa_01.png   # Print resultado 1
├── print_conversa_02.png   # Print resultado 2
└── print_conversa_03.png   # Print resultado 3
```

### Especificações Prints
- Tamanho: 300-400px largura
- Formato: PNG
- Estilo: Screenshot real de WhatsApp/Tinder
- Importante: borrar/censurar dados sensíveis

### Ícones e UI
```
/assets/images/icons/
├── icon_volume.svg         # Ícone de volume animado
├── icon_phone.svg          # Ícone telefone
├── icon_lock.svg           # Cadeado (para desbloqueio)
├── icon_unlock.svg         # Cadeado aberto
└── icon_check.svg          # Check de confirmação
```

---

## Vídeos (Opcional)

Se quiser adicionar vídeos curtos em algum momento:
```
/assets/videos/
├── bg_particles.mp4        # Partículas sutis para landing
└── transition_unlock.mp4   # Efeito de desbloqueio
```

---

# COMPONENTES REACT

## Estrutura de Pastas
```
/src
├── pages/
│   ├── Landing.tsx
│   ├── IncomingCall.tsx
│   ├── CallCode.tsx
│   ├── Dialer.tsx
│   ├── CallAna.tsx
│   ├── Chat.tsx
│   └── Checkout.tsx
│
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   └── ProgressBar.tsx
│   │
│   ├── phone/
│   │   ├── IncomingCallScreen.tsx
│   │   ├── OngoingCallScreen.tsx
│   │   ├── DialerScreen.tsx
│   │   └── CallEndedScreen.tsx
│   │
│   ├── chat/
│   │   ├── ChatContainer.tsx
│   │   ├── ChatBubble.tsx
│   │   ├── TypingIndicator.tsx
│   │   ├── ChatInput.tsx
│   │   ├── ChatOptions.tsx
│   │   └── SuggestionBox.tsx
│   │
│   └── audio/
│       ├── AudioPlayer.tsx
│       └── Waveform.tsx
│
├── hooks/
│   ├── useAudio.ts
│   ├── useVibration.ts
│   ├── useChatSequence.ts
│   └── useTimer.ts
│
├── lib/
│   ├── scripts/
│   │   ├── codeScript.ts       # Texto do áudio do Code
│   │   ├── anaScript.ts        # Texto do áudio da Ana
│   │   └── chatScript.ts       # Sequência de mensagens do chat
│   │
│   ├── audioManager.ts
│   └── tracking.ts
│
└── assets/
    ├── audios/
    ├── images/
    └── videos/
```

---

## Rotas
```tsx
<Route path="/" component={Landing} />
<Route path="/ligacao" component={IncomingCall} />
<Route path="/ligacao/code" component={CallCode} />
<Route path="/discar" component={Dialer} />
<Route path="/ligacao/ana" component={CallAna} />
<Route path="/chat" component={Chat} />
<Route path="/checkout" component={Checkout} />
```

---

# ESPECIFICAÇÕES TÉCNICAS

## Áudio
- Usar Web Audio API para melhor controle
- Preload dos áudios principais no landing
- Fallback para `<audio>` se Web Audio não suportado

## Vibração
- Usar Vibration API: `navigator.vibrate([200, 100, 200])`
- Pattern de vibração de telefone: `[500, 200, 500, 200, 500]`
- Fallback: nada (só visual)

## Responsividade
- Mobile-first (maioria do tráfego)
- Telas de ligação: fullscreen em mobile
- Chat: funciona igual WhatsApp mobile

## Performance
- Preload de assets críticos
- Lazy load de imagens de prova social
- Áudios: streaming, não download completo

---

# TRACKING E MÉTRICAS

## Eventos para Rastrear
```
- landing_view
- landing_click_ready
- call_code_answer
- call_code_decline
- call_code_complete
- dialer_call_click
- call_ana_complete
- chat_start
- chat_option_selected (qual opção)
- chat_simulation_complete
- chat_reveal_view
- chat_cta_click
- checkout_view
- checkout_plan_select (qual plano)
- checkout_form_start
- checkout_complete
```

## Métricas Principais
- Taxa Landing → Atender ligação
- Taxa Atender → Completar ligação Code
- Taxa Completar Code → Ligar Ana
- Taxa Ligar Ana → Iniciar chat
- Taxa Iniciar chat → Ver revelação
- Taxa Revelação → Checkout
- Taxa Checkout → Compra

---

# VARIAÇÕES PARA TESTE

## Parâmetros de URL
```
/?v=1    # Versão padrão
/?v=2    # Versão com narrativa alternativa
/?v=3    # Versão mais curta
```

## O que pode variar
- Tom do áudio do Code (mais urgente vs mais casual)
- Duração dos áudios
- Quantidade de prints no chat
- Copy do checkout
- Ordem das opções de resposta

---

# PRÓXIMOS PASSOS

## Fase 1: Assets
- [ ] Gravar áudio do Code
- [ ] Gravar áudio da Ana
- [ ] Coletar/criar prints de prova social
- [ ] Criar avatares
- [ ] Baixar/criar efeitos sonoros

## Fase 2: Desenvolvimento
- [ ] Setup projeto React/Vite
- [ ] Componentes de telefone
- [ ] Componentes de chat
- [ ] Integração de áudio
- [ ] Sistema de rotas e navegação

## Fase 3: Integração
- [ ] Conectar com checkout existente
- [ ] Tracking de eventos
- [ ] Testes em dispositivos

## Fase 4: Deploy
- [ ] Build de produção
- [ ] Deploy no Firebase
- [ ] Configurar domínio
- [ ] Testar fluxo completo

---

# NOTAS DE PRODUÇÃO DE ÁUDIO

## Áudio do Code
- **Tom**: Urgente mas genuíno, não forçado
- **Ambiente**: Leve ruído de fundo (parece real)
- **Qualidade**: Levemente comprimido (parecer ligação)
- **Efeitos**: Estática crescente no final, corte abrupto

## Áudio da Ana
- **Tom**: Começa confusa, depois confiante e misteriosa
- **Ambiente**: Limpo, mais qualidade que o Code
- **Ritmo**: Pausas dramáticas nos momentos certos
- **Emoção**: Transmitir que ela SABE algo importante

## Dicas Gerais
- Gravar em ambiente silencioso
- Usar pop filter
- Não exagerar na atuação - naturalidade > drama forçado
- Fazer múltiplas takes e escolher a melhor

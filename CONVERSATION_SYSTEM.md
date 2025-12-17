# 💬 Sistema de Conversas Gerenciadas com Avatar

## 🎯 Visão Geral

Sistema completo de gerenciamento de conversas com IA que permite:
1. **Criar conversas** a partir de openers gerados
2. **Manter histórico completo** de cada conversa
3. **Calibragem automática** do estilo de resposta do match
4. **Avatar da conversa** que aprende e evolui
5. **3 Níveis de Tons** integrados (Básico, Avançado, Expert)

---

## 🔄 Fluxo Completo do Usuário

```
1. ABA ANÁLISE → Upload screenshot + Gerar opener
   ↓
2. Selecionar opener + "Iniciar Conversa com Esta"
   ↓
3. Conversa criada + Navega para tela de detalhes
   ↓
4. Inserir resposta recebida + Escolher tom
   ↓
5. IA gera 3 sugestões baseadas NO HISTÓRICO COMPLETO + CALIBRAGEM
   ↓
6. Selecionar sugestão OU escrever mensagem própria
   ↓
7. Enviar mensagem + Sistema atualiza analytics
   ↓
8. Repetir passos 4-7 para continuar a conversa
```

---

## 📊 Avatar da Conversa

Cada conversa tem um **avatar único** que contém:

### 👤 Perfil do Match
- Nome
- Plataforma (Tinder, Bumble, Hinge, Instagram)
- Bio
- Idade
- Localização
- Interesses
- Descrições de fotos

### 📈 Calibragem Automática (Atualizada em Tempo Real)
```typescript
detectedPatterns: {
  responseLength: 'short' | 'medium' | 'long',  // Como ela/ele responde
  emotionalTone: 'warm' | 'neutral' | 'cold',    // Tom emocional
  useEmojis: boolean,                             // Usa emojis?
  flirtLevel: 'low' | 'medium' | 'high',          // Receptividade ao flerte
}
```

### 💡 Informações Aprendidas
- Hobbies detectados
- Lifestyle
- Dislikes
- Goals
- Traços de personalidade

### 📊 Analytics
- Total de mensagens
- Sugestões da IA usadas
- Mensagens customizadas usadas
- Qualidade da conversa: excellent, good, average, poor

---

## 🤖 Sistema de Calibragem Inteligente

### Como Funciona

A cada mensagem recebida do match, o sistema automaticamente:

1. **Analisa o tamanho da resposta**
   ```
   < 50 chars  → short  → IA espelha com respostas curtas
   < 150 chars → medium → IA espelha proporcionalmente
   > 150 chars → long   → IA pode investir mais
   ```

2. **Detecta tom emocional**
   ```
   Palavras quentes (amor, querido, fofo, haha) → warm  🔥
   Palavras frias (ok, sei, talvez, depois)      → cold  ❄️
   Neutro                                        → neutral 😐
   ```

3. **Avalia receptividade ao flerte**
   ```
   Mensagens match > usuário → high   🔥 (muito interessado!)
   Mensagens match = usuário → medium 😊
   Mensagens match < usuário → low    ❄️ (reduza investimento)
   ```

4. **Detecta padrões de uso de emoji**
   - Se usa → você pode usar também
   - Se não usa → evite emojis

5. **Extrai informações aprendidas**
   - Detecta hobbies: "gosto de", "adoro", "amo"
   - Detecta dislikes: "odeio", "não gosto", "detesto"

---

## 🎨 Frontend (Flutter)

### Telas Criadas

#### 1. **ConversationsScreen** (Lista de Conversas)
- Lista todas as conversas ativas
- Mostra indicadores de calibragem (🔥/❄️/😐)
- Plataforma emoji (🔥 Tinder, 💛 Bumble, etc.)
- Última mensagem + timestamp
- Pull-to-refresh

#### 2. **ConversationDetailScreen** (Tela da Conversa)
**Componentes:**
- **Barra de Calibragem** (topo)
  - 📏/📄/📜 Tamanho de resposta
  - 🔥/😐/❄️ Tom emocional
  - 🔥/😊/❄️ Nível de flerte
  - ⭐⭐⭐ Qualidade

- **Histórico de Mensagens**
  - Bolhas alinhadas (direita = você, esquerda = match)
  - Tag "🤖 Sugestão da IA" nas mensagens geradas

- **Input de Mensagem Recebida**
  - Campo para colar mensagem recebida
  - Botão "✨ Gerar Sugestões"
  - Seletor de tom (6 opções)

- **Seção de Sugestões** (aparece após gerar)
  - 3 sugestões da IA
  - Botão copiar em cada sugestão
  - Botão enviar em cada sugestão
  - Campo para mensagem customizada
  - Botão limpar sugestões

#### 3. **UnifiedAnalysisScreen** (Atualizado)
- Agora tem botão "Iniciar Conversa com Esta" em cada opener
- Cria conversa automaticamente e navega para ela

---

## 🔧 Backend (Node.js + TypeScript)

### Endpoints Criados

```typescript
POST   /conversations                      // Criar nova conversa
GET    /conversations                      // Listar conversas
GET    /conversations/:id                  // Obter conversa específica
POST   /conversations/:id/messages         // Adicionar mensagem
POST   /conversations/:id/suggestions      // Gerar sugestões (PRINCIPAL)
PATCH  /conversations/:id/tone             // Atualizar tom
DELETE /conversations/:id                  // Deletar conversa
```

### Endpoint Principal: `/conversations/:id/suggestions`

**Input:**
```json
{
  "receivedMessage": "Oiii, tudo bem? 😊",
  "tone": "expert",
  "userContext": { ... }
}
```

**Processamento:**
1. Adiciona mensagem recebida ao histórico
2. Atualiza calibragem automática
3. Formata histórico completo com:
   - Perfil do match
   - Calibragem detectada
   - Informações aprendidas
   - Analytics
   - Histórico de mensagens
4. Seleciona prompt baseado no tom (Básico/Avançado/Expert)
5. Envia para Claude com contexto COMPLETO
6. Retorna 3 sugestões calibradas

**Output:**
```json
{
  "suggestions": "1. Resposta 1\n2. Resposta 2\n3. Resposta 3"
}
```

---

## 📝 Exemplo de Prompt Enviado para Claude

```
[EXPERT_SYSTEM_PROMPT com 4 Leis Fundamentais]

═══════════════════════════════════════════════════════════════════
📋 CONTEXTO DA CONVERSA
═══════════════════════════════════════════════════════════════════

👤 PERFIL DO MATCH:
Nome: Maria
Plataforma: TINDER
Bio: Amo viajar e conhecer pessoas novas 🌍
Idade: 25
Interesses: viagens, yoga, fotografia

📊 CALIBRAGEM DETECTADA:
- Tamanho de resposta: MÉDIO
- Tom emocional: 🔥 CALOROSO (ela está receptiva!)
- Usa emojis: SIM (você pode usar também)
- Nível de flerte: 🔥 ALTO (ela está muito interessada!)

💡 INFORMAÇÕES APRENDIDAS:
- Hobbies: viajar, yoga, fotografia

📈 ANÁLISE DE PERFORMANCE:
- Total de mensagens: 6
- Sugestões da IA usadas: 4
- Mensagens customizadas: 2
- Qualidade da conversa: EXCELLENT

═══════════════════════════════════════════════════════════════════
💬 HISTÓRICO DA CONVERSA
═══════════════════════════════════════════════════════════════════

1. VOCÊ [IA]: "Viajar e yoga? Aposto que você é do tipo que faz pose de lótus no topo de uma montanha 😂"
2. MARIA: "Hahaha, exatamente! Já fiz no Peru 😊"
3. VOCÊ [IA]: "Peru? Agora você me deixou curioso. Machu Picchu?"
4. MARIA: "Sim! Foi incrível, melhor viagem da minha vida ❤️"
5. VOCÊ: "Incrível! Eu tô planejando ir ano que vem"
6. MARIA: "Vai amar! Se quiser dicas, me chama 😊"

═══════════════════════════════════════════════════════════════════

👤 SEU PERFIL
═══════════════════════════════════════════════════════════════════
Nome: João
Idade: 27
Interesses: tecnologia, viagens, música
⚠️ EVITE mencionar: política, esportes

═══════════════════════════════════════════════════════════════════

A mensagem mais recente que você acabou de receber foi:
"Vai amar! Se quiser dicas, me chama 😊"

Com base em TODO o contexto acima (perfil do match, calibragem detectada, histórico completo), gere APENAS 3 sugestões de resposta que:
1. ESPELHEM o tamanho de resposta detectado
2. ADAPTEM ao tom emocional detectado
3. MANTENHAM a qualidade da conversa
4. AVANCEM a interação de forma natural
```

---

## 🎯 Integração com Sistema de 3 Níveis

Cada conversa usa um dos **3 níveis de prompts**:

### 🟢 Básico (engraçado, romântico, casual)
- Respostas simples e naturais
- Sem técnicas avançadas
- Fácil de usar

### 🟡 Avançado (ousado, confiante)
- Push-Pull sutil
- Frame control moderado
- Calibragem básica

### 🔴 Expert
- **4 Leis Fundamentais** completas
- Shit test detection
- Calibragem avançada
- Para situações complexas

---

## 💾 Persistência (Atual: Memória)

Atualmente, as conversas são armazenadas em memória:

```typescript
const conversations = new Map<string, Conversation>();
```

**Para produção:**
- [ ] Migrar para MongoDB/PostgreSQL
- [ ] Adicionar autenticação de usuário
- [ ] Vincular conversas a usuários
- [ ] Backup automático

---

## 🚀 Como Usar

### 1. Gerar Opener
1. Vá para aba "Análise"
2. Upload screenshot do perfil (opcional)
3. Preencha nome, bio, fotos
4. Escolha plataforma e tom
5. Clique "Gerar Mensagens"
6. Clique "Iniciar Conversa com Esta" em um opener

### 2. Continuar Conversa
1. Match respondeu? Vá para aba "Conversas"
2. Abra a conversa
3. Cole a mensagem recebida
4. Escolha o tom (ou mantenha atual)
5. Clique ✨ para gerar sugestões
6. Selecione uma sugestão OU escreva sua própria
7. Envie!

### 3. Acompanhar Performance
- Barra de calibragem mostra status em tempo real
- Botão ℹ️ no topo mostra detalhes completos do avatar
- Analytics atualizam automaticamente

---

## 📈 Benefícios do Sistema

1. **Contexto Completo**
   - IA sempre sabe toda a história
   - Não esquece informações importantes
   - Mantém coerência

2. **Calibragem Automática**
   - Adapta-se ao estilo do match
   - Espelha investimento
   - Detecta receptividade

3. **Aprendizado Contínuo**
   - Extrai informações de cada mensagem
   - Constrói perfil do match
   - Melhora sugestões ao longo do tempo

4. **Analytics**
   - Vê o que funciona
   - Taxa de sucesso de sugestões IA
   - Qualidade da conversa

5. **Flexibilidade**
   - Pode usar sugestões IA
   - Pode escrever próprias mensagens
   - Sistema aprende de ambas

---

## 🔮 Roadmap Futuro

- [ ] Sistema de tags/categorias para conversas
- [ ] Busca em conversas
- [ ] Exportar histórico
- [ ] Sugestões proativas ("Faz 2 dias que não responde, envie...")
- [ ] A/B testing de abordagens
- [ ] Modo "Coach" que explica por que cada sugestão funciona
- [ ] Integração com apps reais (via API)
- [ ] Análise de sentimento mais sofisticada
- [ ] Previsão de sucesso de mensagens antes de enviar

---

**Última atualização:** Dezembro 2025
**Versão:** 1.0
**Status:** ✅ Funcional

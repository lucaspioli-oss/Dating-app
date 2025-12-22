# 🎯 Sistema de Prompts Hierárquico

## Visão Geral

O sistema foi estruturado em **3 níveis de sofisticação** para atender diferentes públicos e contextos:

```
🟢 BÁSICO → 🟡 AVANÇADO → 🔴 EXPERT
```

---

## 📊 Estrutura dos Níveis

### 🟢 Nível 1: BÁSICO (Iniciantes / Conversas Leves)

**Público-alvo:** Usuários iniciantes, conversas casuais

**Tons disponíveis:**
- 😄 **Engraçado**: Humor leve e natural
- ❤️ **Romântico**: Conexão emocional autêntica
- 😎 **Casual**: Descontraído e natural

**Características:**
- Prompts simples e diretos
- Foco em naturalidade
- Evita técnicas avançadas
- Acessível para qualquer contexto

---

### 🟡 Nível 2: AVANÇADO (Intermediário / Flerte Ativo)

**Público-alvo:** Usuários intermediários, situações de flerte

**Tons disponíveis:**
- 🔥 **Ousado**: Tensão sexual através de ambiguidade
- 💪 **Confiante**: Frame control e alto valor social

**Características:**
- Aplica **Lei da Calibragem** (espelha investimento)
- Usa técnica **Push-Pull** sutil
- Demonstra **Frame Control** moderado
- Evita elogios diretos e busca de validação

---

### 🔴 Nível 3: EXPERT MODE (Avançado / Elite)

**Público-alvo:** Usuários avançados, shit tests, situações complexas

**Tom disponível:**
- 🎯 **Expert Mode**: Dinâmica social de elite

**Características:**
Aplica **rigorosamente** as **4 Leis Fundamentais**:

#### ⚖️ LEI #1: SHIT TEST (Teste de Congruência)
- Detecta críticas, desafios e provocações
- NUNCA justifica, pede desculpas ou busca validação
- Usa "Agree & Amplify", "Ignore & Pivot" ou "Playful Misinterpretation"

#### ⚖️ LEI #2: CALIBRAGEM (Espelhamento)
- Analisa tamanho e esforço da mensagem recebida
- Espelha ou investe LIGEIRAMENTE MENOS
- Evita parecer desesperado

#### ⚖️ LEI #3: TENSÃO E SUBTEXTO
- Proíbe elogios diretos
- Usa Push-Pull, Qualificação, Cold Reading
- Cria tensão sexual através de ambiguidade

#### ⚖️ LEI #4: PRÊMIO (Frame Control)
- Posiciona o usuário como o prêmio
- Demonstra escassez e altos padrões
- Outcome independence

---

## 🔧 Arquitetura Técnica

### Arquivos Principais

```
src/
├── prompts.ts              # Sistema hierárquico de prompts
├── services/
│   └── anthropic.ts        # Integração com Claude API
└── types/
    └── index.ts            # Tipos TypeScript
```

### Como Funciona

```typescript
// 1. Usuário seleciona o tom
const selectedTone = 'expert';

// 2. Sistema seleciona o prompt correto
const systemPrompt = getSystemPromptForTone(selectedTone);

// 3. Prompt é enviado para a API
await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  system: systemPrompt,
  messages: [...]
});
```

### Função Helper

```typescript
export function getSystemPromptForTone(tone: string): string {
  // 🔴 NÍVEL 3: Expert Mode
  if (tone === 'expert') {
    return EXPERT_SYSTEM_PROMPT;
  }

  // 🟡 NÍVEL 2: Avançado
  if (tone === 'ousado' || tone === 'confiante') {
    return ADVANCED_PROMPTS[tone];
  }

  // 🟢 NÍVEL 1: Básico
  return BASIC_PROMPTS[tone];
}
```

---

## 📦 Expansão Futura (Expert Mode)

O **Expert Mode** foi projetado para ser **extensível**. Conceitos futuros podem ser adicionados em:

```typescript
// src/prompts.ts - Seção de Expansão

// ═══════════════════════════════════════════════════════════════════
// 📦 SEÇÃO DE EXPANSÃO FUTURA (EXPERT MODE)
// ═══════════════════════════════════════════════════════════════════
// Adicione novos conceitos aqui:
//
// - Lei #5: [A ser definida]
// - Lei #6: [A ser definida]
// - Técnicas de NLP (Programação Neurolinguística)
// - Padrões de linguagem de Robert Cialdini
// - Gatilhos emocionais avançados
// - Estratégias de Mystery Method
// - Técnicas de rapport acelerado
// - Etc.
// ═══════════════════════════════════════════════════════════════════
```

### Como Adicionar Novas Leis/Conceitos

1. Edite `src/prompts.ts`
2. Adicione a nova Lei/Conceito ao `EXPERT_SYSTEM_PROMPT`
3. Documente aqui em `PROMPT_SYSTEM.md`
4. Teste extensivamente
5. Compile o backend: `npm run build`

---

## 🎨 UI/UX - Seletor de Tons

### Frontend (Flutter)

Os tons são organizados visualmente por nível:

```dart
// 🟢 Nível Básico
Wrap(
  children: [
    ChoiceChip('😄 Engraçado'),
    ChoiceChip('❤️ Romântico'),
    ChoiceChip('😎 Casual'),
  ],
)

// 🟡 Nível Avançado
Wrap(
  children: [
    ChoiceChip('🔥 Ousado'),
    ChoiceChip('💪 Confiante'),
  ],
)

// 🔴 Nível Expert
ChoiceChip('🎯 Expert Mode')
```

---

## 📈 Metadados dos Tons

```typescript
export const TONE_METADATA = {
  engraçado: {
    level: 'basic',
    emoji: '😄',
    description: 'Humor leve e natural',
    difficulty: 'Iniciante',
  },
  // ... outros tons
  expert: {
    level: 'expert',
    emoji: '🎯',
    description: 'Dinâmica social de elite (4 Leis)',
    difficulty: 'Avançado',
  },
};
```

---

## 🧪 Teste e Validação

### Checklist de Qualidade (Expert Mode)

Toda resposta Expert DEVE passar por:

- ✓ Demonstra alto valor social?
- ✓ Evita buscar validação?
- ✓ Cria tensão/curiosidade?
- ✓ Espelha o input recebido?
- ✓ Usa humor e confiança?
- ✓ Posiciona usuário como prêmio?
- ✓ Evita clichês?
- ✓ Se shit test, usou Agree & Amplify ou Ignore & Pivot?

### Exemplos de Respostas

**Input (Shit Test):** "Você é baixinho?"

**❌ Resposta Ruim (Básico):**
"Na verdade tenho 1,75m haha"

**✅ Resposta Expert:**
"Cara, tenho 1,20m. Preciso de escadinha pra dar beijo"
*(Agree & Amplify - Lei #1)*

---

## 🔄 Fluxo de Processamento

```
Usuário
  ↓
Seleciona Tom (basic/advanced/expert)
  ↓
getSystemPromptForTone(tone)
  ↓
Sistema seleciona prompt correto
  ↓
Claude API gera resposta
  ↓
Validação automática (Expert: 4 Leis)
  ↓
Retorna 2-3 sugestões
```

---

## 📝 Notas de Desenvolvimento

### Por Que 3 Níveis?

1. **Acessibilidade**: Iniciantes não precisam entender "shit tests"
2. **Progressão**: Usuários podem evoluir gradualmente
3. **Contexto**: Nem toda conversa precisa de Expert Mode
4. **Flexibilidade**: Permite testar diferentes abordagens
5. **Expansibilidade**: Expert pode crescer sem afetar os outros

### Padrão de Design: Strategy Pattern

O sistema usa o **Strategy Pattern**, onde cada nível é uma estratégia diferente de geração de resposta, selecionada em runtime.

---

## 🎯 Roadmap Futuro

### Expert Mode - Conceitos a Adicionar

- [ ] **Lei #5**: Storytelling e DHV (Demonstration of Higher Value)
- [ ] **Lei #6**: Padrões de NLP (Milton Model, Meta Model)
- [ ] **Lei #7**: Gatilhos de Cialdini (Escassez, Autoridade, Prova Social)
- [ ] **Lei #8**: Escalada de Intimidade (Kino verbal)
- [ ] **Técnicas Mystery Method**: Peacocking verbal, Negs calibrados
- [ ] **False Time Constraints**: "Tenho 5 min mas..."
- [ ] **Qualification Loops**: Fazer ela trabalhar por aprovação
- [ ] **Role Reversal**: Inverter frame de pursuer/pursuee

---

## 🤝 Contribuindo

Ao adicionar novos conceitos ao Expert Mode:

1. Mantenha o padrão de documentação
2. Adicione exemplos práticos
3. Teste em cenários reais
4. Atualize este documento
5. Mantenha compatibilidade com níveis básicos

---

**Última atualização:** Dezembro 2025
**Versão:** 1.0
**Autores:** Sistema de IA Dating Assistant

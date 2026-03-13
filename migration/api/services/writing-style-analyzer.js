"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeWritingStyle = analyzeWritingStyle;
exports.buildStyleInstruction = buildStyleInstruction;

const { supabase } = require("../config/supabase");

// Common Brazilian Portuguese abbreviations
const ABBREVIATIONS = {
  "vc": "você",
  "tb": "também",
  "tbm": "também",
  "tmb": "também",
  "pq": "porque",
  "q": "que",
  "oq": "o que",
  "cmg": "comigo",
  "ctg": "contigo",
  "msg": "mensagem",
  "blz": "beleza",
  "flw": "falou",
  "vlw": "valeu",
  "pfv": "por favor",
  "obg": "obrigado",
  "td": "tudo",
  "hj": "hoje",
  "qnd": "quando",
  "qnt": "quanto",
  "dps": "depois",
  "msm": "mesmo",
  "ngm": "ninguém",
  "alg": "alguém",
  "mt": "muito",
  "mto": "muito",
  "n": "não",
  "nao": "não",
  "eh": "é",
  "ta": "está",
  "to": "estou",
  "ce": "você",
  "p": "para",
  "pra": "para",
  "pro": "para o",
  "bjs": "beijos",
  "abs": "abraços",
  "slk": "seloko",
  "vdd": "verdade",
  "nd": "nada",
  "dnv": "de novo",
  "qdo": "quando",
  "agr": "agora",
  "ss": "sim",
  "nn": "não",
  "kk": "risos",
  "kkk": "risos",
  "rs": "risos",
  "rsrs": "risos",
};

const ABBREV_KEYS = Object.keys(ABBREVIATIONS);

/**
 * Analyze an array of messages to extract writing style patterns.
 * @param {string[]} texts - Array of message texts from the user
 * @returns {object} Style profile
 */
function analyzeWritingStyle(texts) {
  if (!texts || texts.length === 0) {
    return null;
  }

  const allText = texts.join(" ");
  const words = allText.split(/\s+/).filter(w => w.length > 0);
  const totalMessages = texts.length;

  if (words.length < 5) return null;

  // --- Abbreviation detection ---
  let abbrevCount = 0;
  let totalCheckableWords = 0;
  const usedAbbreviations = new Set();

  for (const word of words) {
    const clean = word.toLowerCase().replace(/[.,!?;:()]/g, "");
    if (clean.length === 0) continue;
    totalCheckableWords++;
    if (ABBREV_KEYS.includes(clean)) {
      abbrevCount++;
      usedAbbreviations.add(clean);
    }
  }

  const abbrevRatio = totalCheckableWords > 0 ? abbrevCount / totalCheckableWords : 0;

  // --- Average message length ---
  const avgLength = texts.reduce((sum, t) => sum + t.length, 0) / totalMessages;

  // --- Punctuation usage ---
  const punctuationCount = (allText.match(/[.!?,;:]/g) || []).length;
  const punctuationRatio = punctuationCount / totalMessages;

  // --- Capitalization ---
  const sentences = texts.filter(t => t.length > 2);
  let startsWithUpper = 0;
  for (const s of sentences) {
    if (s[0] === s[0].toUpperCase() && s[0] !== s[0].toLowerCase()) {
      startsWithUpper++;
    }
  }
  const capsRatio = sentences.length > 0 ? startsWithUpper / sentences.length : 0;

  // --- Accent usage ---
  const accentWords = (allText.match(/[áàâãéèêíìîóòôõúùûç]/gi) || []).length;
  const noAccentVersions = (allText.match(/\b(nao|voce|tambem|ate|ja|so|entao|ai|agua|cafe|la|aqui|mae|pai|vc)\b/gi) || []).length;
  const usesAccents = accentWords > noAccentVersions;

  // --- Emoji usage ---
  const emojiCount = (allText.match(/[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1FA00}-\u{1FAFF}]/gu) || []).length;
  const emojiRatio = emojiCount / totalMessages;

  // --- Laugh style ---
  const kkCount = (allText.match(/\bk{2,}\b/gi) || []).length;
  const hahaCount = (allText.match(/\bha{2,}\b/gi) || []).length;
  const rsCount = (allText.match(/\brs{1,}\b/gi) || []).length;
  let laughStyle = "none";
  if (kkCount >= hahaCount && kkCount >= rsCount && kkCount > 0) laughStyle = "kk";
  else if (hahaCount >= kkCount && hahaCount >= rsCount && hahaCount > 0) laughStyle = "haha";
  else if (rsCount > 0) laughStyle = "rs";

  // --- Determine formality level ---
  let formalityLevel;
  if (abbrevRatio > 0.08 || (capsRatio < 0.3 && punctuationRatio < 1)) {
    formalityLevel = "low";
  } else if (capsRatio > 0.7 && punctuationRatio > 1.5 && abbrevRatio < 0.02) {
    formalityLevel = "high";
  } else {
    formalityLevel = "medium";
  }

  return {
    formalityLevel,
    usesAbbreviations: abbrevRatio > 0.03,
    abbreviationFrequency: abbrevRatio,
    commonAbbreviations: [...usedAbbreviations].slice(0, 10),
    avgMessageLength: Math.round(avgLength),
    usesAccents,
    usesPunctuation: punctuationRatio > 1,
    startsWithCapital: capsRatio > 0.5,
    emojiFrequency: emojiRatio,
    laughStyle,
    sampleCount: totalMessages,
  };
}

/**
 * Build a prompt instruction string from a style profile.
 * @param {object|null} style - Style profile from analyzeWritingStyle
 * @returns {string} Instruction for Claude prompt
 */
function buildStyleInstruction(style) {
  if (!style) {
    // Default: casual Brazilian style without being 100% abbreviation-heavy
    return `\nESTILO DE ESCRITA: Escreva de forma natural e casual, como um jovem brasileiro escreveria no WhatsApp. Use algumas abreviações comuns (vc, tb, pq, q) mas não em toda palavra. Não use pontuação perfeita. Comece frases com minúscula às vezes. Seja natural, não robótico.`;
  }

  const parts = [];
  parts.push("\nESTILO DE ESCRITA DO USUÁRIO (imite este estilo):");

  // Formality
  if (style.formalityLevel === "low") {
    parts.push("- Escrita informal e descontraída");
  } else if (style.formalityLevel === "high") {
    parts.push("- Escrita mais formal e bem estruturada");
  } else {
    parts.push("- Escrita semi-informal, equilibrada");
  }

  // Abbreviations
  if (style.usesAbbreviations && style.commonAbbreviations.length > 0) {
    parts.push(`- Usa abreviações como: ${style.commonAbbreviations.join(", ")}`);
    if (style.abbreviationFrequency > 0.12) {
      parts.push("- Usa MUITAS abreviações, quase toda palavra possível é abreviada");
    } else {
      parts.push("- Usa abreviações às vezes, mas não em toda palavra");
    }
  } else {
    parts.push("- Não costuma usar abreviações, escreve as palavras completas");
  }

  // Accents
  if (!style.usesAccents) {
    parts.push("- Não usa acentos (escreve 'voce' em vez de 'você', 'nao' em vez de 'não')");
  } else {
    parts.push("- Usa acentos corretamente");
  }

  // Capitalization
  if (!style.startsWithCapital) {
    parts.push("- Começa frases com letra minúscula");
  }

  // Punctuation
  if (!style.usesPunctuation) {
    parts.push("- Quase não usa pontuação");
  }

  // Message length
  if (style.avgMessageLength < 30) {
    parts.push("- Mensagens bem curtas e diretas");
  } else if (style.avgMessageLength > 100) {
    parts.push("- Mensagens mais longas e detalhadas");
  }

  // Emoji
  if (style.emojiFrequency > 0.5) {
    parts.push("- Usa emojis com frequência");
  } else if (style.emojiFrequency < 0.1) {
    parts.push("- Raramente usa emojis");
  }

  // Laugh style
  if (style.laughStyle !== "none") {
    const laughMap = { kk: "kkk/kkkk", haha: "haha/hahaha", rs: "rs/rsrs" };
    parts.push(`- Quando ri, usa: ${laughMap[style.laughStyle]}`);
  }

  return parts.join("\n");
}

/**
 * Get user's writing style by analyzing their outbound WhatsApp messages
 * and/or their messages in app conversations.
 * @param {string} userId - Supabase user ID
 * @returns {Promise<object|null>} Style profile or null
 */
async function getUserWritingStyle(userId) {
  const texts = [];

  // Source 1: WhatsApp outbound messages (from Baileys/desenrola-sync)
  try {
    const { data: whatsappMsgs } = await supabase
      .from("messages")
      .select("text")
      .eq("user_id", userId)
      .eq("direction", "outbound")
      .not("text", "is", null)
      .order("ts", { ascending: false })
      .limit(100);

    if (whatsappMsgs && whatsappMsgs.length > 0) {
      for (const m of whatsappMsgs) {
        if (m.text && m.text.trim().length > 2) {
          texts.push(m.text.trim());
        }
      }
    }
  } catch (e) {
    // messages table might not exist yet for this user, that's ok
  }

  // Source 2: User messages from app conversations (role="user", source="keyboard")
  try {
    const { data: convs } = await supabase
      .from("conversations")
      .select("messages")
      .eq("user_id", userId)
      .order("last_message_at", { ascending: false })
      .limit(10);

    if (convs) {
      for (const conv of convs) {
        const msgs = conv.messages || [];
        for (const m of msgs) {
          if (m.role === "user" && !m.wasAiSuggestion && m.content && m.content.trim().length > 2) {
            texts.push(m.content.trim());
          }
        }
      }
    }
  } catch (e) {
    // non-critical
  }

  if (texts.length < 5) return null;

  return analyzeWritingStyle(texts);
}

exports.getUserWritingStyle = getUserWritingStyle;

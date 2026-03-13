"use strict";

const Fastify = require("fastify");
const cors = require("@fastify/cors");
const env_1 = require("./config/env");
const anthropic_1 = require("./services/anthropic");
const agents_1 = require("./agents");
const conversation_manager_1 = require("./services/conversation-manager");
const prompts_1 = require("./prompts");
const stripe_1 = require("./services/stripe");
const auth_1 = require("./middleware/auth");
const { verifyRequestSignature } = require("./middleware/auth");
const instagram_crop_service_1 = require("./services/instagram-crop-service");
const { supabase } = require("./config/supabase");
const firebaseSync = require("./services/firebase-sync");
const { getUserWritingStyle, buildStyleInstruction } = require("./services/writing-style-analyzer");
const Stripe = require("stripe");

const fastify = Fastify({ logger: true });

// ═══════════════════════════════════════════════════════════════════
// CORS (restricted to trusted origins)
// ═══════════════════════════════════════════════════════════════════
fastify.register(cors, {
  origin: [
    "https://desenrola-ia.web.app",
    "https://desenrola-ia.firebaseapp.com",
    "https://desenrolaai.site",
    "https://api.desenrolaai.site",
  ],
});

// Rate limiting
fastify.register(require("@fastify/rate-limit"), {
  max: 15,
  timeWindow: "1 minute",
  keyGenerator: (request) => {
    return request.user?.uid || request.ip;
  },
});

// Raw body parser for Stripe webhooks
fastify.addContentTypeParser(
  "application/json",
  { parseAs: "buffer" },
  (req, body, done) => {
    req.rawBody = body;
    try {
      const json = JSON.parse(body.toString());
      done(null, json);
    } catch (err) {
      done(err, undefined);
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// HELPER: Resolve Firebase UID to Supabase UUID via mapping table
// ═══════════════════════════════════════════════════════════════════
async function resolveFirebaseUidToSupabase(firebaseUid) {
  const { data, error } = await supabase
    .from("user_id_mapping")
    .select("supabase_uid")
    .eq("firebase_uid", firebaseUid)
    .single();

  if (error || !data) return null;
  return data.supabase_uid;
}

// ═══════════════════════════════════════════════════════════════════
// HELPER: Extract profile tags for collective intelligence
// ═══════════════════════════════════════════════════════════════════
function extractProfileTags(bio, photoDescription) {
  const tags = [];
  const text = `${bio || ""} ${photoDescription || ""}`.toLowerCase();

  const categories = {
    praia: ["praia", "mar", "surf", "beach", "litoral", "verao"],
    fitness: [
      "academia",
      "gym",
      "crossfit",
      "treino",
      "fitness",
      "musculacao",
      "corrida",
    ],
    viagem: ["viagem", "viajar", "travel", "mochilao", "aventura", "mundo"],
    musica: [
      "musica",
      "show",
      "festival",
      "rock",
      "sertanejo",
      "pagode",
      "funk",
      "mpb",
      "rap",
    ],
    pagode: ["pagode", "samba", "roda de samba"],
    sertanejo: ["sertanejo", "country", "rodeio"],
    balada: ["balada", "festa", "night", "club", "role"],
    gastronomia: [
      "comida",
      "restaurante",
      "culinaria",
      "chef",
      "cozinhar",
      "foodie",
    ],
    pets: ["cachorro", "gato", "pet", "dog", "cat", "animal"],
    natureza: ["natureza", "trilha", "camping", "montanha", "cachoeira"],
    arte: ["arte", "museu", "teatro", "cinema", "fotografia"],
    livros: ["livro", "leitura", "ler", "literatura"],
    games: ["game", "jogo", "gamer", "playstation", "xbox", "nintendo"],
    esporte: ["futebol", "volei", "basquete", "tenis", "esporte"],
    cerveja: ["cerveja", "beer", "bar", "happy hour", "drinks", "vinho"],
    cafe: ["cafe", "coffee", "cafeteria"],
    netflix: ["netflix", "serie", "series", "filme", "maratonar"],
    tattoo: ["tattoo", "tatuagem", "tatuado"],
    signo_agua: [
      "cancer",
      "canceriana",
      "escorpiao",
      "escorpiana",
      "peixes",
      "pisciana",
    ],
    signo_fogo: [
      "aries",
      "ariana",
      "leao",
      "leonina",
      "sagitario",
      "sagitariana",
    ],
    signo_terra: [
      "touro",
      "taurina",
      "virgem",
      "virginiana",
      "capricornio",
      "capricorniana",
    ],
    signo_ar: [
      "gemeos",
      "geminiana",
      "libra",
      "libriana",
      "aquario",
      "aquariana",
    ],
  };

  for (const [tag, keywords] of Object.entries(categories)) {
    if (keywords.some((kw) => text.includes(kw))) {
      tags.push(tag);
    }
  }
  return tags;
}

// ═══════════════════════════════════════════════════════════════════
// HELPER: Get collective insights by tags from Supabase
// ═══════════════════════════════════════════════════════════════════
async function getInsightsByTags(tags, platform) {
  if (tags.length === 0) return null;
  try {
    const docIds = tags.map((tag) => `${tag}_${platform}`);

    const { data: rows, error } = await supabase
      .from("tag_insights")
      .select("*")
      .in("id", docIds);

    if (error || !rows || rows.length === 0) return null;

    const allInsights = {
      whatWorks: [],
      whatDoesntWork: [],
      goodExamples: [],
      badExamples: [],
      bestTypes: [],
      matchedTags: [],
    };

    for (const row of rows) {
      allInsights.matchedTags.push(row.tag || row.id.split("_")[0]);
      if (row.what_works) allInsights.whatWorks.push(...row.what_works);
      if (row.what_doesnt_work)
        allInsights.whatDoesntWork.push(...row.what_doesnt_work);
      if (row.good_examples) allInsights.goodExamples.push(...row.good_examples);
      if (row.bad_examples) allInsights.badExamples.push(...row.bad_examples);
      if (row.best_types) allInsights.bestTypes.push(...row.best_types);
    }

    // Deduplicate
    allInsights.whatWorks = [...new Set(allInsights.whatWorks)].slice(0, 5);
    allInsights.whatDoesntWork = [...new Set(allInsights.whatDoesntWork)].slice(
      0,
      5
    );
    allInsights.goodExamples = [...new Set(allInsights.goodExamples)].slice(
      0,
      5
    );
    allInsights.badExamples = [...new Set(allInsights.badExamples)].slice(0, 3);
    allInsights.bestTypes = [...new Set(allInsights.bestTypes)].slice(0, 3);

    return allInsights.matchedTags.length > 0 ? allInsights : null;
  } catch (err) {
    console.error("Erro ao buscar insights por tags:", err);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPER: getFormattedHistory (inline implementation)
// ═══════════════════════════════════════════════════════════════════
function getFormattedHistory(conversation) {
  const messages = conversation.messages || [];
  const avatar = conversation.avatar || {};
  const matchName = avatar.matchName || avatar.name || "Match";

  let historyStr =
    "═══════════════════════════════════════════════════════════════════\n";
  historyStr += `PERFIL DO MATCH: ${matchName}\n`;
  if (avatar.platform) historyStr += `Plataforma: ${avatar.platform}\n`;
  if (avatar.bio) historyStr += `Bio: ${avatar.bio}\n`;

  // Calibration info
  const patterns = avatar.detectedPatterns || {};
  if (patterns.responseLength)
    historyStr += `Tamanho de resposta dela: ${patterns.responseLength}\n`;
  if (patterns.emotionalTone)
    historyStr += `Tom emocional: ${patterns.emotionalTone}\n`;
  if (patterns.flirtLevel)
    historyStr += `Nivel de flerte: ${patterns.flirtLevel}\n`;

  historyStr +=
    "═══════════════════════════════════════════════════════════════════\n\n";
  historyStr += "HISTORICO DA CONVERSA:\n";

  const recentMessages = messages.slice(-20);
  for (const msg of recentMessages) {
    const role = msg.role === "user" ? "Voce" : matchName;
    historyStr += `${role}: ${msg.content}\n`;
  }

  return historyStr;
}

// ═══════════════════════════════════════════════════════════════════
// ROUTE SCHEMAS
// ═══════════════════════════════════════════════════════════════════
const analyzeSchema = {
  body: {
    type: "object",
    required: ["text", "tone"],
    properties: {
      text: { type: "string", minLength: 1 },
      tone: {
        type: "string",
        enum: [
          "automatico",
          "engracado",
          "ousado",
          "romantico",
          "casual",
          "confiante",
          "expert",
        ],
      },
      conversationId: { type: "string" },
      objective: {
        type: "string",
        enum: [
          "automatico",
          "pegar_numero",
          "marcar_encontro",
          "modo_intimo",
          "mudar_plataforma",
          "reacender",
          "virar_romantico",
          "video_call",
          "pedir_desculpas",
          "criar_conexao",
        ],
      },
    },
  },
};

// ═══════════════════════════════════════════════════════════════════
// 1. POST /analyze - Text analysis with PRO/BASIC mode
// ═══════════════════════════════════════════════════════════════════
fastify.post("/analyze", { schema: analyzeSchema }, async (request, reply) => {
  try {
    const { text, tone, conversationId, objective } = request.body;

    // PRO MODE: If conversationId is provided, use rich context pipeline
    if (conversationId) {
      try {
        // Inline auth: verify Firebase token, then resolve to Supabase UUID
        let userId = null;
        const authHeader = request.headers.authorization;
        if (authHeader && authHeader.startsWith("Bearer ")) {
          try {
            const token = authHeader.split(" ")[1];
            // Use firebase-admin to verify token during migration period
            const admin = require("firebase-admin");
            const decoded = await admin.auth().verifyIdToken(token);
            const firebaseUid = decoded.uid;
            // Resolve Firebase UID to Supabase UUID
            userId = await resolveFirebaseUidToSupabase(firebaseUid);
          } catch (e) {
            // Token invalid, continue without auth
          }
        }

        if (userId) {
          // Get conversation from Supabase
          const { data: convData, error: convError } = await supabase
            .from("conversations")
            .select("*")
            .eq("id", conversationId)
            .eq("user_id", userId)
            .single();

          if (!convError && convData) {
            // Save clipboard text as match's message
            const matchMessage = {
              id: `kb_match_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
              role: "match",
              content: text,
              timestamp: new Date().toISOString(),
              source: "keyboard_clipboard",
            };

            await supabase.rpc("append_message", {
              conv_id: conversationId,
              new_message: matchMessage,
            });
            firebaseSync.syncMessageAppend(conversationId, matchMessage);

            // Re-fetch updated conversation
            const { data: updatedConv } = await supabase
              .from("conversations")
              .select("*")
              .eq("id", conversationId)
              .single();

            const messages = updatedConv.messages || [];
            const avatar = updatedConv.avatar || {};

            // Build rich context prompt
            let historyStr = "";
            const recentMessages = messages.slice(-20);
            for (const msg of recentMessages) {
              const role =
                msg.role === "user"
                  ? "Voce"
                  : avatar.matchName || "Match";
              historyStr += `${role}: ${msg.content}\n`;
            }

            // Get collective insights if available
            let collectiveStr = "";
            if (updatedConv.collective_avatar_id) {
              const { data: avatarDoc } = await supabase
                .from("collective_avatars")
                .select("collective_insights")
                .eq("id", updatedConv.collective_avatar_id)
                .single();

              if (avatarDoc) {
                const ci = avatarDoc.collective_insights || {};
                if (ci.whatWorks && ci.whatWorks.length > 0) {
                  collectiveStr = `\nO que funciona com essa pessoa: ${ci.whatWorks.join(", ")}`;
                }
                if (ci.whatDoesntWork && ci.whatDoesntWork.length > 0) {
                  collectiveStr += `\nO que NAO funciona: ${ci.whatDoesntWork.join(", ")}`;
                }
              }
            }

            // Build calibration info
            let calibrationStr = "";
            const patterns = avatar.detectedPatterns || {};
            if (patterns.responseLength) {
              calibrationStr += `\nTamanho de resposta dela: ${patterns.responseLength}`;
            }
            if (patterns.emotionalTone) {
              calibrationStr += `\nTom emocional: ${patterns.emotionalTone}`;
            }
            if (patterns.flirtLevel) {
              calibrationStr += `\nNivel de flerte: ${patterns.flirtLevel}`;
            }

            const objectiveInstruction = prompts_1.getObjectivePrompt(
              objective || "automatico"
            );

            // Analyze user's writing style (WhatsApp history + app messages)
            let styleInstruction = "";
            try {
              const userStyle = await getUserWritingStyle(userId);
              styleInstruction = buildStyleInstruction(userStyle);
            } catch (styleErr) {
              styleInstruction = buildStyleInstruction(null);
              fastify.log.warn("Style analysis error (using default):", styleErr.message);
            }

            const richPrompt = `Voce esta ajudando a responder mensagens de dating.
Perfil da match: ${avatar.matchName || "Desconhecida"} (${avatar.platform || "dating app"})
${avatar.bio ? `Bio: ${avatar.bio}` : ""}
${calibrationStr}
${collectiveStr}
${styleInstruction}

${objectiveInstruction}

Historico recente:
${historyStr}

A ultima mensagem dela foi:
"${text}"

Gere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).
Calibre com base no historico, tom detectado, OBJETIVO e ESTILO DE ESCRITA definidos acima.`;

            const analysis = await anthropic_1.analyzeMessage({
              text: richPrompt,
              tone,
            });
            return reply.code(200).send({ analysis, mode: "pro" });
          }
        }
      } catch (proError) {
        fastify.log.error("PRO mode error, falling back to BASIC:", proError);
        // Fall through to BASIC mode
      }
    }

    // BASIC MODE: Simple analysis without context
    const basicObjective = prompts_1.getObjectivePrompt(
      objective || "automatico"
    );
    // Even in basic mode, try to get user's writing style if authenticated
    let basicStyleStr = buildStyleInstruction(null); // default casual style
    try {
      const authHeader = request.headers.authorization;
      if (authHeader && authHeader.startsWith("Bearer ")) {
        const token = authHeader.split(" ")[1];
        const admin = require("firebase-admin");
        const decoded = await admin.auth().verifyIdToken(token);
        const basicUserId = await resolveFirebaseUidToSupabase(decoded.uid);
        if (basicUserId) {
          const userStyle = await getUserWritingStyle(basicUserId);
          if (userStyle) basicStyleStr = buildStyleInstruction(userStyle);
        }
      }
    } catch (e) { /* non-critical, use default */ }
    const textWithObjective = `${basicObjective}\n${basicStyleStr}\n\nMensagem recebida:\n"${text}"\n\nGere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases). Siga o ESTILO DE ESCRITA definido acima.`;
    const analysis = await anthropic_1.analyzeMessage({
      text: textWithObjective,
      tone,
    });
    const response = {
      analysis,
      mode: "basic",
    };
    return reply.code(200).send(response);
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao processar analise",
      message: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 2. GET /health
// ═══════════════════════════════════════════════════════════════════
fastify.get("/health", async (request, reply) => {
  return { status: "ok", timestamp: new Date().toISOString() };
});

// ═══════════════════════════════════════════════════════════════════
// 3. POST /analyze-profile
// ═══════════════════════════════════════════════════════════════════
fastify.post("/analyze-profile", async (request, reply) => {
  try {
    const { bio, platform, photoDescription, name, age, userContext } =
      request.body;
    const agent = new agents_1.ProfileAnalyzerAgent();
    const result = await agent.execute(
      { bio, platform, photoDescription, name, age },
      userContext
    );
    return reply.code(200).send({ analysis: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao analisar perfil",
      message: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 4. POST /generate-first-message
// ═══════════════════════════════════════════════════════════════════
fastify.post("/generate-first-message", async (request, reply) => {
  try {
    const {
      matchName,
      matchBio,
      platform,
      tone,
      photoDescription,
      specificDetail,
      userContext,
    } = request.body;

    // Extract profile tags for collective insights lookup
    const profileTags = extractProfileTags(matchBio, photoDescription);

    // Get insights from Supabase tag_insights table
    let collectiveInsights;
    try {
      const insights = await getInsightsByTags(
        profileTags,
        platform || "tinder"
      );
      if (insights) {
        collectiveInsights = {
          whatWorks: insights.whatWorks,
          whatDoesntWork: insights.whatDoesntWork,
          goodOpenerExamples: insights.goodExamples,
          badOpenerExamples: insights.badExamples,
          bestOpenerTypes: insights.bestTypes,
          matchedTags: insights.matchedTags,
        };
      }
    } catch (err) {
      console.warn("Nao foi possivel buscar insights coletivos:", err);
    }

    const agent = new agents_1.FirstMessageAgent();
    const result = await agent.execute(
      {
        matchName,
        matchBio,
        platform,
        tone,
        photoDescription,
        specificDetail,
        collectiveInsights,
      },
      userContext
    );
    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao gerar primeira mensagem",
      message: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 5. POST /generate-instagram-opener
// ═══════════════════════════════════════════════════════════════════
fastify.post("/generate-instagram-opener", async (request, reply) => {
  try {
    const {
      username,
      bio,
      recentPosts,
      stories,
      tone,
      approachType,
      specificPost,
      userContext,
    } = request.body;

    // Extract profile tags
    const allText = [bio, ...(recentPosts || []), ...(stories || [])]
      .filter(Boolean)
      .join(" ");
    const profileTags = extractProfileTags(allText);

    // Get insights from Supabase tag_insights table
    let collectiveInsights;
    try {
      const insights = await getInsightsByTags(profileTags, "instagram");
      if (insights) {
        collectiveInsights = {
          whatWorks: insights.whatWorks,
          whatDoesntWork: insights.whatDoesntWork,
          goodOpenerExamples: insights.goodExamples,
          badOpenerExamples: insights.badExamples,
          matchedTags: insights.matchedTags,
        };
      }
    } catch (err) {
      console.warn("Nao foi possivel buscar insights coletivos:", err);
    }

    const agent = new agents_1.InstagramOpenerAgent();
    const result = await agent.execute(
      {
        username,
        bio,
        recentPosts,
        stories,
        tone,
        approachType,
        specificPost,
        collectiveInsights,
      },
      userContext
    );
    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao gerar abertura do Instagram",
      message: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 6. POST /reply
// ═══════════════════════════════════════════════════════════════════
fastify.post("/reply", async (request, reply) => {
  try {
    const {
      receivedMessage,
      conversationHistory,
      tone,
      matchName,
      context,
      userContext,
    } = request.body;
    const agent = new agents_1.ConversationReplyAgent();
    const result = await agent.execute(
      { receivedMessage, conversationHistory, tone, matchName, context },
      userContext
    );
    return reply.code(200).send({ suggestions: result });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao gerar resposta",
      message: error instanceof Error ? error.message : "Erro desconhecido",
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 7. POST /analyze-profile-image
// ═══════════════════════════════════════════════════════════════════
fastify.post("/analyze-profile-image", async (request, reply) => {
  try {
    const { imageBase64, imageMediaType, platform } = request.body;

    if (!imageBase64) {
      return reply.code(400).send({
        error: "Imagem nao fornecida",
        message: "O campo imageBase64 e obrigatorio",
      });
    }

    const agent = new agents_1.ProfileImageAnalyzerAgent();
    const result = await agent.analyzeImageAndParse({
      imageBase64,
      imageMediaType: imageMediaType || "image/jpeg",
      platform,
    });

    // For Instagram: server-side crop using OpenCV HoughCircles
    let croppedFaceBase64 = null;
    if (platform && platform.toLowerCase() === "instagram") {
      try {
        const cropResult =
          await instagram_crop_service_1.InstagramCropService.cropProfilePhoto(
            imageBase64
          );
        if (cropResult.success && cropResult.croppedFaceBase64) {
          croppedFaceBase64 = cropResult.croppedFaceBase64;
          console.log(
            `Instagram face crop: method=${cropResult.method}` +
              (cropResult.circle
                ? ` circle=(${cropResult.circle.x},${cropResult.circle.y}) r=${cropResult.circle.r}`
                : "")
          );
        }
      } catch (cropError) {
        console.warn(
          "Instagram crop failed, client will use fallback:",
          cropError.message
        );
      }
    }

    return reply.code(200).send({
      extractedData: result,
      ...(croppedFaceBase64 ? { croppedFaceBase64 } : {}),
    });
  } catch (error) {
    console.error("Erro ao analisar imagem:", error);
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Erro ao analisar imagem",
      message: error instanceof Error ? error.message : "Erro desconhecido",
      stack: error instanceof Error ? error.stack : undefined,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 8. CONVERSATION CRUD ENDPOINTS (with auth)
// ═══════════════════════════════════════════════════════════════════

// POST /conversations - Create new conversation
fastify.post(
  "/conversations",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const body = request.body;
      const userId = request.user.uid;
      const conversation =
        await conversation_manager_1.ConversationManager.createConversation({
          ...body,
          userId,
        });
      return reply.code(201).send(conversation);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao criar conversa",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// GET /conversations - List user conversations
fastify.get(
  "/conversations",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const userId = request.user.uid;
      const conversations =
        await conversation_manager_1.ConversationManager.listConversations(
          userId
        );
      return reply.code(200).send(conversations);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao listar conversas",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// GET /conversations/:id - Get specific conversation
fastify.get(
  "/conversations/:id",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const conversation =
        await conversation_manager_1.ConversationManager.getConversation(
          id,
          userId
        );
      if (!conversation) {
        return reply.code(404).send({ error: "Conversa nao encontrada" });
      }
      return reply.code(200).send(conversation);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao obter conversa",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// POST /conversations/:id/messages - Add message to conversation
fastify.post(
  "/conversations/:id/messages",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const body = request.body;
      const conversation =
        await conversation_manager_1.ConversationManager.addMessage({
          conversationId: id,
          userId,
          ...body,
        });
      return reply.code(200).send(conversation);
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao adicionar mensagem",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// POST /conversations/:id/suggestions - Generate suggestions from full history
fastify.post(
  "/conversations/:id/suggestions",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const { receivedMessage, tone, userContext } = request.body;

      const conversation =
        await conversation_manager_1.ConversationManager.getConversation(
          id,
          userId
        );
      if (!conversation) {
        return reply.code(404).send({ error: "Conversa nao encontrada" });
      }

      // Add the received message to history
      await conversation_manager_1.ConversationManager.addMessage({
        conversationId: id,
        userId,
        role: "match",
        content: receivedMessage,
      });

      // Get formatted history inline (since we have the conversation data)
      // Re-fetch after adding message
      const updatedConversation =
        await conversation_manager_1.ConversationManager.getConversation(
          id,
          userId
        );
      const formattedHistory = getFormattedHistory(
        updatedConversation || conversation
      );

      // Select prompt based on tone
      const systemPrompt = prompts_1.getSystemPromptForTone(tone);

      // Build user context string
      let userContextStr = "";
      if (userContext) {
        userContextStr = `
═══════════════════════════════════════════════════════════════════
SEU PERFIL
═══════════════════════════════════════════════════════════════════
${userContext.name ? `Nome: ${userContext.name}` : ""}
${userContext.age ? `Idade: ${userContext.age}` : ""}
${userContext.interests && userContext.interests.length > 0 ? `Interesses: ${userContext.interests.join(", ")}` : ""}
${userContext.dislikes && userContext.dislikes.length > 0 ? `EVITE mencionar: ${userContext.dislikes.join(", ")}` : ""}
${userContext.humorStyle ? `Estilo de humor: ${userContext.humorStyle}` : ""}
${userContext.relationshipGoal ? `Objetivo: ${userContext.relationshipGoal}` : ""}
`;
      }

      // Analyze user's writing style
      let convStyleStr = "";
      try {
        const userStyle = await getUserWritingStyle(userId);
        convStyleStr = buildStyleInstruction(userStyle);
      } catch (e) {
        convStyleStr = buildStyleInstruction(null);
      }

      // Generate suggestions using Claude
      const fullPrompt = `${systemPrompt}\n\n${formattedHistory}\n${userContextStr}
${convStyleStr}

A mensagem mais recente que voce acabou de receber foi:
"${receivedMessage}"

Com base em TODO o contexto acima (perfil do match, calibragem detectada, historico completo, ESTILO DE ESCRITA), gere APENAS 3 sugestoes de resposta que:
1. ESPELHEM o tamanho de resposta detectado
2. ADAPTEM ao tom emocional detectado
3. SIGAM o estilo de escrita do usuario definido acima
4. AVANCEM a interacao de forma natural`;

      const response = await anthropic_1.analyzeMessage({
        text: fullPrompt,
        tone: tone,
      });
      return reply.code(200).send({ suggestions: response });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao gerar sugestoes",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// PATCH /conversations/:id/tone - Update conversation tone
fastify.patch(
  "/conversations/:id/tone",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const { tone } = request.body;
      await conversation_manager_1.ConversationManager.updateTone(
        id,
        userId,
        tone
      );
      return reply.code(200).send({ success: true });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao atualizar tom",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// DELETE /conversations/:id - Delete conversation
fastify.delete(
  "/conversations/:id",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const deleted =
        await conversation_manager_1.ConversationManager.deleteConversation(
          id,
          userId
        );
      if (!deleted) {
        return reply.code(404).send({ error: "Conversa nao encontrada" });
      }
      return reply.code(200).send({ success: true });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao deletar conversa",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// 9. POST /conversations/:id/feedback - Submit message feedback
// ═══════════════════════════════════════════════════════════════════
fastify.post(
  "/conversations/:id/feedback",
  { preHandler: auth_1.verifyAuth },
  async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.uid;
      const { messageId, gotResponse, responseQuality } = request.body;

      await conversation_manager_1.ConversationManager.submitMessageFeedback(
        id,
        userId,
        messageId,
        gotResponse,
        responseQuality
      );
      return reply.code(200).send({ success: true });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao submeter feedback",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// 10. STRIPE ENDPOINTS
// ═══════════════════════════════════════════════════════════════════

// POST /create-checkout-session (verifyAuthOnly - user may not have subscription yet)
fastify.post(
  "/create-checkout-session",
  { preHandler: auth_1.verifyAuthOnly },
  async (request, reply) => {
    try {
      const { priceId, plan } = request.body;
      const user = request.user;

      if (!user.email) {
        return reply.code(400).send({
          error: "Email not found",
          message: "User email is required to create checkout session",
        });
      }

      const session = await stripe_1.createCheckoutSession({
        priceId,
        plan,
        userId: user.uid,
        userEmail: user.email,
      });

      return reply.code(200).send({
        url: session.url,
        sessionId: session.id,
      });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Failed to create checkout session",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

// POST /create-checkout-redirect (no auth - for funnel pages)
fastify.post("/create-checkout-redirect", async (request, reply) => {
  try {
    const { priceId, plan, email, name, source } = request.body;

    if (!priceId || !plan) {
      return reply.code(400).send({
        error: "Missing required fields",
        message: "priceId and plan are required",
      });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", {
      apiVersion: "2023-10-16",
    });

    const frontendUrl =
      process.env.FRONTEND_URL || "https://desenrola-ia.web.app";

    // Build checkout session params
    const sessionParams = {
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${frontendUrl}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${frontendUrl}/subscription/cancelled`,
      metadata: {
        plan,
        source: source || "funnel_redirect",
      },
      subscription_data: {
        metadata: {
          plan,
          source: source || "funnel_redirect",
        },
      },
      allow_promotion_codes: true,
      billing_address_collection: "required",
    };

    // Pre-fill email if provided
    if (email) {
      // Try to find existing customer
      const existingCustomers = await stripe.customers.list({
        email,
        limit: 1,
      });

      if (existingCustomers.data.length > 0) {
        sessionParams.customer = existingCustomers.data[0].id;
      } else {
        sessionParams.customer_email = email;
      }
    }

    const session = await stripe.checkout.sessions.create(sessionParams);

    console.log("Checkout redirect session created:", {
      sessionId: session.id,
      plan,
      priceId,
      source,
    });

    return reply.code(200).send({
      url: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Failed to create checkout session",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// GET /unsubscribe/:leadId
fastify.get("/unsubscribe/:leadId", async (request, reply) => {
  try {
    const { leadId } = request.params;

    // Look up user by leadId in Supabase
    const { data: userData, error } = await supabase
      .from("users")
      .select("id, email, subscription_status, stripe_customer_id")
      .eq("id", leadId)
      .single();

    if (error || !userData) {
      return reply.code(404).send({
        error: "Lead not found",
        message: "No user found with the provided ID",
      });
    }

    // If they have a Stripe subscription, cancel it
    if (userData.stripe_customer_id) {
      try {
        const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", {
          apiVersion: "2023-10-16",
        });

        const subscriptions = await stripe.subscriptions.list({
          customer: userData.stripe_customer_id,
          status: "active",
          limit: 1,
        });

        if (subscriptions.data.length > 0) {
          await stripe.subscriptions.cancel(subscriptions.data[0].id);
        }
      } catch (stripeErr) {
        console.error("Stripe cancellation error:", stripeErr.message);
      }
    }

    // Update Supabase user
    await supabase
      .from("users")
      .update({
        subscription_status: "cancelled",
        subscription_cancelled_at: new Date().toISOString(),
      })
      .eq("id", leadId);

    return reply.code(200).send({
      success: true,
      message: "Subscription cancelled successfully",
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Failed to unsubscribe",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// GET /api/checkout/session - Get checkout session details
fastify.get("/api/checkout/session", async (request, reply) => {
  try {
    const { session_id } = request.query;

    if (!session_id) {
      return reply.code(400).send({
        error: "Missing session_id",
        message: "session_id query parameter is required",
      });
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", {
      apiVersion: "2023-10-16",
    });

    const session = await stripe.checkout.sessions.retrieve(session_id);

    return reply.code(200).send({
      id: session.id,
      status: session.status,
      payment_status: session.payment_status,
      customer_email:
        session.customer_email || session.customer_details?.email,
      subscription: session.subscription,
      metadata: session.metadata,
    });
  } catch (error) {
    fastify.log.error(error);
    return reply.code(500).send({
      error: "Failed to retrieve session",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// POST /webhook/stripe - Stripe webhook handler
fastify.post("/webhook/stripe", async (request, reply) => {
  const sig = request.headers["stripe-signature"];
  if (!sig) {
    console.error("Missing stripe-signature header");
    return reply.code(400).send({ error: "Missing signature" });
  }

  let event;
  try {
    const rawBody = request.rawBody;
    event = stripe_1.constructWebhookEvent(rawBody, sig);
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return reply.code(400).send({ error: `Webhook Error: ${err.message}` });
  }

  console.log("Stripe webhook received:", event.type);

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await stripe_1.handleCheckoutCompleted(event.data.object);
        break;
      case "customer.subscription.updated":
        await stripe_1.handleSubscriptionUpdated(event.data.object);
        break;
      case "customer.subscription.deleted":
        await stripe_1.handleSubscriptionDeleted(event.data.object);
        break;
      case "invoice.paid":
        await stripe_1.handleInvoicePaid(event.data.object);
        break;
      case "invoice.payment_failed":
        await stripe_1.handlePaymentFailed(event.data.object);
        break;
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
    return reply.code(200).send({ received: true });
  } catch (error) {
    console.error("Error processing webhook:", error);
    return reply.code(500).send({
      error: "Internal server error",
      message: error.message,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 11. KEYBOARD EXTENSION ENDPOINTS
// ═══════════════════════════════════════════════════════════════════

// GET /keyboard/context - Returns profiles with photos and linked conversations
fastify.get(
  "/keyboard/context",
  { preHandler: [verifyRequestSignature, auth_1.verifyAuth] },
  async (request, reply) => {
    try {
      const userId = request.user.uid;

      // Query Supabase profiles and conversations tables
      const [profilesResult, convsResult] = await Promise.all([
        supabase
          .from("profiles")
          .select("*")
          .eq("user_id", userId)
          .order("updated_at", { ascending: false })
          .limit(20),
        supabase
          .from("conversations")
          .select("*")
          .eq("user_id", userId)
          .eq("status", "active"),
      ]);

      const profiles = profilesResult.data || [];
      const conversations = convsResult.data || [];

      // Build profile photo map: lowercase name -> faceImageBase64
      const photoMap = {};
      const profileIdMap = {};
      for (const profile of profiles) {
        const key = (profile.name || "").toLowerCase();
        photoMap[key] = profile.face_image_base64 || null;
        profileIdMap[key] = profile.id;
      }

      // Build entries from conversations (each has its own platform)
      const seenKeys = new Set();
      const entries = [];

      // Sort conversations by last_message_at desc
      const sortedConvs = conversations
        .map((conv) => ({
          conv,
          lastMessageAt: conv.last_message_at
            ? new Date(conv.last_message_at)
            : new Date(0),
        }))
        .sort((a, b) => b.lastMessageAt - a.lastMessageAt);

      for (const { conv } of sortedConvs) {
        const avatar = conv.avatar || {};
        const matchName = avatar.matchName || avatar.name || "Desconhecida";
        const platform = avatar.platform || "tinder";
        const key = `${matchName.toLowerCase()}_${platform}`;

        if (seenKeys.has(key)) continue; // dedupe same name+platform
        seenKeys.add(key);

        const nameKey = matchName.toLowerCase();
        entries.push({
          conversationId: conv.id,
          profileId: profileIdMap[nameKey] || null,
          matchName,
          platform,
          faceImageBase64: photoMap[nameKey] || null,
        });
      }

      // Add profiles that have NO conversation yet
      for (const profile of profiles) {
        const name = profile.name || "Sem nome";
        const platforms = profile.platforms || {};
        const firstPlatformKey = Object.keys(platforms)[0];
        const platform = firstPlatformKey
          ? platforms[firstPlatformKey].type || firstPlatformKey
          : "instagram";
        const key = `${name.toLowerCase()}_${platform}`;

        if (!seenKeys.has(key)) {
          seenKeys.add(key);
          entries.push({
            conversationId: null,
            profileId: profile.id,
            matchName: name,
            platform,
            faceImageBase64: profile.face_image_base64 || null,
          });
        }
      }

      return reply.code(200).send({ conversations: entries });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao buscar contexto do teclado",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// POST /keyboard/send-message - Save message sent via keyboard extension
fastify.post(
  "/keyboard/send-message",
  { preHandler: [verifyRequestSignature, auth_1.verifyAuth] },
  async (request, reply) => {
    try {
      const userId = request.user.uid;
      const {
        conversationId,
        profileId,
        content,
        wasAiSuggestion,
        tone,
        objective,
      } = request.body;

      if (!content) {
        return reply.code(400).send({
          error: "Missing required fields",
          message: "content is required",
        });
      }

      if (!conversationId && !profileId) {
        return reply.code(400).send({
          error: "Missing required fields",
          message: "conversationId or profileId is required",
        });
      }

      let activeConversationId = conversationId;

      // Auto-create conversation if only profileId provided
      if (!activeConversationId && profileId) {
        // Check for existing active conversation first
        const { data: existingConvs } = await supabase
          .from("conversations")
          .select("id")
          .eq("user_id", userId)
          .eq("profile_id", profileId)
          .eq("status", "active")
          .limit(1);

        if (existingConvs && existingConvs.length > 0) {
          activeConversationId = existingConvs[0].id;
        } else {
          // Create new conversation from profile
          const { data: profileData, error: profileError } = await supabase
            .from("profiles")
            .select("*")
            .eq("id", profileId)
            .eq("user_id", userId)
            .single();

          if (profileError || !profileData) {
            return reply.code(404).send({ error: "Perfil nao encontrado" });
          }

          const platforms = profileData.platforms || {};
          const firstPlatformKey = Object.keys(platforms)[0];
          const platformData = firstPlatformKey
            ? platforms[firstPlatformKey]
            : {};
          const platform =
            platformData.type || firstPlatformKey || "tinder";

          const newConvId = require("crypto").randomUUID();
          const now = new Date().toISOString();

          const { error: insertError } = await supabase
            .from("conversations")
            .insert({
              id: newConvId,
              user_id: userId,
              profile_id: profileId,
              status: "active",
              avatar: {
                matchName: profileData.name || "Desconhecida",
                platform,
                bio: platformData.bio || "",
                photoDescriptions: platformData.photoDescriptions || [],
                age: platformData.age || null,
                analytics: {
                  totalMessages: 0,
                  aiSuggestionsUsed: 0,
                  customMessagesUsed: 0,
                },
              },
              messages: [],
              current_tone: tone || "casual",
              created_at: now,
              last_message_at: now,
            });

          if (insertError) {
            throw new Error(
              `Failed to create conversation: ${insertError.message}`
            );
          }

          activeConversationId = newConvId;
          fastify.log.info(
            `Auto-created conversation ${activeConversationId} for profile ${profileId}`
          );

          // Dual-write new conversation to Firebase
          firebaseSync.syncConversationCreate({
            id: newConvId,
            user_id: userId,
            profile_id: profileId,
            platform,
            avatar: {
              matchName: profileData.name || "Desconhecida",
              platform,
              bio: platformData.bio || "",
              photoDescriptions: platformData.photoDescriptions || [],
              age: platformData.age || null,
              analytics: { totalMessages: 0, aiSuggestionsUsed: 0, customMessagesUsed: 0 },
            },
            messages: [],
            current_tone: tone || "casual",
            status: "active",
            created_at: now,
            last_message_at: now,
          });
        }
      }

      // Verify conversation belongs to user
      const { data: convData, error: convError } = await supabase
        .from("conversations")
        .select("id, user_id, profile_id")
        .eq("id", activeConversationId)
        .eq("user_id", userId)
        .single();

      if (convError || !convData) {
        return reply.code(404).send({ error: "Conversa nao encontrada" });
      }

      // Add message to conversation via RPC
      const message = {
        id: `kb_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        role: "user",
        content,
        timestamp: new Date().toISOString(),
        wasAiSuggestion: wasAiSuggestion || false,
        tone: tone || null,
        objective: objective || null,
        source: "keyboard",
      };

      await supabase.rpc("append_message", {
        conv_id: activeConversationId,
        new_message: message,
      });
      firebaseSync.syncMessageAppend(activeConversationId, message);

      // Update last_message_at
      await supabase
        .from("conversations")
        .update({ last_message_at: new Date().toISOString() })
        .eq("id", activeConversationId);

      // Update analytics via RPC
      const analyticsField = wasAiSuggestion
        ? "avatar.analytics.aiSuggestionsUsed"
        : "avatar.analytics.customMessagesUsed";

      await supabase.rpc("increment_avatar_stat", {
        conv_id: activeConversationId,
        stat_path: analyticsField,
        increment_by: 1,
      });

      await supabase.rpc("increment_avatar_stat", {
        conv_id: activeConversationId,
        stat_path: "avatar.analytics.totalMessages",
        increment_by: 1,
      });

      // Dual-write analytics to Firebase
      firebaseSync.syncAvatarAnalyticsIncrement(
        activeConversationId,
        wasAiSuggestion ? "aiSuggestionsUsed" : "customMessagesUsed"
      );

      // Update profile's last_activity_at for sorting in profiles list
      const convProfileId = convData.profile_id;
      if (convProfileId) {
        try {
          const now = new Date().toISOString();
          await supabase
            .from("profiles")
            .update({
              last_activity_at: now,
              last_message_preview: content.substring(0, 80),
              updated_at: now,
            })
            .eq("id", convProfileId);
          // Dual-write profile activity to Firebase
          firebaseSync.syncProfileActivity(convProfileId, content);
        } catch (profileErr) {
          // Non-critical - profile ordering won't update but message is saved
          fastify.log.warn(
            "Failed to update profile lastActivityAt:",
            profileErr
          );
        }
      }

      return reply.code(200).send({ success: true, messageId: message.id });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao salvar mensagem",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// POST /keyboard/start-conversation - Generate first message openers
fastify.post(
  "/keyboard/start-conversation",
  { preHandler: [verifyRequestSignature, auth_1.verifyAuth] },
  async (request, reply) => {
    try {
      const userId = request.user.uid;
      const { conversationId, profileId, objective, tone } = request.body;

      if (!objective || !tone) {
        return reply.code(400).send({
          error: "Missing required fields",
          message: "objective and tone are required",
        });
      }

      // Build context from profile/conversation data
      let matchName = "";
      let matchBio = "";
      let platform = "tinder";
      let photoDescription = "";
      let specificDetail = "";
      let userContext = undefined;

      // Try to get data from conversation
      if (conversationId) {
        try {
          const { data: convData } = await supabase
            .from("conversations")
            .select("*")
            .eq("id", conversationId)
            .eq("user_id", userId)
            .single();

          if (convData) {
            const avatar = convData.avatar || {};
            matchName = avatar.matchName || "";
            matchBio = avatar.bio || "";
            platform = avatar.platform || "tinder";
            photoDescription = avatar.photoDescriptions || "";

            // Check existing messages for context
            const messages = convData.messages || [];
            if (messages.length > 0) {
              specificDetail = `Ja trocaram ${messages.length} mensagens anteriormente.`;
            }
          }
        } catch (err) {
          fastify.log.warn(
            "Failed to fetch conversation for start-conversation:",
            err
          );
        }
      }

      // Fallback: try profile data
      if (!matchName && profileId) {
        try {
          const { data: profileData } = await supabase
            .from("profiles")
            .select("*")
            .eq("id", profileId)
            .eq("user_id", userId)
            .single();

          if (profileData) {
            matchName = profileData.name || "";
            matchBio = profileData.bio || "";
            platform = profileData.platform || "tinder";
            if (
              profileData.photo_descriptions &&
              profileData.photo_descriptions.length > 0
            ) {
              photoDescription = profileData.photo_descriptions.join(". ");
            }
          }
        } catch (err) {
          fastify.log.warn(
            "Failed to fetch profile for start-conversation:",
            err
          );
        }
      }

      // Get objective prompt for calibration
      const objectiveInstruction = prompts_1.getObjectivePrompt(objective);

      // Build enriched input for the agent
      const enrichedInput = {
        matchName: matchName || "Match",
        matchBio: matchBio || "",
        platform,
        tone,
        photoDescription,
        specificDetail: specificDetail
          ? `${specificDetail}\n\n${objectiveInstruction}`
          : objectiveInstruction,
      };

      const agent = new agents_1.FirstMessageAgent();
      const result = await agent.execute(enrichedInput, userContext);

      return reply.code(200).send({ analysis: result });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao gerar primeira mensagem",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// POST /keyboard/analyze-screenshot - Extract messages from image
fastify.post(
  "/keyboard/analyze-screenshot",
  { preHandler: [verifyRequestSignature, auth_1.verifyAuth] },
  async (request, reply) => {
    try {
      const userId = request.user.uid;
      const { imageBase64, imageMediaType, conversationId, objective, tone } =
        request.body;

      if (!imageBase64) {
        return reply.code(400).send({
          error: "Missing required fields",
          message: "imageBase64 is required",
        });
      }

      // Step 1: Extract messages from screenshot using ConversationImageAnalyzerAgent
      const imageAgent = new agents_1.ConversationImageAnalyzerAgent();
      const extractedData = await imageAgent.analyzeAndExtract({
        imageBase64,
        imageMediaType: imageMediaType || "image/jpeg",
      });

      if (!extractedData || !extractedData.lastMessage) {
        return reply.code(200).send({
          analysis:
            "Nao foi possivel extrair mensagens da imagem. Tente com um print mais nitido.",
          extractedMessages: [],
          mode: "screenshot",
        });
      }

      // Step 2: Build context and generate suggestions
      let richPrompt = "";
      let convContext = "";

      if (conversationId) {
        try {
          const { data: convData } = await supabase
            .from("conversations")
            .select("*")
            .eq("id", conversationId)
            .eq("user_id", userId)
            .single();

          if (convData) {
            const avatar = convData.avatar || {};
            const messages = convData.messages || [];

            // Build history from saved messages
            if (messages.length > 0) {
              const recent = messages.slice(-15);
              convContext =
                "Historico salvo:\n" +
                recent
                  .map((m) => {
                    const role =
                      m.role === "user"
                        ? "Voce"
                        : avatar.matchName || "Match";
                    return `${role}: ${m.content}`;
                  })
                  .join("\n");
            }

            // Deduplicate: remove screenshot messages that already exist in history
            if (
              extractedData.conversationContext &&
              messages.length > 0
            ) {
              const existingContents = messages.map((m) =>
                m.content.toLowerCase().trim()
              );
              extractedData.conversationContext =
                extractedData.conversationContext.filter((msg) => {
                  const normalized = msg.toLowerCase().trim();
                  return !existingContents.some((existing) => {
                    // Fuzzy match: if 80%+ similar, consider duplicate
                    const shorter = Math.min(
                      existing.length,
                      normalized.length
                    );
                    const longer = Math.max(
                      existing.length,
                      normalized.length
                    );
                    if (shorter === 0) return false;
                    let matches = 0;
                    for (let i = 0; i < shorter; i++) {
                      if (existing[i] === normalized[i]) matches++;
                    }
                    return matches / longer > 0.8;
                  });
                });
            }

            // Save extracted messages to conversation
            const screenshotMessages = [];

            if (extractedData.conversationContext) {
              for (const msg of extractedData.conversationContext) {
                screenshotMessages.push({
                  id: `kb_screenshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                  role: "match",
                  content: msg,
                  timestamp: new Date().toISOString(),
                  source: "keyboard_screenshot",
                });
              }
            }

            if (extractedData.lastMessage) {
              screenshotMessages.push({
                id: `kb_screenshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                role:
                  extractedData.lastMessageSender === "user"
                    ? "user"
                    : "match",
                content: extractedData.lastMessage,
                timestamp: new Date().toISOString(),
                source: "keyboard_screenshot",
              });
            }

            if (screenshotMessages.length > 0) {
              await supabase.rpc("append_messages", {
                conv_id: conversationId,
                new_messages: screenshotMessages,
              });
              firebaseSync.syncMessagesAppend(conversationId, screenshotMessages);

              await supabase
                .from("conversations")
                .update({ last_message_at: new Date().toISOString() })
                .eq("id", conversationId);
            }
          }
        } catch (err) {
          fastify.log.warn(
            "Failed to process conversation context for screenshot:",
            err
          );
        }
      }

      // Build screenshot context
      let screenshotContext = "";
      if (
        extractedData.conversationContext &&
        extractedData.conversationContext.length > 0
      ) {
        screenshotContext =
          "Mensagens do screenshot:\n" +
          extractedData.conversationContext.join("\n");
      }

      const objectiveInstruction = prompts_1.getObjectivePrompt(
        objective || "automatico"
      );

      richPrompt = `Voce esta ajudando a responder mensagens de dating.
${convContext ? convContext + "\n\n" : ""}${screenshotContext ? screenshotContext + "\n\n" : ""}A ultima mensagem ${extractedData.lastMessageSender === "user" ? "foi sua" : "foi dela"}:
"${extractedData.lastMessage}"

${objectiveInstruction}

Gere APENAS 3 sugestoes de resposta numeradas (1. 2. 3.), cada uma curta (1-2 frases).
Calibre com base no contexto da conversa e OBJETIVO definido acima.`;

      const analysis = await anthropic_1.analyzeMessage({
        text: richPrompt,
        tone: tone || "automatico",
      });

      return reply.code(200).send({
        analysis,
        extractedMessages: extractedData.conversationContext || [],
        mode: "screenshot",
      });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Erro ao analisar screenshot",
        message: error instanceof Error ? error.message : "Erro desconhecido",
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// 12. POST /apple/activate-subscription
// ═══════════════════════════════════════════════════════════════════
fastify.post(
  "/apple/activate-subscription",
  { preHandler: auth_1.verifyAuthOnly },
  async (request, reply) => {
    try {
      const { productId, transactionId, plan, verificationData } =
        request.body;
      const user = request.user;

      if (!productId || !transactionId || !plan) {
        return reply.code(400).send({
          error: "Missing required fields",
          message: "productId, transactionId, and plan are required",
        });
      }

      // Calculate expiration based on plan
      const now = new Date();
      let expiresAt;
      switch (plan) {
        case "monthly":
          expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
          break;
        case "quarterly":
          expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
          break;
        case "yearly":
          expiresAt = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
          break;
        default:
          expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      }

      // Update user subscription in Supabase users table
      const { error: updateError } = await supabase
        .from("users")
        .update({
          subscription_status: "active",
          subscription_plan: plan,
          subscription_provider: "apple",
          apple_product_id: productId,
          apple_transaction_id: transactionId,
          subscription_expires_at: expiresAt.toISOString(),
          subscription_started_at: new Date().toISOString(),
        })
        .eq("id", user.uid);

      if (updateError) {
        // User may not exist yet, try upsert
        const { error: upsertError } = await supabase.from("users").upsert(
          {
            id: user.uid,
            email: user.email || "",
            subscription_status: "active",
            subscription_plan: plan,
            subscription_provider: "apple",
            apple_product_id: productId,
            apple_transaction_id: transactionId,
            subscription_expires_at: expiresAt.toISOString(),
            subscription_started_at: new Date().toISOString(),
          },
          { onConflict: "id" }
        );

        if (upsertError) {
          throw new Error(
            `Failed to update subscription: ${upsertError.message}`
          );
        }
      }

      console.log("Apple subscription activated:", { plan, expiresAt });

      // Dual-write to Firestore
      firebaseSync.syncSubscription(user.uid, {
        status: "active",
        plan,
        provider: "apple",
        appleProductId: productId,
        appleTransactionId: transactionId,
        expiresAt: expiresAt.toISOString(),
        startedAt: true,
      });

      return reply.code(200).send({
        success: true,
        plan,
        expiresAt: expiresAt.toISOString(),
      });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Failed to activate subscription",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// 13. DELETE /user/account - GDPR account deletion
// ═══════════════════════════════════════════════════════════════════
fastify.delete(
  "/user/account",
  { preHandler: [auth_1.verifyAuthOnly] },
  async (request, reply) => {
    try {
      const userId = request.user.uid;

      // Delete from Supabase tables
      // Delete conversations
      await supabase
        .from("conversations")
        .delete()
        .eq("user_id", userId);

      // Delete profiles
      await supabase
        .from("profiles")
        .delete()
        .eq("user_id", userId);

      // Delete analytics
      await supabase
        .from("analytics")
        .delete()
        .eq("user_id", userId);

      // Delete training feedback
      await supabase
        .from("training_feedback")
        .delete()
        .eq("user_id", userId);

      // Delete user record
      await supabase
        .from("users")
        .delete()
        .eq("id", userId);

      // Dual-write: delete from Firebase too
      firebaseSync.syncAccountDelete(userId);

      // Clean up mapping
      await supabase
        .from("user_id_mapping")
        .delete()
        .eq("supabase_uid", userId);

      return reply
        .code(200)
        .send({ success: true, message: "Account and all data deleted" });
    } catch (error) {
      fastify.log.error(error);
      return reply.code(500).send({
        error: "Failed to delete account",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════
// 14. CRON: Check expired subscriptions
// ═══════════════════════════════════════════════════════════════════
async function checkExpiredSubscriptions() {
  try {
    const now = new Date().toISOString();

    // Query Supabase users table for expired subscriptions
    const { data: expiredUsers, error } = await supabase
      .from("users")
      .select("id")
      .eq("subscription_status", "active")
      .lt("subscription_expires_at", now);

    if (error) {
      console.error("Subscription check query error:", error.message);
      return;
    }

    if (!expiredUsers || expiredUsers.length === 0) {
      console.log("Subscription check: no expired subscriptions found");
      return;
    }

    const expiredIds = expiredUsers.map((u) => u.id);

    // Batch update status to 'expired'
    const { error: updateError } = await supabase
      .from("users")
      .update({ subscription_status: "expired" })
      .in("id", expiredIds);

    if (updateError) {
      console.error("Subscription check update error:", updateError.message);
      return;
    }

    console.log(
      `Subscription check: marked ${expiredUsers.length} subscriptions as expired`
    );

    // Dual-write: also mark as expired in Firestore
    (async () => {
      try {
        const firebaseUids = [];
        for (const id of expiredIds) {
          const fbUid = await firebaseSync.resolveFirebaseUid(id);
          if (fbUid) firebaseUids.push(fbUid);
        }
        firebaseSync.syncExpiredSubscriptions(firebaseUids);
      } catch (e) {
        console.warn("[Firebase-Sync] Expired sync failed:", e.message);
      }
    })();
  } catch (error) {
    console.error(
      "Subscription check failed:",
      error.message || error
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SERVER START
// ═══════════════════════════════════════════════════════════════════
const start = async () => {
  try {
    await fastify.listen({ port: env_1.env.PORT, host: "0.0.0.0" });
    console.log(`Servidor rodando na porta ${env_1.env.PORT}`);

    // Run subscription check on startup, then every 24h
    checkExpiredSubscriptions();
    setInterval(checkExpiredSubscriptions, 24 * 60 * 60 * 1000);

    // Start cart recovery cron
    try {
      const { startRecoveryCron } = require("./services/recovery-cron");
      startRecoveryCron();
    } catch (e) {
      console.warn("Recovery cron not started:", e.message);
    }
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConversationManager = void 0;

const { randomUUID } = require("crypto");
const { supabase } = require("../config/supabase");
const { CollectiveAvatarManager } = require("./collective-avatar-manager");
const firebaseSync = require("./firebase-sync");

class ConversationManager {
  static async createConversation(request) {
    const conversationId = randomUUID();
    const now = new Date();

    // Find or create collective avatar
    const collectiveAvatar = await CollectiveAvatarManager.findOrCreateCollectiveAvatar({
      name: request.matchName,
      platform: request.platform,
      bio: request.bio,
      age: request.age,
      location: request.location,
      interests: request.interests,
    });

    const avatar = {
      matchName: request.matchName,
      platform: request.platform,
      bio: request.bio,
      photoDescriptions: request.photoDescriptions,
      age: request.age,
      location: request.location,
      interests: request.interests,
      detectedPatterns: {
        responseLength: "medium",
        emotionalTone: "neutral",
        useEmojis: false,
        flirtLevel: "medium",
        lastUpdated: now.toISOString(),
      },
      learnedInfo: {
        hobbies: request.interests || [],
        lifestyle: [],
        dislikes: [],
        goals: [],
        personality: [],
      },
      analytics: {
        totalMessages: 0,
        aiSuggestionsUsed: 0,
        customMessagesUsed: 0,
        conversationQuality: "average",
      },
    };

    const messages = [];
    if (request.firstMessage) {
      messages.push({
        id: randomUUID(),
        role: "user",
        content: request.firstMessage,
        timestamp: now.toISOString(),
        wasAiSuggestion: true,
        tone: request.tone,
      });
    }

    const conversation = {
      id: conversationId,
      user_id: request.userId,
      profile_id: request.profileId || null,
      platform: request.platform,
      avatar,
      messages,
      current_tone: request.tone || "casual",
      status: "active",
      collective_avatar_id: collectiveAvatar?.id || null,
      created_at: now.toISOString(),
      last_message_at: now.toISOString(),
    };

    const { error } = await supabase.from("conversations").insert(conversation);
    if (error) throw new Error(`Failed to create conversation: ${error.message}`);

    // Dual-write to Firestore
    firebaseSync.syncConversationCreate(conversation);

    return {
      id: conversationId,
      ...conversation,
      createdAt: now,
      lastMessageAt: now,
    };
  }

  static async addMessage(conversationId, userId, messageData) {
    // Verify ownership
    const { data: conv, error: getErr } = await supabase
      .from("conversations")
      .select("id, user_id, avatar, messages")
      .eq("id", conversationId)
      .single();

    if (!conv) throw new Error("Conversation not found");
    if (conv.user_id !== userId) throw new Error("Unauthorized");

    const message = {
      id: randomUUID(),
      role: messageData.role || "user",
      content: messageData.content,
      timestamp: new Date().toISOString(),
      wasAiSuggestion: messageData.wasAiSuggestion || false,
      tone: messageData.tone,
      source: messageData.source,
      objective: messageData.objective,
    };

    // Append message
    await supabase.rpc("append_message", {
      conv_id: conversationId,
      new_message: message,
    });

    // Dual-write to Firestore
    firebaseSync.syncMessageAppend(conversationId, message);

    // Update avatar analytics
    const analyticsField = message.wasAiSuggestion ? "aiSuggestionsUsed" : "customMessagesUsed";
    await supabase.rpc("increment_avatar_stat", {
      conv_id: conversationId,
      stat_path: ["analytics", "totalMessages"],
    });
    await supabase.rpc("increment_avatar_stat", {
      conv_id: conversationId,
      stat_path: ["analytics", analyticsField],
    });

    // Dual-write analytics to Firestore
    firebaseSync.syncAvatarAnalyticsIncrement(conversationId, analyticsField);

    // Update avatar patterns if match message
    if (messageData.role === "match" && messageData.content) {
      const content = messageData.content;
      const patterns = conv.avatar?.detectedPatterns || {};
      const updatedPatterns = { ...patterns };

      if (content.length < 30) updatedPatterns.responseLength = "short";
      else if (content.length > 150) updatedPatterns.responseLength = "long";
      else updatedPatterns.responseLength = "medium";

      const hasEmoji = /[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]/u.test(content);
      updatedPatterns.useEmojis = hasEmoji;
      updatedPatterns.lastUpdated = new Date().toISOString();

      await supabase.rpc("update_avatar", {
        conv_id: conversationId,
        avatar_update: { detectedPatterns: updatedPatterns },
      });
    }

    return message;
  }

  static async getConversation(conversationId, userId) {
    const { data, error } = await supabase
      .from("conversations")
      .select("*")
      .eq("id", conversationId)
      .single();

    if (!data) throw new Error("Conversation not found");
    if (data.user_id !== userId) throw new Error("Unauthorized");

    return {
      id: data.id,
      userId: data.user_id,
      profileId: data.profile_id,
      avatar: data.avatar,
      messages: data.messages || [],
      currentTone: data.current_tone,
      status: data.status,
      collectiveAvatarId: data.collective_avatar_id,
      createdAt: data.created_at ? new Date(data.created_at) : null,
      lastMessageAt: data.last_message_at ? new Date(data.last_message_at) : null,
    };
  }

  static async listConversations(userId) {
    const { data, error } = await supabase
      .from("conversations")
      .select("*")
      .eq("user_id", userId)
      .order("last_message_at", { ascending: false });

    if (error) throw new Error(`Failed to list conversations: ${error.message}`);

    return (data || []).map((d) => ({
      id: d.id,
      userId: d.user_id,
      profileId: d.profile_id,
      avatar: d.avatar,
      messages: d.messages || [],
      currentTone: d.current_tone,
      status: d.status,
      collectiveAvatarId: d.collective_avatar_id,
      createdAt: d.created_at ? new Date(d.created_at) : null,
      lastMessageAt: d.last_message_at ? new Date(d.last_message_at) : null,
    }));
  }

  static async updateTone(conversationId, userId, tone) {
    const { data, error: getErr } = await supabase
      .from("conversations")
      .select("user_id")
      .eq("id", conversationId)
      .single();

    if (!data) throw new Error("Conversation not found");
    if (data.user_id !== userId) throw new Error("Unauthorized");

    const { error } = await supabase
      .from("conversations")
      .update({ current_tone: tone })
      .eq("id", conversationId);

    if (error) throw new Error(`Failed to update tone: ${error.message}`);

    // Dual-write
    firebaseSync.syncToneUpdate(conversationId, tone);
  }

  static async deleteConversation(conversationId, userId) {
    const { data } = await supabase
      .from("conversations")
      .select("user_id")
      .eq("id", conversationId)
      .single();

    if (!data) throw new Error("Conversation not found");
    if (data.user_id !== userId) throw new Error("Unauthorized");

    const { error } = await supabase.from("conversations").delete().eq("id", conversationId);
    if (error) throw new Error(`Failed to delete: ${error.message}`);

    // Dual-write
    firebaseSync.syncConversationDelete(conversationId);
  }
}

exports.ConversationManager = ConversationManager;

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CollectiveAvatarManager = void 0;

const { randomUUID } = require("crypto");
const { supabase } = require("../config/supabase");

class CollectiveAvatarManager {
  static normalizeForId(text) {
    return (text || "")
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]/g, "_")
      .replace(/_+/g, "_")
      .replace(/^_|_$/g, "");
  }

  static async findOrCreateCollectiveAvatar(profileInfo) {
    const { name, platform, bio, age, location, interests } = profileInfo;
    if (!name || !platform) return null;

    const normalizedName = this.normalizeForId(name);
    const avatarId = `${normalizedName}_${platform}`;

    const { data: existing } = await supabase
      .from("collective_avatars")
      .select("*")
      .eq("id", avatarId)
      .single();

    if (existing) {
      // Merge new data
      const profileData = existing.profile_data || {};
      const updates = {};
      let changed = false;

      if (age && !(profileData.possibleAges || []).includes(age)) {
        profileData.possibleAges = [...(profileData.possibleAges || []), age];
        changed = true;
      }
      if (location && !(profileData.possibleLocations || []).includes(location)) {
        profileData.possibleLocations = [...(profileData.possibleLocations || []), location];
        changed = true;
      }
      if (bio && !(profileData.possibleBios || []).includes(bio)) {
        profileData.possibleBios = [...(profileData.possibleBios || []), bio];
        changed = true;
      }
      if (interests) {
        for (const interest of interests) {
          if (!(profileData.commonInterests || []).includes(interest)) {
            profileData.commonInterests = [...(profileData.commonInterests || []), interest];
            changed = true;
          }
        }
      }

      if (changed) {
        const metrics = existing.metrics || {};
        metrics.totalConversations = (metrics.totalConversations || 0) + 1;

        await supabase
          .from("collective_avatars")
          .update({
            profile_data: profileData,
            metrics,
            last_updated: new Date().toISOString(),
          })
          .eq("id", avatarId);
      }

      return { id: avatarId, ...existing, profile_data: profileData };
    }

    // Create new
    const newAvatar = {
      id: avatarId,
      normalized_name: normalizedName,
      platform,
      profile_data: {
        possibleAges: age ? [age] : [],
        possibleLocations: location ? [location] : [],
        possibleBios: bio ? [bio] : [],
        commonInterests: interests || [],
      },
      collective_insights: {
        likes: [],
        dislikes: [],
        behaviorPatterns: [],
        whatWorks: [],
        whatDoesntWork: [],
        openerStats: [],
        personalityTraits: [],
      },
      metrics: {
        totalConversations: 1,
        totalMessages: 0,
        avgConversationLength: 0,
        successRate: 0,
        dateConversionRate: 0,
      },
      confidence_score: 10,
      last_updated: new Date().toISOString(),
    };

    const { error } = await supabase.from("collective_avatars").insert(newAvatar);
    if (error) {
      console.error("Failed to create collective avatar:", error.message);
      return null;
    }

    return newAvatar;
  }

  static async getCollectiveAvatar(avatarId) {
    if (!avatarId) return null;
    const { data } = await supabase.from("collective_avatars").select("*").eq("id", avatarId).single();
    return data;
  }

  static async submitFeedback(feedbackData) {
    const { collectiveAvatarId, messageType, tone, messageSent, gotResponse, responseTime, responseQuality } = feedbackData;

    const feedback = {
      id: randomUUID(),
      collective_avatar_id: collectiveAvatarId,
      message_type: messageType || "reply",
      tone: tone || null,
      message_sent: (messageSent || "").substring(0, 200), // anonymize
      got_response: gotResponse,
      response_time: responseTime || null,
      response_quality: responseQuality || null,
    };

    await supabase.from("message_feedback").insert(feedback);

    // Update collective avatar insights
    if (collectiveAvatarId) {
      const { data: avatar } = await supabase
        .from("collective_avatars")
        .select("collective_insights, metrics")
        .eq("id", collectiveAvatarId)
        .single();

      if (avatar) {
        const insights = avatar.collective_insights || {};
        const metrics = avatar.metrics || {};

        // Update opener stats if it's an opener
        if (messageType === "opener" && tone) {
          const stats = insights.openerStats || [];
          const existing = stats.find((s) => s.openerType === tone);
          if (existing) {
            existing.totalSent = (existing.totalSent || 0) + 1;
            if (gotResponse) {
              existing.responseRate = Math.round(
                ((existing.responseRate * (existing.totalSent - 1) + 100) / existing.totalSent)
              );
            }
            existing.examples = (existing.examples || []).slice(-5);
            existing.examples.push({ opener: feedback.message_sent, gotResponse, responseQuality });
          } else {
            stats.push({
              openerType: tone,
              responseRate: gotResponse ? 100 : 0,
              avgResponseQuality: responseQuality || "neutral",
              totalSent: 1,
              examples: [{ opener: feedback.message_sent, gotResponse, responseQuality }],
            });
          }
          insights.openerStats = stats;
        }

        // Update what works / doesn't work
        if (gotResponse && responseQuality === "warm") {
          const whatWorks = insights.whatWorks || [];
          whatWorks.push({
            strategy: `${tone} tone`,
            successCount: 1,
            failCount: 0,
            successRate: 100,
            examples: [feedback.message_sent],
          });
          insights.whatWorks = whatWorks.slice(-20);
        } else if (!gotResponse || responseQuality === "cold") {
          const whatDoesnt = insights.whatDoesntWork || [];
          whatDoesnt.push({
            strategy: `${tone} tone`,
            successCount: 0,
            failCount: 1,
            successRate: 0,
            examples: [feedback.message_sent],
          });
          insights.whatDoesntWork = whatDoesnt.slice(-20);
        }

        metrics.totalMessages = (metrics.totalMessages || 0) + 1;

        await supabase
          .from("collective_avatars")
          .update({
            collective_insights: insights,
            metrics,
            last_updated: new Date().toISOString(),
          })
          .eq("id", collectiveAvatarId);
      }
    }

    return feedback;
  }

  static async getTagInsights(tags, platform) {
    if (!tags || !tags.length || !platform) return null;

    const docIds = tags.map((t) => `${t.toLowerCase()}_${platform}`);
    const { data } = await supabase.from("tag_insights").select("*").in("id", docIds);

    if (!data || data.length === 0) return null;

    // Merge insights from all matching tags
    const merged = { whatWorks: [], whatDoesntWork: [], goodExamples: [], badExamples: [], bestTypes: [] };
    for (const row of data) {
      merged.whatWorks.push(...(row.what_works || []));
      merged.whatDoesntWork.push(...(row.what_doesnt_work || []));
      merged.goodExamples.push(...(row.good_examples || []));
      merged.badExamples.push(...(row.bad_examples || []));
      merged.bestTypes.push(...(row.best_types || []));
    }

    return merged;
  }
}

exports.CollectiveAvatarManager = CollectiveAvatarManager;

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TrainingFeedbackService = void 0;

const { randomUUID } = require("crypto");
const { supabase } = require("../config/supabase");

class TrainingFeedbackService {
  static async create(data) {
    const now = new Date().toISOString();
    const feedback = {
      id: randomUUID(),
      category: data.category,
      subcategory: data.subcategory || null,
      instruction: data.instruction,
      examples: data.examples || [],
      tags: data.tags || [],
      priority: data.priority || "medium",
      is_active: true,
      usage_count: 0,
      created_at: now,
      updated_at: now,
    };

    const { error } = await supabase.from("training_feedback").insert(feedback);
    if (error) throw new Error(`Failed to create feedback: ${error.message}`);
    return feedback;
  }

  static async update(id, data) {
    const updates = { updated_at: new Date().toISOString() };
    if (data.instruction !== undefined) updates.instruction = data.instruction;
    if (data.examples !== undefined) updates.examples = data.examples;
    if (data.tags !== undefined) updates.tags = data.tags;
    if (data.priority !== undefined) updates.priority = data.priority;
    if (data.isActive !== undefined) updates.is_active = data.isActive;

    const { error } = await supabase.from("training_feedback").update(updates).eq("id", id);
    if (error) throw new Error(`Failed to update feedback: ${error.message}`);
  }

  static async delete(id) {
    const { error } = await supabase.from("training_feedback").delete().eq("id", id);
    if (error) throw new Error(`Failed to delete feedback: ${error.message}`);
  }

  static async getAllActive() {
    const { data, error } = await supabase
      .from("training_feedback")
      .select("*")
      .eq("is_active", true)
      .order("priority")
      .order("created_at", { ascending: false });

    if (error) throw new Error(`Failed to get feedback: ${error.message}`);
    return (data || []).map(this._toResponse);
  }

  static async getByCategory(category) {
    const { data, error } = await supabase
      .from("training_feedback")
      .select("*")
      .eq("category", category)
      .eq("is_active", true)
      .order("priority");

    if (error) throw new Error(`Failed to get feedback: ${error.message}`);
    return (data || []).map(this._toResponse);
  }

  static async incrementUsage(id) {
    await supabase.rpc("increment_usage", { feedback_id: id });
  }

  static _toResponse(row) {
    return {
      id: row.id,
      category: row.category,
      subcategory: row.subcategory,
      instruction: row.instruction,
      examples: row.examples,
      tags: row.tags,
      priority: row.priority,
      isActive: row.is_active,
      usageCount: row.usage_count,
      createdAt: row.created_at ? new Date(row.created_at) : null,
      updatedAt: row.updated_at ? new Date(row.updated_at) : null,
    };
  }
}

exports.TrainingFeedbackService = TrainingFeedbackService;

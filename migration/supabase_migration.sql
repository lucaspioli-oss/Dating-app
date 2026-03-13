-- ============================================
-- Desenrola AI: Firebase → Supabase Migration
-- ============================================

-- 1. Update existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_developer BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_provider TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_product_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_transaction_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_amount NUMERIC;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_currency TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_started_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_cancelled_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_cancel_reason TEXT;

-- 2. Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id TEXT,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Sem nome',
  platforms JSONB DEFAULT '{}',
  face_image_base64 TEXT,
  last_activity_at TIMESTAMPTZ,
  last_message_preview TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_updated ON profiles(user_id, updated_at DESC);

-- 3. Conversations table (messages as JSONB array, same as Firestore)
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_id TEXT,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  profile_id UUID,
  platform TEXT,
  current_tone TEXT DEFAULT 'casual',
  status TEXT DEFAULT 'active',
  avatar JSONB DEFAULT '{}',
  messages JSONB DEFAULT '[]',
  collective_avatar_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_conv_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conv_user_status ON conversations(user_id, status);
CREATE INDEX IF NOT EXISTS idx_conv_last_msg ON conversations(user_id, last_message_at DESC);

-- 4. Collective avatars
CREATE TABLE IF NOT EXISTS collective_avatars (
  id TEXT PRIMARY KEY,
  normalized_name TEXT,
  platform TEXT,
  profile_data JSONB DEFAULT '{}',
  collective_insights JSONB DEFAULT '{}',
  metrics JSONB DEFAULT '{"totalConversations":0,"totalMessages":0,"avgConversationLength":0,"successRate":0,"dateConversionRate":0}',
  confidence_score INTEGER DEFAULT 10,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  last_analyzed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Tag insights
CREATE TABLE IF NOT EXISTS tag_insights (
  id TEXT PRIMARY KEY,
  what_works JSONB DEFAULT '[]',
  what_doesnt_work JSONB DEFAULT '[]',
  good_examples JSONB DEFAULT '[]',
  bad_examples JSONB DEFAULT '[]',
  best_types JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Message feedback
CREATE TABLE IF NOT EXISTS message_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collective_avatar_id TEXT,
  message_type TEXT,
  tone TEXT,
  message_sent TEXT,
  got_response BOOLEAN,
  response_time INTEGER,
  response_quality TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_mf_avatar ON message_feedback(collective_avatar_id);

-- 7. Training feedback
CREATE TABLE IF NOT EXISTS training_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category TEXT,
  subcategory TEXT,
  instruction TEXT,
  examples JSONB DEFAULT '[]',
  tags JSONB DEFAULT '[]',
  priority TEXT DEFAULT 'medium',
  is_active BOOLEAN DEFAULT TRUE,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Analytics
CREATE TABLE IF NOT EXISTS analytics (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  signup_date TIMESTAMPTZ,
  last_active TIMESTAMPTZ,
  conversation_quality_history JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RPC Functions for atomic operations
-- ============================================

-- Append single message to conversation
CREATE OR REPLACE FUNCTION append_message(conv_id UUID, new_message JSONB)
RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET messages = messages || jsonb_build_array(new_message),
      last_message_at = NOW()
  WHERE id = conv_id;
END;
$$ LANGUAGE plpgsql;

-- Append multiple messages
CREATE OR REPLACE FUNCTION append_messages(conv_id UUID, new_messages JSONB)
RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET messages = messages || new_messages,
      last_message_at = NOW()
  WHERE id = conv_id;
END;
$$ LANGUAGE plpgsql;

-- Increment avatar analytics counter
CREATE OR REPLACE FUNCTION increment_avatar_stat(conv_id UUID, stat_path TEXT[], increment_by INT DEFAULT 1)
RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET avatar = jsonb_set(
    avatar,
    stat_path,
    (COALESCE((avatar #>> stat_path)::int, 0) + increment_by)::text::jsonb
  )
  WHERE id = conv_id;
END;
$$ LANGUAGE plpgsql;

-- Update avatar object (merge)
CREATE OR REPLACE FUNCTION update_avatar(conv_id UUID, avatar_update JSONB)
RETURNS void AS $$
BEGIN
  UPDATE conversations
  SET avatar = avatar || avatar_update
  WHERE id = conv_id;
END;
$$ LANGUAGE plpgsql;

-- Increment training feedback usage
CREATE OR REPLACE FUNCTION increment_usage(feedback_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE training_feedback
  SET usage_count = usage_count + 1
  WHERE id = feedback_id;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE collective_avatars ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- RLS policies (service_role bypasses these; these are for future client-side access)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_own') THEN
    CREATE POLICY profiles_select_own ON profiles FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_all_own') THEN
    CREATE POLICY profiles_all_own ON profiles FOR ALL USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conversations_select_own') THEN
    CREATE POLICY conversations_select_own ON conversations FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conversations_all_own') THEN
    CREATE POLICY conversations_all_own ON conversations FOR ALL USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'analytics_select_own') THEN
    CREATE POLICY analytics_select_own ON analytics FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

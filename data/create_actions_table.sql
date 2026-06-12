CREATE TABLE IF NOT EXISTS official.actions (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'PHB 2024',
  legacy BOOLEAN NOT NULL DEFAULT FALSE,
  tags TEXT[] DEFAULT ARRAY['action']::TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Admin account photos (PostgreSQL). Existing accounts may upload a photo when edited.
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_data BYTEA;
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_type VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_name VARCHAR(150);

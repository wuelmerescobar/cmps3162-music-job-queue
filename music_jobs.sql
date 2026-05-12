-- =====================================================
-- CMPS3162 Test #2
-- PostgreSQL Music Job Queue
-- Name: Wuelmer Escobar
-- Database: PostgreSQL 18.1
-- =====================================================

-- =====================================================
-- STEP 1 — id, payload, created_at
-- =====================================================

DROP TABLE IF EXISTS music_jobs;

CREATE TABLE music_jobs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sample Data

INSERT INTO music_jobs (payload)
VALUES
(
    '{
        "original_filename": "brukdown_vibes.mp3",
        "mime_type": "audio/mpeg",
        "artist": "Wilfred Peters",
        "uploaded_by": "djramirez",
        "duration_seconds": 245
    }'
),
(
    '{
        "original_filename": "punta_mix.wav",
        "mime_type": "audio/wav",
        "artist": "Supa G",
        "uploaded_by": "studio_belize"
    }'
),
(
    '{
        "original_filename": "carnival_live_session.mp3",
        "mime_type": "audio/mpeg",
        "artist": "Various Artists",
        "uploaded_by": "bluesteel_sounds",
        "duration_seconds": 312,
        "concert_location": "Belize City"
    }'
);

-- =====================================================
-- Verification Queries
-- =====================================================

-- Make output easier to read
\x on
\pset border 2
\pset null '(null)'

-- 1. Show all jobs ordered by creation time

SELECT *
FROM music_jobs
ORDER BY created_at;


-- Turn expanded mode off for cleaner table output
\x off

-- 2. Extract just the filename and mime_type from each job

SELECT
    payload->>'original_filename' AS filename,
    payload->>'mime_type' AS mime_type
FROM music_jobs;


-- 3. Find only MP3 uploads

SELECT
    id,
    payload->>'original_filename' AS filename,
    payload->>'mime_type' AS mime_type
FROM music_jobs
WHERE payload->>'mime_type' = 'audio/mpeg';


-- Turn expanded mode back on
\x on

-- 4. Find the job that has the extra field

SELECT *
FROM music_jobs
WHERE payload ? 'concert_location';

-- Questions:
-- 1. Why UUID over SERIAL for the primary key?
-- 2. Why uuidv7() specifically over uuidv4()?
-- 3. Why JSONB over JSON?
-- 4. Why TIMESTAMPTZ over TIMESTAMP?
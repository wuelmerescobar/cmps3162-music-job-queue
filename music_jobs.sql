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
-- Output:
-- +-[ RECORD 1 ]-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- | id         | 019e1d33-359d-742c-b513-c60660030d77                                                                                                                                                                      |
-- | payload    | {"artist": "Wilfred Peters", "mime_type": "audio/mpeg", "uploaded_by": "djramirez", "duration_seconds": 245, "original_filename": "brukdown_vibes.mp3"}                                                   |
-- | created_at | 2026-05-12 11:19:15.869012-06                                                                                                                                                                             |
-- +-[ RECORD 2 ]-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- | id         | 019e1d33-359d-79ae-b386-07eb5fd20293                                                                                                                                                                      |
-- | payload    | {"artist": "Supa G", "mime_type": "audio/wav", "uploaded_by": "studio_belize", "original_filename": "punta_mix.wav"}                                                                                      |
-- | created_at | 2026-05-12 11:19:15.869012-06                                                                                                                                                                             |
-- +-[ RECORD 3 ]-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- | id         | 019e1d33-359d-79e4-854e-b99584825b4b                                                                                                                                                                      |
-- | payload    | {"artist": "Various Artists", "mime_type": "audio/mpeg", "uploaded_by": "bluesteel_sounds", "concert_location": "Belize City", "duration_seconds": 312, "original_filename": "carnival_live_session.mp3"} |
-- | created_at | 2026-05-12 11:19:15.869012-06                                                                                                                                                                             |
-- +------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+


-- Turn expanded mode off for cleaner table output
\x off

-- 2. Extract just the filename and mime_type from each job

SELECT
    payload->>'original_filename' AS filename,
    payload->>'mime_type' AS mime_type
FROM music_jobs;
-- Output:
-- +---------------------------+------------+
-- |         filename          | mime_type  |
-- +---------------------------+------------+
-- | brukdown_vibes.mp3        | audio/mpeg |
-- | punta_mix.wav             | audio/wav  |
-- | carnival_live_session.mp3 | audio/mpeg |
-- +---------------------------+------------+
-- (3 rows)


-- 3. Find only MP3 uploads

SELECT
    id,
    payload->>'original_filename' AS filename,
    payload->>'mime_type' AS mime_type
FROM music_jobs
WHERE payload->>'mime_type' = 'audio/mpeg';
-- Output:
-- +--------------------------------------+---------------------------+------------+
-- |                  id                  |         filename          | mime_type  |
-- +--------------------------------------+---------------------------+------------+
-- | 019e1d33-359d-742c-b513-c60660030d77 | brukdown_vibes.mp3        | audio/mpeg |
-- | 019e1d33-359d-79e4-854e-b99584825b4b | carnival_live_session.mp3 | audio/mpeg |
-- +--------------------------------------+---------------------------+------------+
-- (2 rows)


-- Turn expanded mode back on
\x on

-- 4. Find the job that has the extra field

SELECT *
FROM music_jobs
WHERE payload ? 'concert_location';
-- Output:
-- +-[ RECORD 1 ]-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
-- | id         | 019e1d33-359d-79e4-854e-b99584825b4b                                                                                                                                                                      |
-- | payload    | {"artist": "Various Artists", "mime_type": "audio/mpeg", "uploaded_by": "bluesteel_sounds", "concert_location": "Belize City", "duration_seconds": 312, "original_filename": "carnival_live_session.mp3"} |
-- | created_at | 2026-05-12 11:19:15.869012-06                                                                                                                                                                             |
-- +------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

-- Questions:
-- 1. Why UUID over SERIAL for the primary key?
-- UUID is better because it is harder to predict compared to SERIAL IDs.
-- It also works better if the system grows larger or connects with other systems later on.
-- 2. Why uuidv7() specifically over uuidv4()?
-- uuidv7() is ordered by time, so inserts perform better in PostgreSQL indexes.
-- uuidv4() is random, which can make indexes more fragmented over time.
-- 3. Why JSONB over JSON?
-- JSONB is more flexible and faster when searching or filtering data.
-- It also supports indexing and PostgreSQL JSON operators.
-- 4. Why TIMESTAMPTZ over TIMESTAMP?
-- TIMESTAMPTZ stores the timezone together with the date and time.
-- This helps keep the correct time even if users or servers are in different locations.

-- =====================================================
-- STEP 2 — public_id
-- =====================================================

ALTER TABLE music_jobs
ADD COLUMN public_id UUID NOT NULL UNIQUE DEFAULT uuidv4();

-- =====================================================
-- Step 2 Verification Queries
-- =====================================================

-- Turn expanded mode off for cleaner table output
\x off

-- 1. Show id vs public_id side by side — what do you notice?

SELECT
    id,
    public_id
FROM music_jobs
ORDER BY created_at;
-- Output:
-- +--------------------------------------+--------------------------------------+
-- |                  id                  |              public_id               |
-- +--------------------------------------+--------------------------------------+
-- | 019e1d49-43c9-7f34-8b22-9f1adb777ffe | 3a7e9423-17fd-42a8-b70b-3ea744949498 |
-- | 019e1d49-43ca-7894-8b48-b769a30f89e1 | 8636f467-8aea-4f48-add8-acef326d6569 |
-- | 019e1d49-43ca-78cb-ae1f-7c5ab35a4813 | 6c330171-3f1a-4282-9cac-515511a2d09e |
-- +--------------------------------------+--------------------------------------+
-- (3 rows)
-- The internal id is a uuidv7 which is time-based and shows when the row was created.
-- the public_id is a uuidv4 which is random and does not show when the row was created.

-- 2. Run uuid_extract_timestamp() on both columns — what does this prove?

SELECT
    id,
    uuid_extract_timestamp(id) AS id_timestamp,
    public_id,
    uuid_extract_timestamp(public_id) AS public_id_timestamp
FROM music_jobs
ORDER BY created_at;
-- Output:
-- +--------------------------------------+----------------------------+--------------------------------------+---------------------+
-- |                  id                  |        id_timestamp        |              public_id               | public_id_timestamp |
-- +--------------------------------------+----------------------------+--------------------------------------+---------------------+
-- | 019e1d49-43c9-7f34-8b22-9f1adb777ffe | 2026-05-12 11:43:21.289-06 | 3a7e9423-17fd-42a8-b70b-3ea744949498 | (null)              |
-- | 019e1d49-43ca-7894-8b48-b769a30f89e1 | 2026-05-12 11:43:21.29-06  | 8636f467-8aea-4f48-add8-acef326d6569 | (null)              |
-- | 019e1d49-43ca-78cb-ae1f-7c5ab35a4813 | 2026-05-12 11:43:21.29-06  | 6c330171-3f1a-4282-9cac-515511a2d09e | (null)              |
-- +--------------------------------------+----------------------------+--------------------------------------+---------------------+
-- (3 rows)


-- 3. Show what the Go server would return to the client after insert

SELECT
    public_id
FROM music_jobs
ORDER BY created_at
LIMIT 1;
-- Output:
-- +--------------------------------------+
-- |              public_id               |
-- +--------------------------------------+
-- | 3a7e9423-17fd-42a8-b70b-3ea744949498 |
-- +--------------------------------------+
-- (1 row)


-- 4. Show what the Go server would do when the client polls

SELECT
    public_id,
    payload,
    created_at
FROM music_jobs
WHERE public_id = (
    SELECT public_id
    FROM music_jobs
    ORDER BY created_at
    LIMIT 1
);
-- Output:
-- +--------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------+
-- |              public_id               |                                                                         payload                                                                         |          created_at           |
-- +--------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------+
-- | 3a7e9423-17fd-42a8-b70b-3ea744949498 | {"artist": "Wilfred Peters", "mime_type": "audio/mpeg", "uploaded_by": "djramirez", "duration_seconds": 245, "original_filename": "brukdown_vibes.mp3"} | 2026-05-12 11:43:21.289454-06 |
-- +--------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------+
-- (1 row)

-- Questions:
-- 1. Why does this column use uuidv4() and not uuidv7()?
-- public_id uses uuidv4() because it is random and does not show when the row was created.
-- This makes it safer to give to clients compared to uuidv7().
-- 2. What does uuid_extract_timestamp() reveal about uuidv7?
-- uuid_extract_timestamp() shows the timestamp that is inside a uuidv7 value.
-- This proves that uuidv7() is time-based and better kept as an internal ID.
-- 3. Why does the UNIQUE constraint make CREATE INDEX unnecessary?
-- PostgreSQL automatically creates an index when a UNIQUE constraint is added.
-- So creating another index manually on public_id would just repeat the same work.
-- 4. What is the two-ID pattern and why does it matter?
-- The two-ID pattern means the database has one internal ID and one public ID.
-- The internal ID is for the database, and the public ID is what the client uses.

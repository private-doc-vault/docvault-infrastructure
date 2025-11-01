-- Initialize DocVault Database
-- This script runs on PostgreSQL container startup

-- Create extensions for UUID and full-text search
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Create database user with appropriate permissions
-- (User is already created by POSTGRES_USER env var, this is for additional setup)

-- Set timezone
SET timezone = 'UTC';

-- Create initial schema (tables will be created by Symfony migrations)
COMMENT ON DATABASE docvault IS 'DocVault Document Archiving System Database';
# Meilisearch Configuration

Meilisearch is configured entirely through environment variables in `docker-compose.yml` and `docker-compose.dev.yml`.

No additional configuration file is required.

## Environment Variables

The following environment variables are used:

- `MEILI_MASTER_KEY` - Master key for API authentication
- `MEILI_ENV` - Environment mode (development/production)
- `MEILI_LOG_LEVEL` - Logging level (INFO, DEBUG, etc.)
- `MEILI_HTTP_ADDR` - HTTP server address and port

## Data Persistence

Meilisearch data is persisted using a Docker volume (`meilisearch_data`) mounted at `/meili_data`.

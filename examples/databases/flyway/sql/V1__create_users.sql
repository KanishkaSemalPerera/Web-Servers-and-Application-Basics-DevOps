-- Flyway naming: V<version>__<description>.sql   (TWO underscores)
-- Applied once, in version order. Never edit after it has run anywhere.

CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    full_name   VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

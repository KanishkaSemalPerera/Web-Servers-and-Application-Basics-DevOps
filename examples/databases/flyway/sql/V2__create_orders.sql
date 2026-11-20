CREATE TABLE orders (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT        NOT NULL REFERENCES users(id),
    total       NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    status      VARCHAR(20)   NOT NULL DEFAULT 'NEW',
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

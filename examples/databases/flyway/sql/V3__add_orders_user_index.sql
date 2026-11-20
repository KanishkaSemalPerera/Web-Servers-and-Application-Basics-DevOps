-- Backward-compatible change: adding an index does not break the running app version.
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Adding a NULLABLE column is also safe. Adding NOT NULL without a default would break old code.
ALTER TABLE users ADD COLUMN phone VARCHAR(30);

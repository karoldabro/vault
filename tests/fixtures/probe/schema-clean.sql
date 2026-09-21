-- A schema that breaks no rule.
CREATE TABLE customers (
  id BIGINT NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NULL
);

CREATE TABLE orders (
  id BIGINT NOT NULL PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  KEY idx_orders_customer (customer_id),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (id)
);

CREATE TABLE order_lines (
  id BIGINT NOT NULL PRIMARY KEY,
  order_id BIGINT NOT NULL,
  sku VARCHAR(40) NOT NULL,
  quantity INT NOT NULL,
  KEY idx_lines_order (order_id),
  FOREIGN KEY (order_id) REFERENCES orders (id)
);

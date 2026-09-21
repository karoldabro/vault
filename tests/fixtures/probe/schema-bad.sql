-- One defect of each rule. A line that ends in "expect: <rule>" is where the probe must report that rule.
CREATE TABLE customers (
  id BIGINT NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  phone VARCHAR(40),
  country_code CHAR(2),
  created_at TIMESTAMP NULL
);

CREATE TABLE customer_archive ( -- expect: dup-column-set
  id BIGINT NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  phone VARCHAR(40),
  country_code CHAR(2),
  created_at TIMESTAMP NULL
);

CREATE TABLE orders (
  id BIGINT NOT NULL PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (id) -- expect: fk-no-index
);

CREATE TABLE invoices (
  id BIGINT NOT NULL PRIMARY KEY,
  amount DECIMAL(10,2) NOT NULL,
  amount DECIMAL(10,2) NOT NULL -- expect: dup-column-in-table
);

CREATE TABLE OrderLines ( -- expect: naming-snake-case
  id BIGINT NOT NULL PRIMARY KEY,
  order_id BIGINT NOT NULL,
  INDEX idx_order (order_id)
);

-- =====================================================================
-- Food Delivery Order Management System  |  MySQL 8.0.16+ (CHECK enforced)
-- =====================================================================
DROP DATABASE IF EXISTS food_delivery;
CREATE DATABASE food_delivery CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE food_delivery;

-- ---------------------------------------------------------------------
-- 1. customers
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    phone        VARCHAR(15)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    city         VARCHAR(60)  NOT NULL,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_phone (phone),
    UNIQUE KEY uq_customers_email (email),
    KEY idx_customers_city (city)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. restaurants
-- ---------------------------------------------------------------------
CREATE TABLE restaurants (
    restaurant_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name          VARCHAR(120) NOT NULL,
    city          VARCHAR(60)  NOT NULL,
    cuisine       VARCHAR(50)  NOT NULL,
    is_open       TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (restaurant_id),
    UNIQUE KEY uq_restaurants_name_city (name, city),
    KEY idx_restaurants_city_cuisine (city, cuisine)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. menu_items  (stock lives here)
-- ---------------------------------------------------------------------
CREATE TABLE menu_items (
    item_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    restaurant_id  INT UNSIGNED  NOT NULL,
    name           VARCHAR(120)  NOT NULL,
    price          DECIMAL(8,2)  NOT NULL,
    stock_qty      INT           NOT NULL DEFAULT 0,
    is_available   TINYINT(1)    NOT NULL DEFAULT 1,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (item_id),
    UNIQUE KEY uq_menu_restaurant_item (restaurant_id, name),
    KEY idx_menu_restaurant_avail (restaurant_id, is_available),
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id) ON DELETE CASCADE,
    CONSTRAINT chk_menu_price CHECK (price > 0),
    CONSTRAINT chk_menu_stock CHECK (stock_qty >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. delivery_partners
-- ---------------------------------------------------------------------
CREATE TABLE delivery_partners (
    partner_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    phone       VARCHAR(15)  NOT NULL,
    city        VARCHAR(60)  NOT NULL,
    status      ENUM('available','busy','offline') NOT NULL DEFAULT 'offline',
    PRIMARY KEY (partner_id),
    UNIQUE KEY uq_partners_phone (phone),
    KEY idx_partners_city_status (city, status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. orders  (header)
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    customer_id    INT UNSIGNED  NOT NULL,
    restaurant_id  INT UNSIGNED  NOT NULL,
    partner_id     INT UNSIGNED  NULL,
    status         ENUM('placed','confirmed','preparing','out_for_delivery','delivered','cancelled')
                                 NOT NULL DEFAULT 'placed',
    total_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    KEY idx_orders_customer_created (customer_id, created_at),
    KEY idx_orders_restaurant_created (restaurant_id, created_at),
    KEY idx_orders_status_created (status, created_at),
    KEY idx_orders_partner (partner_id),
    CONSTRAINT fk_orders_customer   FOREIGN KEY (customer_id)   REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
    CONSTRAINT fk_orders_partner    FOREIGN KEY (partner_id)    REFERENCES delivery_partners (partner_id)
                                    ON DELETE SET NULL,
    CONSTRAINT chk_orders_total CHECK (total_amount >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. order_items  (lines; unit_price snapshots the price at order time)
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    order_id      INT UNSIGNED  NOT NULL,
    item_id       INT UNSIGNED  NOT NULL,
    quantity      INT           NOT NULL,
    unit_price    DECIMAL(8,2)  NOT NULL,
    PRIMARY KEY (order_item_id),
    UNIQUE KEY uq_order_item (order_id, item_id),
    KEY idx_order_items_item (item_id),
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_oi_item  FOREIGN KEY (item_id)  REFERENCES menu_items (item_id),
    CONSTRAINT chk_oi_qty   CHECK (quantity > 0),
    CONSTRAINT chk_oi_price CHECK (unit_price > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. payments
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    order_id    INT UNSIGNED  NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    method      ENUM('upi','card','cod','wallet') NOT NULL,
    status      ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
    paid_at     DATETIME      NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    KEY idx_payments_order (order_id),
    KEY idx_payments_status_paid (status, paid_at),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. order_status_log  (written by trigger trg_order_status_log)
-- ---------------------------------------------------------------------
CREATE TABLE order_status_log (
    log_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id    INT UNSIGNED    NOT NULL,
    old_status  VARCHAR(20)     NULL,
    new_status  VARCHAR(20)     NOT NULL,
    changed_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id),
    KEY idx_log_order_changed (order_id, changed_at),
    CONSTRAINT fk_log_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. stock_alerts  (written by trigger trg_low_stock_alert)
-- ---------------------------------------------------------------------
CREATE TABLE stock_alerts (
    alert_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    item_id     INT UNSIGNED NOT NULL,
    stock_qty   INT          NOT NULL,
    is_resolved TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (alert_id),
    KEY idx_alerts_item_resolved (item_id, is_resolved),
    CONSTRAINT fk_alerts_item FOREIGN KEY (item_id) REFERENCES menu_items (item_id) ON DELETE CASCADE
) ENGINE=InnoDB;

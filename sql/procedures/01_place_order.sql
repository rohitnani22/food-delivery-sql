USE food_delivery;

DROP PROCEDURE IF EXISTS place_order;
DELIMITER $$

CREATE PROCEDURE place_order(
    IN  p_customer_id   INT UNSIGNED,
    IN  p_restaurant_id INT UNSIGNED,
    IN  p_items         JSON,           
    IN  p_method        VARCHAR(10),     
    OUT p_order_id      INT UNSIGNED,
    OUT p_total         DECIMAL(10,2)
)
BEGIN
    DECLARE v_is_open     TINYINT;
    DECLARE v_line_count  INT DEFAULT 0;
    DECLARE v_updated     INT DEFAULT 0;
    DECLARE v_pay_status  VARCHAR(10);

    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS tmp_cart;
        SET p_order_id = NULL;
        SET p_total = NULL;
        RESIGNAL;
    END;

    
    IF p_method NOT IN ('upi', 'card', 'cod', 'wallet') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    SELECT is_open INTO v_is_open FROM restaurants WHERE restaurant_id = p_restaurant_id;
    IF v_is_open IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Restaurant not found';
    ELSEIF v_is_open = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Restaurant is closed';
    END IF;

    IF p_items IS NULL OR JSON_TYPE(p_items) <> 'ARRAY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Items must be a JSON array';
    END IF;

    -- ---------- 2. parse the JSON cart (duplicate items are merged) ----------
    DROP TEMPORARY TABLE IF EXISTS tmp_cart;
    CREATE TEMPORARY TABLE tmp_cart AS
    SELECT jt.item_id, CAST(SUM(jt.qty) AS SIGNED) AS qty
    FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
            item_id INT UNSIGNED PATH '$.item_id',
            qty     INT          PATH '$.qty')) AS jt
    GROUP BY jt.item_id;

    SELECT COUNT(*) INTO v_line_count FROM tmp_cart;
    IF v_line_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart is empty';
    END IF;
    IF EXISTS (SELECT 1 FROM tmp_cart WHERE item_id IS NULL OR qty IS NULL OR qty <= 0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Each item needs a valid item_id and qty > 0';
    END IF;


    START TRANSACTION;

    UPDATE menu_items m
    JOIN tmp_cart c ON c.item_id = m.item_id
    SET m.stock_qty = m.stock_qty - c.qty
    WHERE m.restaurant_id = p_restaurant_id
      AND m.is_available = 1
      AND m.stock_qty >= c.qty;
    SET v_updated = ROW_COUNT();         

    IF v_updated <> v_line_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'An item is unavailable, out of stock, or not on this restaurant''s menu';
    END IF;

    INSERT INTO orders (customer_id, restaurant_id, status, total_amount)
    VALUES (p_customer_id, p_restaurant_id, 'placed', 0);
    SET p_order_id = LAST_INSERT_ID();

  
    INSERT INTO order_items (order_id, item_id, quantity, unit_price)
    SELECT p_order_id, c.item_id, c.qty, m.price
    FROM tmp_cart c
    JOIN menu_items m ON m.item_id = c.item_id;

    SELECT SUM(quantity * unit_price) INTO p_total
    FROM order_items WHERE order_id = p_order_id;

    UPDATE orders SET total_amount = p_total WHERE order_id = p_order_id;

    SET v_pay_status = IF(p_method = 'cod', 'pending', 'paid');
    INSERT INTO payments (order_id, amount, method, status, paid_at)
    VALUES (p_order_id, p_total, p_method, v_pay_status,
            IF(v_pay_status = 'paid', NOW(), NULL));

    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS tmp_cart;
END$$

DELIMITER ;
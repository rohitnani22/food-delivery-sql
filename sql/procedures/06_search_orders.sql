USE food_delivery;

DROP PROCEDURE IF EXISTS search_orders;
DELIMITER $$

CREATE PROCEDURE search_orders(
    IN p_customer_id INT UNSIGNED,   -- NULL = any customer
    IN p_status      VARCHAR(20),    -- NULL = any status
    IN p_from        DATE,           -- NULL = no start date
    IN p_to          DATE,           -- NULL = no end date
    IN p_sort        VARCHAR(10),    -- 'date' or 'amount'
    IN p_limit       INT             -- 1-100, default 20
)
BEGIN
    DECLARE v_order_by VARCHAR(30);


    IF p_status IS NOT NULL AND p_status NOT IN
       ('placed','confirmed','preparing','out_for_delivery','delivered','cancelled') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status';
    END IF;
    IF p_from IS NOT NULL AND p_to IS NOT NULL AND p_from > p_to THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Start date is after end date';
    END IF;
    IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
        SET p_limit = 20;
    END IF;

   
    SET v_order_by = CASE p_sort
                         WHEN 'amount' THEN 'o.total_amount DESC'
                         ELSE 'o.created_at DESC'
                     END;

    
    SET @sp_sql = CONCAT(
        'SELECT o.order_id, c.name AS customer, r.name AS restaurant, ',
        'o.status, o.total_amount, o.created_at ',
        'FROM orders o ',
        'JOIN customers c ON c.customer_id = o.customer_id ',
        'JOIN restaurants r ON r.restaurant_id = o.restaurant_id ',
        'WHERE (? IS NULL OR o.customer_id = ?) ',
        'AND (? IS NULL OR o.status = ?) ',
        'AND (? IS NULL OR o.created_at >= ?) ',
        'AND (? IS NULL OR o.created_at < DATE_ADD(?, INTERVAL 1 DAY)) ',
        'ORDER BY ', v_order_by, ' LIMIT ?');

    SET @sp_c = p_customer_id;
    SET @sp_s = p_status;
    SET @sp_f = p_from;
    SET @sp_t = p_to;
    SET @sp_l = p_limit;

    PREPARE sp_stmt FROM @sp_sql;
    EXECUTE sp_stmt USING @sp_c, @sp_c, @sp_s, @sp_s, @sp_f, @sp_f, @sp_t, @sp_t, @sp_l;
    DEALLOCATE PREPARE sp_stmt;
END$$

DELIMITER ;
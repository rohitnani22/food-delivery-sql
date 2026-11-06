USE food_delivery;

DROP PROCEDURE IF EXISTS assign_delivery_partner;
DELIMITER $$

CREATE PROCEDURE assign_delivery_partner(IN p_order_id INT UNSIGNED)
BEGIN
    DECLARE v_status  VARCHAR(20);
    DECLARE v_partner INT UNSIGNED DEFAULT NULL;
    DECLARE v_current INT UNSIGNED DEFAULT NULL;
    DECLARE v_city    VARCHAR(60);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- lock the order row; also read the customer's city
    SELECT o.status, o.partner_id, c.city
    INTO v_status, v_current, v_city
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_id = p_order_id
    FOR UPDATE OF o;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    IF v_status NOT IN ('confirmed', 'preparing') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A partner can only be assigned to a confirmed or preparing order';
    END IF;
    IF v_current IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order already has a delivery partner';
    END IF;

    -- pick one free partner in the same city. SKIP LOCKED means that if another
    -- session is already grabbing a partner, we move on to the next free one.
    SELECT partner_id INTO v_partner
    FROM delivery_partners
    WHERE city = v_city AND status = 'available'
    ORDER BY partner_id
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_partner IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No delivery partner available in this city';
    END IF;

    UPDATE delivery_partners SET status = 'busy' WHERE partner_id = v_partner;
    UPDATE orders SET partner_id = v_partner WHERE order_id = p_order_id;

    COMMIT;

    SELECT p_order_id AS order_id, v_partner AS partner_id, v_city AS city, 'assigned' AS result;
END$$

DELIMITER ;
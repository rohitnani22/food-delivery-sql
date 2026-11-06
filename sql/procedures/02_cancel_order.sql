USE food_delivery;

DROP PROCEDURE IF EXISTS cancel_order;
DELIMITER $$

CREATE PROCEDURE cancel_order(IN p_order_id INT UNSIGNED)
BEGIN
    DECLARE v_status  VARCHAR(20);
    DECLARE v_partner INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT status, partner_id INTO v_status, v_partner
    FROM orders WHERE order_id = p_order_id FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    IF v_status NOT IN ('placed', 'confirmed', 'preparing') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order can no longer be cancelled (already out for delivery, delivered or cancelled)';
    END IF;

    UPDATE menu_items m
    JOIN order_items oi ON oi.item_id = m.item_id
    SET m.stock_qty = m.stock_qty + oi.quantity
    WHERE oi.order_id = p_order_id;


    UPDATE orders SET status = 'cancelled', partner_id = NULL WHERE order_id = p_order_id;

  
    IF v_partner IS NOT NULL THEN
        UPDATE delivery_partners SET status = 'available'
        WHERE partner_id = v_partner AND status = 'busy';
    END IF;

    UPDATE payments
    SET status = IF(status = 'paid', 'refunded', 'failed')
    WHERE order_id = p_order_id AND status IN ('paid', 'pending');

    COMMIT;

    SELECT p_order_id AS order_id, 'cancelled' AS result;
END$$

DELIMITER ;
USE food_delivery;

DROP PROCEDURE IF EXISTS update_order_status;
DELIMITER $$

CREATE PROCEDURE update_order_status(
    IN p_order_id   INT UNSIGNED,
    IN p_new_status VARCHAR(20)
)
BEGIN
    DECLARE v_status   VARCHAR(20);
    DECLARE v_partner  INT UNSIGNED;
    DECLARE v_expected VARCHAR(20);
    DECLARE v_msg      VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

  
    IF p_new_status = 'cancelled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Use cancel_order to cancel an order';
    END IF;
    IF p_new_status NOT IN ('confirmed', 'preparing', 'out_for_delivery', 'delivered') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status';
    END IF;

    START TRANSACTION;

    SELECT status, partner_id INTO v_status, v_partner
    FROM orders WHERE order_id = p_order_id FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;

 
    SET v_expected = CASE v_status
                         WHEN 'placed'           THEN 'confirmed'
                         WHEN 'confirmed'        THEN 'preparing'
                         WHEN 'preparing'        THEN 'out_for_delivery'
                         WHEN 'out_for_delivery' THEN 'delivered'
                         ELSE NULL
                     END;

    IF v_expected IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order is already delivered or cancelled';
    END IF;
    IF p_new_status <> v_expected THEN
        SET v_msg = CONCAT('Invalid step: order is ', v_status,
                           ', next allowed status is ', v_expected);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF p_new_status = 'out_for_delivery' AND v_partner IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assign a delivery partner first';
    END IF;

    UPDATE orders SET status = p_new_status WHERE order_id = p_order_id;

    IF p_new_status = 'delivered' THEN
  
        UPDATE delivery_partners SET status = 'available'
        WHERE partner_id = v_partner AND status = 'busy';
     
        UPDATE payments SET status = 'paid', paid_at = NOW()
        WHERE order_id = p_order_id AND status = 'pending';
    END IF;
	COMMIT;

    SELECT p_order_id AS order_id, v_status AS old_status, p_new_status AS new_status;
END$$

DELIMITER ;
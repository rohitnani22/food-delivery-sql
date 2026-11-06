USE food_delivery;

DROP TRIGGER IF EXISTS trg_block_unavailable_item;
DELIMITER $$

CREATE TRIGGER trg_block_unavailable_item
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_available  TINYINT;
    DECLARE v_item_rest  INT UNSIGNED;
    DECLARE v_order_rest INT UNSIGNED;

    IF @skip_triggers IS NULL THEN
        SELECT is_available, restaurant_id INTO v_available, v_item_rest
        FROM menu_items WHERE item_id = NEW.item_id;

        SELECT restaurant_id INTO v_order_rest
        FROM orders WHERE order_id = NEW.order_id;

        IF v_available = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item is not available';
        END IF;

        IF v_item_rest <> v_order_rest THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Item does not belong to the restaurant of this order';
        END IF;
    END IF;
END$$

DELIMITER ;
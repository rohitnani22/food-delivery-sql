USE food_delivery;

DROP TRIGGER IF EXISTS trg_order_placed_log;
DROP TRIGGER IF EXISTS trg_order_status_log;
DELIMITER $$


CREATE TRIGGER trg_order_placed_log
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF @skip_triggers IS NULL THEN
        INSERT INTO order_status_log (order_id, old_status, new_status)
        VALUES (NEW.order_id, NULL, NEW.status);
    END IF;
END$$


CREATE TRIGGER trg_order_status_log
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF @skip_triggers IS NULL AND NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO order_status_log (order_id, old_status, new_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);
    END IF;
END$$

DELIMITER ;
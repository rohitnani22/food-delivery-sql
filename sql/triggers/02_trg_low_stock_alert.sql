USE food_delivery;

DROP TRIGGER IF EXISTS trg_low_stock_alert;
DELIMITER $$

CREATE TRIGGER trg_low_stock_alert
AFTER UPDATE ON menu_items
FOR EACH ROW
BEGIN
    IF @skip_triggers IS NULL THEN


        IF NEW.stock_qty <= 5 AND NEW.stock_qty < OLD.stock_qty THEN
            IF NOT EXISTS (SELECT 1 FROM stock_alerts
                           WHERE item_id = NEW.item_id AND is_resolved = 0) THEN
                INSERT INTO stock_alerts (item_id, stock_qty)
                VALUES (NEW.item_id, NEW.stock_qty);
            END IF;

            ELSEIF NEW.stock_qty > 5 AND OLD.stock_qty <= 5 THEN
            UPDATE stock_alerts SET is_resolved = 1
            WHERE item_id = NEW.item_id AND is_resolved = 0;
        END IF;

    END IF;
END$$

DELIMITER ;
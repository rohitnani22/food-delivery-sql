USE food_delivery;

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id = 30;
SELECT * FROM stock_alerts WHERE item_id = 30;

UPDATE menu_items SET stock_qty = 7 WHERE item_id = 30;

SELECT * FROM stock_alerts WHERE item_id = 30;

CALL place_order(1, 3, '[{"item_id": 30, "qty": 3}]', 'upi', @o1, @t1);

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id = 30;
SELECT * FROM stock_alerts WHERE item_id = 30;

CALL place_order(1, 3, '[{"item_id": 30, "qty": 1}]', 'upi', @o2, @t2);
SELECT COUNT(*) AS alert_rows FROM stock_alerts WHERE item_id = 30;

UPDATE menu_items SET stock_qty = 50 WHERE item_id = 30;
SELECT * FROM stock_alerts WHERE item_id = 30;

CALL cancel_order(@o1);
CALL cancel_order(@o2);
UPDATE menu_items SET stock_qty = 105 WHERE item_id = 30;
SELECT item_id, name, stock_qty FROM menu_items WHERE item_id = 30;


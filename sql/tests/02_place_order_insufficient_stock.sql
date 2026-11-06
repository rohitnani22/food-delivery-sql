
USE food_delivery;
SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);
SELECT MAX(order_id) AS last_order_id FROM orders;

CALL place_order(1, 3, '[{"item_id": 25, "qty": 1}, {"item_id": 26, "qty": 9999}]', 'upi', @oid2, @total2);
SHOW ERRORS;

SELECT @oid2 AS order_id, @total2 AS total;
SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);
SELECT MAX(order_id) AS last_order_id FROM orders;
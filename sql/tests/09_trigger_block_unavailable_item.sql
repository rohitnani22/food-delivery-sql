USE food_delivery;

SELECT item_id, restaurant_id, name, stock_qty, is_available
FROM menu_items WHERE is_available = 0 LIMIT 3;

SELECT COUNT(*) AS lines_before FROM order_items WHERE order_id = 1;

INSERT INTO order_items (order_id, item_id, quantity, unit_price) VALUES (1, 479, 1, 100);
SHOW ERRORS;

SELECT item_id, restaurant_id, name, is_available
FROM menu_items
WHERE is_available = 1
  AND restaurant_id <> (SELECT restaurant_id FROM orders WHERE order_id = 1)
LIMIT 1;

INSERT INTO order_items (order_id, item_id, quantity, unit_price) VALUES (1, 8, 1, 100);
SHOW ERRORS;

SELECT COUNT(*) AS lines_after FROM order_items WHERE order_id = 1;

CALL place_order(1, 3, '[{"item_id": 27, "qty": 1}]', 'upi', @o5, @t5);
SELECT * FROM order_items WHERE order_id = @o5;
CALL cancel_order(@o5);
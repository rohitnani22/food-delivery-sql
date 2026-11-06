use food_delivery;
SELECT item_id, name, price, stock_qty FROM menu_items WHERE restaurant_id = 3;
CALL place_order(1, 3, '[{"item_id": 25, "qty": 2}, {"item_id": 26, "qty": 1}]', 'upi', @oid, @total);
SELECT @oid AS order_id, @total AS total;
SELECT * FROM orders WHERE order_id = 30001;
SELECT * FROM order_items WHERE order_id = 30001;
SELECT * FROM payments WHERE order_id = 30001;
SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);
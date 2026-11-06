
USE food_delivery;

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);
CALL cancel_order(30001);
SHOW ERRORS;

SELECT order_id, status FROM orders WHERE status = 'delivered' ORDER BY order_id LIMIT 1;

CALL cancel_order(D);
SHOW ERRORS;

CALL cancel_order(999999);
SHOW ERRORS;

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);

SELECT o.order_id, o.status AS order_status, p.status AS payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.order_id = 30001;
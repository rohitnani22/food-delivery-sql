USE food_delivery;
SELECT o.order_id, o.status AS order_status, o.partner_id, p.method, p.status AS payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.order_id = 30001;

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);

CALL cancel_order(30001);

SELECT o.order_id, o.status AS order_status, o.partner_id, p.method, p.status AS payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.order_id = 30001;

SELECT item_id, name, stock_qty FROM menu_items WHERE item_id IN (25, 26);
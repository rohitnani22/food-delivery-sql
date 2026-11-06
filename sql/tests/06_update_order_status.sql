
USE food_delivery;
SELECT o.order_id, o.status, o.partner_id, p.method, p.status AS payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.status = 'placed'
ORDER BY o.order_id LIMIT 3;


CALL update_order_status(29857, 'confirmed');


CALL update_order_status(29857, 'preparing');


CALL update_order_status(29857, 'out_for_delivery');
SHOW ERRORS;

CALL assign_delivery_partner(29857);

CALL update_order_status(29857, 'out_for_delivery');

SELECT partner_id, name, status FROM delivery_partners WHERE partner_id = 10;

CALL update_order_status(29857, 'delivered');

SELECT o.order_id, o.status AS order_status, o.partner_id, p.method, p.status AS payment_status
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.order_id = 29857;

SELECT partner_id, name, status FROM delivery_partners WHERE partner_id = 10;

CALL update_order_status(29858, 'delivered');
SHOW ERRORS;

CALL update_order_status(29857, 'preparing');
SHOW ERRORS;

CALL update_order_status(29858, 'cancelled');
SHOW ERRORS;

CALL update_order_status(29858, 'flying');
SHOW ERRORS;

CALL update_order_status(999999, 'confirmed');
SHOW ERRORS;
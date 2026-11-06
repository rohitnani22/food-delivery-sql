
USE food_delivery;

SELECT o.order_id, o.status, o.partner_id, c.city
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'confirmed'
ORDER BY o.order_id LIMIT 3;

SELECT partner_id, name, city, status
FROM delivery_partners
WHERE city = 'Chennai' AND status = 'available'
ORDER BY partner_id LIMIT 5;

CALL assign_delivery_partner(29851);

SELECT order_id, status, partner_id FROM orders WHERE order_id = 29851;

SELECT partner_id, name, city, status FROM delivery_partners WHERE partner_id = 18;

CALL assign_delivery_partner(18);
SHOW ERRORS;

SELECT order_id, status FROM orders WHERE status = 'placed' ORDER BY order_id LIMIT 1;
CALL assign_delivery_partner(29857);        -- replace Y with that order_id
SHOW ERRORS;

CALL assign_delivery_partner(1);
SHOW ERRORS;

CALL assign_delivery_partner(999999);
SHOW ERRORS;
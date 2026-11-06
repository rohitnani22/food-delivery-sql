USE food_delivery;

SELECT order_id, status, partner_id
FROM orders
WHERE status = 'confirmed' AND partner_id IS NULL
ORDER BY order_id LIMIT 3;

SELECT * FROM order_status_log WHERE order_id = 29860 ORDER BY log_id;

CALL update_order_status(29860, 'preparing');

SELECT * FROM order_status_log WHERE order_id = 29860 ORDER BY log_id;

SELECT COUNT(*) AS log_rows_before FROM order_status_log WHERE order_id = 29860;
CALL assign_delivery_partner(29860);
SELECT COUNT(*) AS log_rows_after FROM order_status_log WHERE order_id = 29860;

CALL place_order(1, 3, '[{"item_id": 27, "qty": 1}]', 'cod', @oid3, @total3);
SELECT @oid3 AS new_order_id;
SELECT * FROM order_status_log WHERE order_id = @oid3 ORDER BY log_id;

CALL cancel_order(@oid3);
SELECT * FROM order_status_log WHERE order_id = @oid3 ORDER BY log_id;
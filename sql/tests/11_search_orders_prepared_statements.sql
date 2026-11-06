USE food_delivery;

PREPARE stmt FROM 'SELECT order_id, status, total_amount FROM orders WHERE customer_id = ? AND status = ? LIMIT 5';
SET @cust = 1, @st = 'delivered';
EXECUTE stmt USING @cust, @st;
DEALLOCATE PREPARE stmt;

CALL search_orders(1, NULL, NULL, NULL, 'date', 10);

CALL search_orders(NULL, 'cancelled', '2026-01-01', '2026-03-31', 'amount', 5);

CALL search_orders(1, 'delivered', NULL, NULL, 'amount', 5);

CALL search_orders(1, 'flying', NULL, NULL, 'date', 10);
SHOW ERRORS;

SET @evil = "delivered' OR '1'='1";
SET @bad_sql = CONCAT("SELECT COUNT(*) AS rows_returned FROM orders WHERE status = '", @evil, "'");
PREPARE bad FROM @bad_sql;
EXECUTE bad;
DEALLOCATE PREPARE bad;

PREPARE good FROM 'SELECT COUNT(*) AS rows_returned FROM orders WHERE status = ?';
EXECUTE good USING @evil;
DEALLOCATE PREPARE good;
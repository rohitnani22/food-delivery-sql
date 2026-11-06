USE food_delivery;

CALL monthly_revenue_report(2026);

SELECT COUNT(*) AS orders, SUM(total_amount) AS revenue
FROM orders
WHERE status = 'delivered'
  AND created_at >= '2026-03-01' AND created_at < '2026-04-01';

CALL monthly_revenue_report(2025);

CALL monthly_revenue_report(1900);
SHOW ERRORS;
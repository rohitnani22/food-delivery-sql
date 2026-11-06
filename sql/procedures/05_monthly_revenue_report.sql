USE food_delivery;

DROP PROCEDURE IF EXISTS monthly_revenue_report;
DELIMITER $$

CREATE PROCEDURE monthly_revenue_report(IN p_year INT)
BEGIN
    IF p_year IS NULL OR p_year < 2000 OR p_year > 2100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Please give a valid year (2000-2100)';
    END IF;

    WITH monthly AS (
        SELECT DATE_FORMAT(created_at, '%Y-%m') AS month_label,
               COUNT(*)                         AS orders,
               SUM(total_amount)                AS revenue
        FROM orders
        WHERE status = 'delivered'
          AND created_at >= MAKEDATE(p_year, 1)
          AND created_at <  MAKEDATE(p_year + 1, 1)
        GROUP BY DATE_FORMAT(created_at, '%Y-%m')
    )
    SELECT month_label,
           orders,
           revenue,
           ROUND(revenue / orders, 2) AS avg_order_value,
           ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month_label))
                     / LAG(revenue) OVER (ORDER BY month_label), 1) AS mom_growth_pct,
           SUM(revenue) OVER (ORDER BY month_label)                 AS running_total,
           RANK() OVER (ORDER BY revenue DESC)                      AS revenue_rank
    FROM monthly
    ORDER BY month_label;
END$$

DELIMITER ;
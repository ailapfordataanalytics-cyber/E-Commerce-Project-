/* ============================================================
   E-COMMERCE REPORTING DATA EXTRACTION SCRIPT
   Database: EcommercePlatform
   Purpose : Analytics / Power BI / Reporting
   ============================================================ */

------------------------------------------------------------
-- 1. PRODUCTS REPORT (Products + Categories)
------------------------------------------------------------
SELECT 
    p.product_id,
    p.name AS product_name,
    p.sku,
    p.base_price,
    p.current_price,
    p.stock_quantity,
    c.name AS category_name,
    p.status AS product_status
FROM Products.Products p
LEFT JOIN Products.Categories c
    ON p.category_id = c.category_id;


------------------------------------------------------------
-- 2. ORDERS WITH CUSTOMER INFO
------------------------------------------------------------
SELECT 
    o.order_id,
    o.order_number,
    u.full_name AS customer_name,
    u.email AS customer_email,
    o.order_date,
    o.status AS order_status,
    o.total_amount
FROM Sales.Orders o
INNER JOIN People.Users u
    ON o.user_id = u.user_id;


------------------------------------------------------------
-- 3. ORDER DETAILS (ORDER ITEMS)
------------------------------------------------------------
SELECT 
    o.order_number,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price,
    oi.final_price
FROM Sales.OrderItems oi
INNER JOIN Sales.Orders o
    ON oi.order_id = o.order_id
INNER JOIN Products.Products p
    ON oi.product_id = p.product_id;


------------------------------------------------------------
-- 4. PAYMENTS REPORT
------------------------------------------------------------
SELECT 
    pay.payment_id,
    o.order_number,
    pay.amount,
    pay.payment_method,
    pay.status AS payment_status,
    pay.payment_date
FROM Finance.Payments pay
INNER JOIN Sales.Orders o
    ON pay.order_id = o.order_id;


------------------------------------------------------------
-- 5. SHIPPING TRACKING REPORT
------------------------------------------------------------
SELECT 
    s.shipment_id,
    o.order_number,
    s.tracking_number,
    s.carrier,
    s.status AS shipping_status,
    s.picked_up_at,
    s.in_transit_at,
    s.delivered_at
FROM Logistics.Shipping s
INNER JOIN Sales.Orders o
    ON s.order_id = o.order_id;


------------------------------------------------------------
-- 6. FULL SALES DASHBOARD VIEW (ALL-IN-ONE)
------------------------------------------------------------
SELECT 
    o.order_number,
    u.full_name AS customer_name,
    p.name AS product_name,
    oi.quantity,
    oi.final_price,
    pay.payment_method,
    pay.status AS payment_status,
    s.carrier,
    s.status AS shipping_status
FROM Sales.Orders o
INNER JOIN People.Users u
    ON o.user_id = u.user_id
INNER JOIN Sales.OrderItems oi
    ON o.order_id = oi.order_id
INNER JOIN Products.Products p
    ON oi.product_id = p.product_id
LEFT JOIN Finance.Payments pay
    ON o.order_id = pay.order_id
LEFT JOIN Logistics.Shipping s
    ON o.order_id = s.order_id;


------------------------------------------------------------
-- 7. TOP SELLING PRODUCTS
------------------------------------------------------------
SELECT 
    p.name AS product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.final_price) AS total_revenue
FROM Sales.OrderItems oi
INNER JOIN Products.Products p
    ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_revenue DESC;


------------------------------------------------------------
-- 8. CUSTOMER PERFORMANCE REPORT
------------------------------------------------------------
SELECT 
    u.full_name AS customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM People.Users u
LEFT JOIN Sales.Orders o
    ON u.user_id = o.user_id
GROUP BY u.full_name
ORDER BY total_spent DESC;
-------------------------------------------------------------
/* ============================================================
   EDA / POWER BI DATASET - ECOMMERCE PLATFORM
   One unified analytical table (Star Schema Style Flattened)
   ============================================================ */

SELECT 
    -- =========================
    -- ORDER INFO
    -- =========================
    o.order_id,
    o.order_number,
    o.order_date,
    o.status AS order_status,
    o.total_amount,
    o.subtotal,
    o.discount_amount,
    o.tax_amount,
    o.shipping_cost,

    -- =========================
    -- CUSTOMER INFO
    -- =========================
    u.user_id,
    u.full_name AS customer_name,
    u.email,
    u.city,
    u.country,
    u.role AS user_role,

    -- =========================
    -- PRODUCT INFO
    -- =========================
    p.product_id,
    p.name AS product_name,
    p.sku,
    p.base_price,
    p.current_price,
    p.stock_quantity,

    c.name AS category_name,

    -- =========================
    -- ORDER ITEM INFO
    -- =========================
    oi.quantity,
    oi.unit_price,
    oi.final_price,

    -- =========================
    -- PAYMENT INFO
    -- =========================
    pay.payment_method,
    pay.status AS payment_status,
    pay.amount AS payment_amount,

    -- =========================
    -- SHIPPING INFO
    -- =========================
    s.carrier,
    s.status AS shipping_status,
    s.picked_up_at,
    s.in_transit_at,
    s.delivered_at,

    -- =========================
    -- TIME FEATURES (VERY IMPORTANT FOR EDA)
    -- =========================
    YEAR(o.order_date) AS order_year,
    MONTH(o.order_date) AS order_month,
    DATENAME(MONTH, o.order_date) AS month_name,
    DATENAME(WEEKDAY, o.order_date) AS order_day_name,

    -- =========================
    -- KPIs / DERIVED METRICS
    -- =========================
    DATEDIFF(DAY, o.order_date, ISNULL(s.delivered_at, GETDATE())) AS delivery_time_days,

    CASE 
        WHEN s.delivered_at IS NOT NULL THEN 'Delivered'
        WHEN s.in_transit_at IS NOT NULL THEN 'In Transit'
        WHEN s.picked_up_at IS NOT NULL THEN 'Shipped'
        ELSE 'Processing'
    END AS delivery_stage,

    CASE 
        WHEN o.total_amount >= 1000 THEN 'High Value'
        WHEN o.total_amount >= 300 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment

FROM Sales.Orders o

-- Customer
INNER JOIN People.Users u
    ON o.user_id = u.user_id

-- Order Items
INNER JOIN Sales.OrderItems oi
    ON o.order_id = oi.order_id

-- Products
INNER JOIN Products.Products p
    ON oi.product_id = p.product_id

-- Category
LEFT JOIN Products.Categories c
    ON p.category_id = c.category_id

-- Payment
LEFT JOIN Finance.Payments pay
    ON o.order_id = pay.order_id

-- Shipping
LEFT JOIN Logistics.Shipping s
    ON o.order_id = s.order_id;
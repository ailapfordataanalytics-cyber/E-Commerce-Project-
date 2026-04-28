-- ============================================================
-- Complete E-commerce Platform Database for SQL Server (SSMS)
-- With Comprehensive Features Explained in Comments
-- ============================================================

-- ============================================================
-- FEATURE 1: Using Schemas for Logical Organization
-- This enables better permission management and responsibility separation
-- ============================================================
CREATE DATABASE  EcommercePlatform;
CREATE SCHEMA Sales;
GO
CREATE SCHEMA Products;
GO
CREATE SCHEMA People;
GO
CREATE SCHEMA Logistics;
GO
CREATE SCHEMA Finance;
GO
CREATE SCHEMA System;
GO

-- ============================================================
-- FEATURE 2: Product Categories with Hierarchical Support
-- ParentId enables multi-level categories (Men's Clothing > Shirts > Summer Shirts)
-- ============================================================
CREATE TABLE Products.Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(MAX),
    parent_category_id INT NULL,  -- Enables hierarchical categorization
    is_active BIT NOT NULL DEFAULT 1,  -- Disable a category without deleting data
    display_order INT DEFAULT 0,  -- Control display order in store
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    -- Self-referential foreign key for hierarchy
    FOREIGN KEY (parent_category_id) REFERENCES Products.Categories(category_id),
    
    -- Optimized indexes for fast searching
    INDEX IX_Categories_ParentId (parent_category_id),
    INDEX IX_Categories_IsActive (is_active)
);
GO

-- ============================================================
-- FEATURE 3: Comprehensive Users Table with Advanced Security Features
-- Includes session tracking, account status, and password recovery mechanism
-- ============================================================
CREATE TABLE People.Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Basic Information
    full_name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    phone NVARCHAR(20) NULL,
    
    -- Security: Separate password hash from token (for 2FA)
    password_hash NVARCHAR(255) NOT NULL,
    password_salt NVARCHAR(64) NOT NULL,  -- Unique salt per user
    two_factor_secret NVARCHAR(255) NULL,  -- Two-factor authentication support
    
    -- Account Management
    role NVARCHAR(20) NOT NULL DEFAULT 'Buyer' 
        CHECK (role IN (N'Buyer', N'Seller', N'Admin', N'Support', N'Moderator')),
    is_active BIT NOT NULL DEFAULT 1,
    is_email_verified BIT NOT NULL DEFAULT 0,
    is_phone_verified BIT NOT NULL DEFAULT 0,
    email_verification_token NVARCHAR(255) NULL,
    password_reset_token NVARCHAR(255) NULL,
    password_reset_expiry DATETIME NULL,
    
    -- Activity Tracking (important for security and analytics)
    last_login_at DATETIME NULL,
    last_login_ip NVARCHAR(45) NULL,  -- Supports IPv6
    login_attempts INT NOT NULL DEFAULT 0,
    locked_until DATETIME NULL,
    
    -- Address Information
    address_line1 NVARCHAR(255) NULL,
    address_line2 NVARCHAR(255) NULL,
    city NVARCHAR(100) NULL,
    state_province NVARCHAR(100) NULL,
    postal_code NVARCHAR(20) NULL,
    country NVARCHAR(100) NOT NULL DEFAULT N'Saudi Arabia',
    
    -- User Preferences
    preferred_language NVARCHAR(10) DEFAULT N'en',
    currency_code NVARCHAR(3) DEFAULT N'SAR',
    
    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,  -- Soft Delete support
    
    -- Optimized indexes for searching
    INDEX IX_Users_Email (email),
    INDEX IX_Users_Role_Active (role, is_active) INCLUDE (user_id, full_name),
    INDEX IX_Users_LastLogin (last_login_at),
    INDEX IX_Users_City (city, country)
);
GO

-- ============================================================
-- FEATURE 4: User Audit Log Table
-- Tracks every important action for security and compliance
-- ============================================================
CREATE TABLE People.UserAuditLog (
    audit_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    action_type NVARCHAR(50) NOT NULL,  -- LOGIN, LOGOUT, PASSWORD_CHANGE, ROLE_CHANGE, PROFILE_UPDATE
    ip_address NVARCHAR(45) NOT NULL,
    user_agent NVARCHAR(500) NULL,
    details NVARCHAR(MAX) NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    
    -- High-performance index
    INDEX IX_UserAudit_UserId_Date (user_id, created_at DESC),
    INDEX IX_UserAudit_ActionType (action_type, created_at DESC)
);
GO

-- ============================================================
-- FEATURE 5: Comprehensive Products Table with Unique SKU, Weights, and Discounts
-- ============================================================
CREATE TABLE Products.Products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Globally unique SKU (critical for inventory management and synchronization)
    sku NVARCHAR(100) NOT NULL UNIQUE,
    barcode NVARCHAR(100) NULL UNIQUE,
    
    name NVARCHAR(255) NOT NULL,
    descriptions NVARCHAR(255) NULL,
    short_description NVARCHAR(500) NULL,
    
    -- Advanced pricing support
    base_price DECIMAL(12, 2) NOT NULL CHECK (base_price >= 0),
    current_price DECIMAL(12, 2) NOT NULL,
    cost_price DECIMAL(12, 2) NULL,  -- Purchase cost (for profit calculation)
    discount_percentage DECIMAL(5, 2) NULL CHECK (discount_percentage BETWEEN 0 AND 100),
    discount_start_date DATETIME NULL,
    discount_end_date DATETIME NULL,
    
    -- Advanced inventory management
    stock_quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,  -- Products in user carts not yet ordered
    low_stock_threshold INT NOT NULL DEFAULT 5,
    is_in_stock BIT NOT NULL DEFAULT 0,  -- Automatically calculated via Trigger
    
    -- Shipping data
    weight_kg DECIMAL(10, 3) NULL,
    length_cm DECIMAL(8, 2) NULL,
    width_cm DECIMAL(8, 2) NULL,
    height_cm DECIMAL(8, 2) NULL,
    
    -- SEO and categorization
    slug NVARCHAR(255) NOT NULL UNIQUE,  -- SEO-friendly URL
    meta_title NVARCHAR(255) NULL,
    meta_description NVARCHAR(500) NULL,
    
    -- Relationships
    category_id INT NULL,
    seller_id INT NOT NULL,
    
    -- Product status (Published, Pending Review, Banned)
    status NVARCHAR(20) NOT NULL DEFAULT 'Draft' 
        CHECK (status IN (N'Draft', N'Pending', N'Published', N'Archived', N'Banned')),
    
    -- Statistics (can be updated via Triggers or Jobs)
    total_views INT NOT NULL DEFAULT 0,
    total_sold INT NOT NULL DEFAULT 0,
    avg_rating DECIMAL(3, 2) NULL,
    total_reviews INT NOT NULL DEFAULT 0,
    
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    published_at DATETIME NULL,
    
    FOREIGN KEY (category_id) REFERENCES Products.Categories(category_id),
    FOREIGN KEY (seller_id) REFERENCES People.Users(user_id),
    
    -- Optimized indexes for search and filtering
    INDEX IX_Products_Seller_Status (seller_id, status),
    INDEX IX_Products_Category_Price (category_id, current_price) INCLUDE (name, slug),
    INDEX IX_Products_Search (name, descriptions),
    INDEX IX_Products_Slug (slug),
    INDEX IX_Products_Discount (discount_start_date, discount_end_date) WHERE discount_percentage > 0,
    INDEX IX_Products_StockStatus (stock_quantity, low_stock_threshold) INCLUDE (product_id, name)
);
GO

-- ============================================================
-- FEATURE 6: Product Images Table (One-to-Many Relationship)
-- Supports multiple images, ordering, and primary image designation
-- ============================================================
CREATE TABLE Products.ProductImages (
    image_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    image_url NVARCHAR(2000) NOT NULL,
    alt_text NVARCHAR(255) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_primary BIT NOT NULL DEFAULT 0,
    image_size_bytes INT NULL,
    image_width INT NULL,
    image_height INT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id) ON DELETE CASCADE,
    
    -- Index for fast primary image retrieval
    INDEX IX_ProductImages_Product (product_id, is_primary, sort_order),
    
    -- Trigger ensures only one primary image per product
);
GO

-- ============================================================
-- FEATURE 7: Orders Table with Discount, Tax, and Shipping Cost Support
-- ============================================================
CREATE TABLE Sales.Orders (
    order_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Readable unique order number for tracking
    order_number NVARCHAR(50) NOT NULL UNIQUE,
    
    user_id INT NOT NULL,
    
    order_date DATETIME NOT NULL DEFAULT GETDATE(),
    
    -- Complete order lifecycle
    status NVARCHAR(50) NOT NULL DEFAULT 'Pending'
        CHECK (status IN (N'Pending', N'Payment_Processing', N'Paid', N'Processing', 
                          N'Shipped', N'Delivered', N'Completed', N'Cancelled', N'Refunded', N'Disputed')),
    
    -- Detailed financial breakdown
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    shipping_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    
    -- Coupon information
    coupon_code NVARCHAR(100) NULL,
    coupon_discount DECIMAL(12, 2) NULL,
    
    -- Shipping information
    shipping_address_line1 NVARCHAR(255) NOT NULL,
    shipping_address_line2 NVARCHAR(255) NULL,
    shipping_city NVARCHAR(100) NOT NULL,
    shipping_state NVARCHAR(100) NULL,
    shipping_postal_code NVARCHAR(20) NOT NULL,
    shipping_country NVARCHAR(100) NOT NULL,
    
    -- Separate billing address from shipping address
    billing_address_same_as_shipping BIT NOT NULL DEFAULT 1,
    billing_address_line1 NVARCHAR(255) NULL,
    billing_city NVARCHAR(100) NULL,
    billing_country NVARCHAR(100) NULL,
    
    -- Important date tracking
    payment_date DATETIME NULL,
    processing_date DATETIME NULL,
    shipping_date DATETIME NULL,
    delivery_date DATETIME NULL,
    cancellation_date DATETIME NULL,
    cancellation_reason NVARCHAR(500) NULL,
    
    -- Notes
    customer_notes NVARCHAR(1000) NULL,
    admin_notes NVARCHAR(1000) NULL,
    
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    
    -- Multiple indexes for reporting and searching
    INDEX IX_Orders_User_Status (user_id, status) INCLUDE (order_number, total_amount),
    INDEX IX_Orders_Date (order_date DESC),
    INDEX IX_Orders_Status_Date (status, order_date) INCLUDE (order_number, total_amount),
    INDEX IX_Orders_Tracking (order_number)
);
GO

-- ============================================================
-- FEATURE 8: Order Items Table with Frozen Price at Purchase Time
-- This protects against product price changes after purchase
-- ============================================================
CREATE TABLE Sales.OrderItems (
    order_item_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price >= 0),
    total_price AS (quantity * unit_price) PERSISTED,  -- Computed column for performance
    
    -- Per-item discount tracking
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    final_price DECIMAL(12, 2) NOT NULL,  -- unit_price × quantity - discount
    
    -- Product information snapshot at purchase time (backup)
    product_name_snapshot NVARCHAR(255) NOT NULL,
    product_sku_snapshot NVARCHAR(100) NOT NULL,
    
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (order_id) REFERENCES Sales.Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id),
    
    -- Optimized indexes
    INDEX IX_OrderItems_OrderId (order_id),
    INDEX IX_OrderItems_ProductId (product_id),
    
    -- Composite key excellent for table joins
    UNIQUE (order_id, product_id)
);
GO

-- ============================================================
-- FEATURE 9: Integrated Payments System with Multiple Payment Method Support
-- ============================================================
CREATE TABLE Finance.Payments (
    payment_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id BIGINT NOT NULL,
    
    -- Unique identifier from payment gateway
    gateway_transaction_id NVARCHAR(255) NOT NULL,
    gateway_reference NVARCHAR(255) NULL,
    gateway_response NVARCHAR(MAX) NULL,  -- Store full gateway response for audit
    
    amount DECIMAL(12, 2) NOT NULL,
    currency NVARCHAR(3) NOT NULL DEFAULT N'SAR',
    
    -- Supported payment methods
    payment_method NVARCHAR(50) NOT NULL
        CHECK (payment_method IN (N'Credit_Card', N'Debit_Card', N'PayPal', N'Mada', N'STC_Pay', N'Cash_On_Delivery', N'Bank_Transfer')),
    
    -- Card details (encrypted)
    card_last_four NVARCHAR(4) NULL,
    card_brand NVARCHAR(20) NULL,
    
    -- Payment status
    status NVARCHAR(50) NOT NULL DEFAULT 'Pending'
        CHECK (status IN (N'Pending', N'Processing', N'Completed', N'Failed', N'Refunded', N'Chargeback')),
    
    -- Attempt tracking and actions
    attempt_count INT NOT NULL DEFAULT 1,
    failure_reason NVARCHAR(500) NULL,
    
    refund_amount DECIMAL(12, 2) DEFAULT 0,
    refund_date DATETIME NULL,
    refund_reason NVARCHAR(500) NULL,
    
    payment_date DATETIME NOT NULL DEFAULT GETDATE(),
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (order_id) REFERENCES Sales.Orders(order_id),
    
    -- Indexes for fast searching
    INDEX IX_Payments_OrderId (order_id),
    INDEX IX_Payments_Transaction (gateway_transaction_id),
    INDEX IX_Payments_Status_Date (status, payment_date),
    INDEX IX_Payments_Method (payment_method)
);
GO

-- ============================================================
-- FEATURE 10: Reviews Table with Duplicate Review Prevention
-- ============================================================
CREATE TABLE Products.Reviews (
    review_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    order_id BIGINT NULL,  -- Links review to specific order (ensures verified purchase)
    
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title NVARCHAR(255) NULL,
    comment NVARCHAR(MAX) NULL,
    
    -- Images in reviews
    has_images BIT NOT NULL DEFAULT 0,
    
    -- Admin response
    admin_response NVARCHAR(MAX) NULL,
    admin_response_date DATETIME NULL,
    
    -- Hide inappropriate reviews
    is_approved BIT NOT NULL DEFAULT 1,
    is_verified_purchase BIT NOT NULL DEFAULT 0,  -- "Verified Buyer" badge
    
    helpful_count INT NOT NULL DEFAULT 0,
    unhelpful_count INT NOT NULL DEFAULT 0,
    
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id),
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    FOREIGN KEY (order_id) REFERENCES Sales.Orders(order_id),
    
    -- Prevents duplicate review of same product by same user
    CONSTRAINT UQ_Product_User UNIQUE (product_id, user_id),
    
    -- Optimized indexes
    INDEX IX_Reviews_Product_Rating (product_id, rating DESC) INCLUDE (comment, title),
    INDEX IX_Reviews_User (user_id),
    INDEX IX_Reviews_Created (created_at DESC)
);
GO

-- ============================================================
-- FEATURE 11: Shopping Cart with Session Support for Guest Users
-- ============================================================
CREATE TABLE Sales.ShoppingCart (
    cart_item_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Supports guest users (SessionId) and registered users (UserId)
    user_id INT NULL,
    session_id NVARCHAR(255) NULL,
    
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    
    -- Save price at add-to-cart time
    price_at_add DECIMAL(12, 2) NOT NULL,
    
    added_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id),
    
    -- Ensures at least one identifier exists
    CHECK (user_id IS NOT NULL OR session_id IS NOT NULL),
    
    -- Composite indexes for speed
    INDEX IX_ShoppingCart_User (user_id),
    INDEX IX_ShoppingCart_Session (session_id),
    
    -- Prevents duplicate product in same user's cart
    CONSTRAINT UQ_Cart_User_Product UNIQUE (user_id, product_id),
    CONSTRAINT UQ_Cart_Session_Product UNIQUE (session_id, product_id)
);
GO

-- ============================================================
-- FEATURE 12: Integrated Shipping System with Tracking
-- ============================================================
CREATE TABLE Logistics.Shipping (
    shipment_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id BIGINT NOT NULL,
    
    tracking_number NVARCHAR(100) NOT NULL UNIQUE,
    carrier NVARCHAR(100) NOT NULL,
    
    -- Shipping information
    weight_kg DECIMAL(10, 3) NULL,
    dimensions NVARCHAR(100) NULL,
    
    -- Supports split shipments (multiple parts)
    is_split_shipment BIT NOT NULL DEFAULT 0,
    parent_shipment_id BIGINT NULL,
    
    -- Shipping timeline
    label_generated_at DATETIME NULL,
    picked_up_at DATETIME NULL,
    in_transit_at DATETIME NULL,
    out_for_delivery_at DATETIME NULL,
    delivered_at DATETIME NULL,
    failed_at DATETIME NULL,
    returned_at DATETIME NULL,
    
    -- Delivery address (can differ from order address)
    delivery_address_line1 NVARCHAR(255) NOT NULL,
    delivery_city NVARCHAR(100) NOT NULL,
    delivery_postal_code NVARCHAR(20) NOT NULL,
    delivery_country NVARCHAR(100) NOT NULL,
    
    -- Region tracking for geographic analytics
    region NVARCHAR(100) NULL,
    
    status NVARCHAR(50) NOT NULL DEFAULT 'Pending'
        CHECK (status IN (N'Pending', N'Label_Created', N'Picked_Up', N'In_Transit', N'Out_For_Delivery', N'Delivered', N'Failed', N'Returned')),
    
    -- Shipping notes
    courier_notes NVARCHAR(500) NULL,
    delivery_photo_url NVARCHAR(2000) NULL,
    signature_received NVARCHAR(255) NULL,
    
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (order_id) REFERENCES Sales.Orders(order_id),
    FOREIGN KEY (parent_shipment_id) REFERENCES Logistics.Shipping(shipment_id),
    
    -- Optimized indexes
    INDEX IX_Shipping_OrderId (order_id),
    INDEX IX_Shipping_Tracking (tracking_number),
    INDEX IX_Shipping_Status (status),
    INDEX IX_Shipping_DeliveryDate (delivered_at),
    INDEX IX_Shipping_Region (region)
);
GO

-- ============================================================
-- FEATURE 13: Advanced Inventory Management with Historical Tracking
-- ============================================================
CREATE TABLE Products.InventoryTransaction (
    transaction_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    
    transaction_type NVARCHAR(50) NOT NULL
        CHECK (transaction_type IN (N'Restock', N'Sale', N'Return', N'Adjustment', N'Reserved', N'Released')),
    
    quantity INT NOT NULL,  -- Can be negative for deductions
    
    reference_id NVARCHAR(255) NULL,  -- Order number or purchase order number
    reference_type NVARCHAR(50) NULL,  -- Order, PurchaseOrder, Adjustment
    
    -- Transaction details
    reason NVARCHAR(500) NULL,
    performed_by INT NOT NULL,  -- User who performed the transaction
    
    transaction_date DATETIME NOT NULL DEFAULT GETDATE(),
    notes NTEXT NULL,
    
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id),
    FOREIGN KEY (performed_by) REFERENCES People.Users(user_id),
    
    -- Indexes for analysis
    INDEX IX_InventoryTransaction_Product (product_id, transaction_date DESC),
    INDEX IX_InventoryTransaction_Type (transaction_type, transaction_date),
    INDEX IX_InventoryTransaction_Reference (reference_id)
);
GO

-- ============================================================
-- FEATURE 14: Coupons and Discounts with Usage Tracking and Validity Periods
-- ============================================================
CREATE TABLE Sales.Coupons (
    coupon_id INT IDENTITY(1,1) PRIMARY KEY,
    
    coupon_code NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(500) NULL,
    
    -- Discount types
    discount_type NVARCHAR(20) NOT NULL CHECK (discount_type IN (N'Percentage', N'Fixed_Amount')),
    discount_value DECIMAL(12, 2) NOT NULL CHECK (discount_value > 0),
    
    -- Usage conditions
    minimum_order_amount DECIMAL(12, 2) NULL,
    maximum_discount_amount DECIMAL(12, 2) NULL,
    
    -- Applicable to specific products or categories
    applicable_to_all_products BIT NOT NULL DEFAULT 1,
    applicable_products NVARCHAR(MAX) NULL,  -- JSON or comma-separated
    applicable_categories NVARCHAR(MAX) NULL,
    
    -- Specific users limitation
    applicable_users NVARCHAR(MAX) NULL,
    
    -- Usage limits
    usage_limit_per_coupon INT NULL,
    usage_limit_per_user INT NULL,
    current_usage_count INT NOT NULL DEFAULT 0,
    
    -- Validity period
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    
    is_active BIT NOT NULL DEFAULT 1,
    
    created_by INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    FOREIGN KEY (created_by) REFERENCES People.Users(user_id),
    
    INDEX IX_Coupons_Code (coupon_code),
    INDEX IX_Coupons_Active (is_active, start_date, end_date)
);
GO

-- ============================================================
-- FEATURE 15: Coupon Usage Tracking
-- ============================================================
CREATE TABLE Sales.CouponUsage (
    usage_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    coupon_id INT NOT NULL,
    order_id BIGINT NOT NULL,
    user_id INT NOT NULL,
    discount_applied DECIMAL(12, 2) NOT NULL,
    used_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (coupon_id) REFERENCES Sales.Coupons(coupon_id),
    FOREIGN KEY (order_id) REFERENCES Sales.Orders(order_id),
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    
    -- Prevents using same coupon twice for the same order
    CONSTRAINT UQ_CouponUsage_Order UNIQUE (order_id, coupon_id),
    
    INDEX IX_CouponUsage_Coupon (coupon_id),
    INDEX IX_CouponUsage_User (user_id)
);
GO

-- ============================================================
-- FEATURE 16: Wishlist with Price Drop and Restock Notifications
-- ============================================================
CREATE TABLE Products.Wishlist (
    wishlist_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    
    -- Notifications when product becomes available or price drops
    notify_on_price_drop BIT NOT NULL DEFAULT 0,
    target_price DECIMAL(12, 2) NULL,
    notify_on_restock BIT NOT NULL DEFAULT 0,
    is_notified BIT NOT NULL DEFAULT 0,
    
    added_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (user_id) REFERENCES People.Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products.Products(product_id),
    
    -- Prevents duplicate product in wishlist
    CONSTRAINT UQ_Wishlist_User_Product UNIQUE (user_id, product_id),
    
    INDEX IX_Wishlist_User (user_id),
    INDEX IX_Wishlist_Notify (notify_on_price_drop, notify_on_restock, is_notified)
);
GO

-- ============================================================
-- FEATURE 17: System Audit Log for Compliance and Security
-- Records every change on important tables
-- ============================================================
CREATE TABLE System.AuditLog (
    audit_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    table_name NVARCHAR(128) NOT NULL,
    record_id NVARCHAR(255) NOT NULL,
    action NVARCHAR(20) NOT NULL CHECK (action IN (N'INSERT', N'UPDATE', N'DELETE')),
    old_data NVARCHAR(MAX) NULL,  -- JSON format
    new_data NVARCHAR(MAX) NULL,  -- JSON format
    changed_by_user_id INT NULL,
    changed_by_ip NVARCHAR(45) NULL,
    changed_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    FOREIGN KEY (changed_by_user_id) REFERENCES People.Users(user_id),
    
    -- Indexes for quick audit search
    INDEX IX_Audit_Table_Record (table_name, record_id),
    INDEX IX_Audit_Date (changed_at DESC),
    INDEX IX_Audit_User (changed_by_user_id)
);
GO

-- ============================================================
-- FEATURE 18: View for Comprehensive Order Summary Report (CORRECTED)
-- Makes it easy for business analysts to get ready-to-use data
-- Fixed: Removed non-existent 'shipping_date' column
-- ============================================================
CREATE VIEW Sales.vw_OrderSummary
AS
SELECT 
    o.order_id,
    o.order_number,
    u.full_name AS customer_name,
    u.email AS customer_email,
    o.order_date,
    o.status AS order_status,
    o.subtotal,
    o.discount_amount,
    o.tax_amount,
    o.shipping_cost,
    o.total_amount,
    p.payment_method,
    p.status AS payment_status,
    s.carrier,
    s.tracking_number,
    s.status AS shipping_status,
    s.delivered_at,
    s.picked_up_at,
    s.label_generated_at,
    s.in_transit_at,
    DATEDIFF(DAY, o.order_date, ISNULL(s.delivered_at, GETDATE())) AS days_to_delivery,
    -- Fixed: Using actual columns from Shipping table instead of non-existent 'shipping_date'
    CASE 
        WHEN s.delivered_at IS NOT NULL THEN 'Delivered'
        WHEN s.picked_up_at IS NOT NULL THEN 'Shipped'  -- Using picked_up_at instead of shipping_date
        WHEN s.label_generated_at IS NOT NULL THEN 'Label Created'
        WHEN p.payment_date IS NOT NULL THEN 'Paid'
        ELSE 'Processing'
    END AS current_phase
FROM Sales.Orders o
INNER JOIN People.Users u ON o.user_id = u.user_id
LEFT JOIN Finance.Payments p ON o.order_id = p.order_id AND p.status = 'Completed'
LEFT JOIN Logistics.Shipping s ON o.order_id = s.order_id;
GO
-- ============================================================
-- FEATURE 19: Trigger to Automatically Update Stock When Order is Created
-- ============================================================
CREATE TRIGGER trg_OrderItems_UpdateStock
ON Sales.OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update product stock levels
    UPDATE p
    SET p.stock_quantity = p.stock_quantity - i.quantity,
        p.total_sold = p.total_sold + i.quantity,
        p.is_in_stock = CASE WHEN (p.stock_quantity - i.quantity) > 0 THEN 1 ELSE 0 END,
        p.updated_at = GETDATE()
    FROM Products.Products p
    INNER JOIN inserted i ON p.product_id = i.product_id;
    
    -- Record inventory transaction
    INSERT INTO Products.InventoryTransaction (product_id, transaction_type, quantity, reference_id, reference_type, reason, performed_by, transaction_date)
    SELECT 
        i.product_id,
        'Sale',
        -i.quantity,
        CAST(i.order_id AS NVARCHAR(50)),
        'Order',
        'Auto: Order placed',
        1,  -- System user ID (assumes system user exists)
        GETDATE()
    FROM inserted i;
END;
GO

-- ============================================================
-- FEATURE 20: Stored Procedure to Get Best-Selling Products
-- ============================================================
CREATE PROCEDURE Sales.sp_GetTopSellingProducts
    @start_date DATE,
    @end_date DATE,
    @top_n INT = 10
AS
BEGIN
    SELECT TOP (@top_n)
        p.product_id,
        p.name AS product_name,
        p.sku,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.final_price) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders,
        AVG(CAST(r.rating AS DECIMAL(3,2))) AS avg_rating
    FROM Products.Products p
    INNER JOIN Sales.OrderItems oi ON p.product_id = oi.product_id
    INNER JOIN Sales.Orders o ON oi.order_id = o.order_id
    LEFT JOIN Products.Reviews r ON p.product_id = r.product_id AND r.is_approved = 1
    WHERE o.order_date BETWEEN @start_date AND @end_date
      AND o.status NOT IN ('Cancelled', 'Refunded')
    GROUP BY p.product_id, p.name, p.sku
    ORDER BY total_revenue DESC;
END;
GO

-- ============================================================
-- FEATURE 21: Trigger for Automatic Audit Logging
-- ============================================================
-- First, ensure the System.AuditLog table exists in System schema
-- If not, create the System schema first
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'System')
BEGIN
    EXEC('CREATE SCHEMA System');
END
GO

-- Create AuditLog table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog' AND SCHEMA_NAME(schema_id) = 'System')
BEGIN
    CREATE TABLE System.AuditLog (
        audit_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        table_name NVARCHAR(128) NOT NULL,
        record_id NVARCHAR(255) NOT NULL,
        action NVARCHAR(20) NOT NULL CHECK (action IN (N'INSERT', N'UPDATE', N'DELETE')),
        old_data NVARCHAR(MAX) NULL,
        new_data NVARCHAR(MAX) NULL,
        changed_by_user_id INT NULL,
        changed_by_ip NVARCHAR(45) NULL,
        changed_at DATETIME NOT NULL DEFAULT GETDATE(),
        
        FOREIGN KEY (changed_by_user_id) REFERENCES People.Users(user_id),
        
        INDEX IX_Audit_Table_Record (table_name, record_id),
        INDEX IX_Audit_Date (changed_at DESC),
        INDEX IX_Audit_User (changed_by_user_id)
    );
END
GO

-- ============================================================
-- CORRECTED TRIGGER: Created in Products schema (same as Products.Products table)
-- ============================================================
CREATE TRIGGER Products.trg_Audit_Products
ON Products.Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- For INSERT and UPDATE operations
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO System.AuditLog (table_name, record_id, action, old_data, new_data, changed_at)
        SELECT 
            'Products.Products',
            CAST(COALESCE(i.product_id, d.product_id) AS NVARCHAR(255)),
            CASE WHEN EXISTS(SELECT * FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END,
            (SELECT * FROM deleted d2 WHERE d2.product_id = COALESCE(i.product_id, d.product_id) FOR JSON PATH),
            (SELECT * FROM inserted i2 WHERE i2.product_id = COALESCE(i.product_id, d.product_id) FOR JSON PATH),
            GETDATE()
        FROM inserted i
        FULL OUTER JOIN deleted d ON i.product_id = d.product_id;
    END
    
    -- For DELETE operations
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO System.AuditLog (table_name, record_id, action, old_data, new_data, changed_at)
        SELECT 
            'Products.Products',
            CAST(product_id AS NVARCHAR(255)),
            'DELETE',
            (SELECT * FROM deleted d2 WHERE d2.product_id = d.product_id FOR JSON PATH),
            NULL,
            GETDATE()
        FROM deleted d;
    END
END;
GO

-- ============================================================
-- FEATURE 22: Stored Procedure for Monthly Sales Analytics
-- ============================================================
CREATE PROCEDURE Sales.sp_GetMonthlySalesReport
    @year INT,
    @month INT = NULL
AS
BEGIN
    SELECT 
        YEAR(order_date) AS sale_year,
        MONTH(order_date) AS sale_month,
        DATENAME(MONTH, order_date) AS month_name,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value,
        SUM(shipping_cost) AS total_shipping_cost,
        SUM(discount_amount) AS total_discounts,
        COUNT(DISTINCT user_id) AS unique_customers,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        (SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS cancellation_rate
    FROM Sales.Orders
    WHERE YEAR(order_date) = @year
      AND (@month IS NULL OR MONTH(order_date) = @month)
      AND status != 'Pending'  -- Exclude pending orders from analytics
    GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
    ORDER BY sale_year, sale_month;
END;
GO

-- ============================================================
-- FEATURE 23: Function to Calculate Customer Lifetime Value (LTV)
-- ============================================================
CREATE FUNCTION Sales.fn_GetCustomerLTV(@user_id INT)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @ltv DECIMAL(12, 2);
    
    SELECT @ltv = SUM(total_amount)
    FROM Sales.Orders
    WHERE user_id = @user_id
      AND status IN ('Delivered', 'Completed')
      AND order_date >= DATEADD(MONTH, -12, GETDATE());
    
    RETURN ISNULL(@ltv, 0);
END;
GO

-- ============================================================
-- FEATURE 24: View for Inventory Status with Alerts
-- ============================================================
CREATE VIEW Products.vw_InventoryStatus
AS
SELECT 
    p.product_id,
    p.name AS product_name,
    p.sku,
    p.stock_quantity,
    p.reserved_quantity,
    (p.stock_quantity - p.reserved_quantity) AS available_quantity,
    p.low_stock_threshold,
    CASE 
        WHEN p.stock_quantity <= 0 THEN 'Out of Stock'
        WHEN p.stock_quantity <= p.low_stock_threshold THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    CASE 
        WHEN p.stock_quantity <= p.low_stock_threshold AND p.stock_quantity > 0 THEN 'Restock Recommended'
        WHEN p.stock_quantity <= 0 THEN 'URGENT - Out of Stock'
        ELSE 'OK'
    END AS action_required,
    ISNULL((
        SELECT SUM(quantity) 
        FROM Sales.OrderItems oi 
        INNER JOIN Sales.Orders o ON oi.order_id = o.order_id
        WHERE oi.product_id = p.product_id 
          AND o.order_date >= DATEADD(DAY, -30, GETDATE())
    ), 0) AS last_30_days_sales
FROM Products.Products p;
GO

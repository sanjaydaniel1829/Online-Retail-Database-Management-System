/* =====================================================================================
   ONLINE RETAIL DATABASE MANAGEMENT SYSTEM
   SQL Server 2026
   Author : Sambathini Sanjay Daniel
   -------------------------------------------------------------------------------------
   This script builds the ENTIRE project end to end. Run it top to bottom in
   SQL Server Management Studio (SSMS) or Azure Data Studio.

   CONTENTS
   1.  Database creation
   2.  Tables (Categories, Customers, Products, Orders, OrderItems)
   3.  Constraints & relationships
   4.  Sample data (INSERT statements)
   5.  Indexes (performance)
   6.  Views
   7.  Triggers (logging + business rules)
   8.  Advanced SELECT queries: JOINs, aggregations, subqueries, window functions
   9.  Role-Based Access Control (RBAC): logins, roles, permissions
   10. Stored procedures (optional bonus for analysis)
   ===================================================================================== */


/* =====================================================================================
   1. DATABASE CREATION
   ===================================================================================== */
IF DB_ID('OnlineRetailDB') IS NOT NULL
BEGIN
    ALTER DATABASE OnlineRetailDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OnlineRetailDB;
END
GO

CREATE DATABASE OnlineRetailDB;
GO

USE OnlineRetailDB;
GO


/* =====================================================================================
   2. TABLE CREATION
   ===================================================================================== */

-- ---------------------------------------------------------------------------
-- 2.1 Categories
-- ---------------------------------------------------------------------------
CREATE TABLE Categories (
    CategoryID      INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName    VARCHAR(100) NOT NULL UNIQUE,
    Description     VARCHAR(255) NULL
);
GO

-- ---------------------------------------------------------------------------
-- 2.2 Customers
-- ---------------------------------------------------------------------------
CREATE TABLE Customers (
    CustomerID      INT IDENTITY(1,1) PRIMARY KEY,
    FirstName       VARCHAR(50)  NOT NULL,
    LastName        VARCHAR(50)  NOT NULL,
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Phone           VARCHAR(20)  NULL,
    City            VARCHAR(50)  NULL,
    State           VARCHAR(50)  NULL,
    Country         VARCHAR(50)  NULL,
    RegisteredDate  DATETIME     NOT NULL DEFAULT GETDATE()
);
GO

-- ---------------------------------------------------------------------------
-- 2.3 Products
-- ---------------------------------------------------------------------------
CREATE TABLE Products (
    ProductID       INT IDENTITY(1,1) PRIMARY KEY,
    ProductName     VARCHAR(150) NOT NULL,
    CategoryID      INT NOT NULL,
    Price           DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    StockQuantity   INT NOT NULL CHECK (StockQuantity >= 0),
    CreatedDate     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);
GO

-- ---------------------------------------------------------------------------
-- 2.4 Orders
-- ---------------------------------------------------------------------------
CREATE TABLE Orders (
    OrderID         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID      INT NOT NULL,
    OrderDate       DATETIME NOT NULL DEFAULT GETDATE(),
    OrderStatus     VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (OrderStatus IN ('Pending','Processing','Shipped','Delivered','Cancelled')),
    TotalAmount     DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
);
GO

-- ---------------------------------------------------------------------------
-- 2.5 OrderItems
-- ---------------------------------------------------------------------------
CREATE TABLE OrderItems (
    OrderItemID     INT IDENTITY(1,1) PRIMARY KEY,
    OrderID         INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL CHECK (Quantity > 0),
    UnitPrice       DECIMAL(10,2) NOT NULL,
    LineTotal       AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID)
        REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);
GO

-- ---------------------------------------------------------------------------
-- 2.6 Audit log table (supports triggers in section 7)
-- ---------------------------------------------------------------------------
CREATE TABLE AuditLog (
    AuditID         INT IDENTITY(1,1) PRIMARY KEY,
    TableName       VARCHAR(50)  NOT NULL,
    Operation       VARCHAR(10)  NOT NULL,
    RecordID        INT          NULL,
    ActionBy        VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ActionDate      DATETIME     NOT NULL DEFAULT GETDATE(),
    Details         VARCHAR(500) NULL
);
GO


/* =====================================================================================
   3. SAMPLE DATA
   ===================================================================================== */

-- 3.1 Categories
INSERT INTO Categories (CategoryName, Description) VALUES
('Electronics', 'Phones, laptops, accessories'),
('Clothing', 'Men, women and kids apparel'),
('Home & Kitchen', 'Appliances and household items'),
('Books', 'Fiction and non-fiction books'),
('Sports', 'Sports gear and equipment');
GO

-- 3.2 Customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, City, State, Country) VALUES
('Ravi', 'Kumar', 'ravi.kumar@mail.com', '9876543210', 'Hyderabad', 'Telangana', 'India'),
('Sneha', 'Reddy', 'sneha.reddy@mail.com', '9876500011', 'Bengaluru', 'Karnataka', 'India'),
('John', 'Smith', 'john.smith@mail.com', '4155550100', 'San Francisco', 'CA', 'USA'),
('Maria', 'Garcia', 'maria.garcia@mail.com', '3125550101', 'Chicago', 'IL', 'USA'),
('Ayesha', 'Khan', 'ayesha.khan@mail.com', '9998887771', 'Mumbai', 'Maharashtra', 'India'),
('David', 'Lee', 'david.lee@mail.com', '2065550111', 'Seattle', 'WA', 'USA');
GO

-- 3.3 Products
INSERT INTO Products (ProductName, CategoryID, Price, StockQuantity) VALUES
('Wireless Mouse', 1, 799.00, 150),
('Bluetooth Headphones', 1, 2499.00, 80),
('Smartphone X200', 1, 24999.00, 40),
('Men Cotton T-Shirt', 2, 499.00, 200),
('Women Kurti', 2, 899.00, 120),
('Non-Stick Pan', 3, 1299.00, 60),
('Mixer Grinder', 3, 3499.00, 35),
('The Silent Patient (Book)', 4, 349.00, 100),
('Atomic Habits (Book)', 4, 399.00, 150),
('Yoga Mat', 5, 599.00, 90),
('Cricket Bat', 5, 1999.00, 45);
GO

-- 3.4 Orders + OrderItems (sample transactions)
INSERT INTO Orders (CustomerID, OrderDate, OrderStatus, TotalAmount) VALUES
(1, '2026-06-01', 'Delivered', 0),
(2, '2026-06-03', 'Delivered', 0),
(3, '2026-06-05', 'Shipped', 0),
(1, '2026-06-10', 'Processing', 0),
(4, '2026-06-12', 'Delivered', 0),
(5, '2026-06-15', 'Cancelled', 0),
(6, '2026-06-18', 'Pending', 0),
(2, '2026-07-01', 'Delivered', 0);
GO

INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 2, 799.00),
(1, 8, 1, 349.00),
(2, 4, 3, 499.00),
(2, 10, 1, 599.00),
(3, 3, 1, 24999.00),
(4, 2, 1, 2499.00),
(4, 9, 2, 399.00),
(5, 6, 1, 1299.00),
(5, 7, 1, 3499.00),
(6, 5, 2, 899.00),
(7, 11, 1, 1999.00),
(8, 1, 1, 799.00),
(8, 9, 1, 399.00);
GO

-- 3.5 Sync Orders.TotalAmount from OrderItems (also handled automatically by trigger later)
UPDATE o
SET o.TotalAmount = t.SumTotal
FROM Orders o
JOIN (
    SELECT OrderID, SUM(LineTotal) AS SumTotal
    FROM OrderItems
    GROUP BY OrderID
) t ON t.OrderID = o.OrderID;
GO


/* =====================================================================================
   4. INDEXES (Performance)
   ===================================================================================== */

-- Speed up product lookups by category
CREATE NONCLUSTERED INDEX IX_Products_CategoryID ON Products(CategoryID);

-- Speed up order lookups by customer and date
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);

-- Speed up order item joins
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID ON OrderItems(OrderID);
CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID ON OrderItems(ProductID);

-- Unique index to enforce fast email lookups (Email already UNIQUE, this documents intent)
CREATE NONCLUSTERED INDEX IX_Customers_Email ON Customers(Email);
GO


/* =====================================================================================
   5. VIEWS
   ===================================================================================== */

-- 5.1 Detailed order view: joins Orders, Customers, OrderItems, Products
CREATE VIEW vw_OrderDetails AS
SELECT
    o.OrderID,
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    oi.Quantity,
    oi.UnitPrice,
    oi.LineTotal,
    o.OrderDate,
    o.OrderStatus
FROM Orders o
JOIN Customers c   ON c.CustomerID = o.CustomerID
JOIN OrderItems oi ON oi.OrderID   = o.OrderID
JOIN Products p    ON p.ProductID  = oi.ProductID
JOIN Categories cat ON cat.CategoryID = p.CategoryID;
GO

-- 5.2 Customer order summary
CREATE VIEW vw_CustomerOrderSummary AS
SELECT
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(DISTINCT o.OrderID)      AS TotalOrders,
    ISNULL(SUM(o.TotalAmount), 0)  AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;
GO

-- 5.3 Product sales performance
CREATE VIEW vw_ProductSales AS
SELECT
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    SUM(oi.Quantity)   AS UnitsSold,
    SUM(oi.LineTotal)  AS Revenue
FROM Products p
JOIN Categories cat ON cat.CategoryID = p.CategoryID
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName, cat.CategoryName;
GO


/* =====================================================================================
   6. TRIGGERS
   ===================================================================================== */

-- 6.1 Auto-reduce stock and log it whenever a new OrderItem is inserted
CREATE TRIGGER trg_OrderItems_ReduceStock
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.StockQuantity = p.StockQuantity - i.Quantity
    FROM Products p
    JOIN inserted i ON i.ProductID = p.ProductID;

    INSERT INTO AuditLog (TableName, Operation, RecordID, Details)
    SELECT 'OrderItems', 'INSERT', i.OrderItemID,
           'Stock reduced for ProductID ' + CAST(i.ProductID AS VARCHAR) +
           ' by ' + CAST(i.Quantity AS VARCHAR)
    FROM inserted i;
END;
GO

-- 6.2 Auto-update Orders.TotalAmount whenever OrderItems change
CREATE TRIGGER trg_OrderItems_UpdateOrderTotal
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH AffectedOrders AS (
        SELECT OrderID FROM inserted
        UNION
        SELECT OrderID FROM deleted
    )
    UPDATE o
    SET o.TotalAmount = ISNULL((
        SELECT SUM(oi.LineTotal)
        FROM OrderItems oi
        WHERE oi.OrderID = o.OrderID
    ), 0)
    FROM Orders o
    JOIN AffectedOrders ao ON ao.OrderID = o.OrderID;
END;
GO

-- 6.3 Audit trigger for new customers (logging)
CREATE TRIGGER trg_Customers_AuditInsert
ON Customers
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, Details)
    SELECT 'Customers', 'INSERT', i.CustomerID,
           'New customer registered: ' + i.FirstName + ' ' + i.LastName
    FROM inserted i;
END;
GO

-- 6.4 Prevent negative stock updates directly on Products (business rule enforcement)
CREATE TRIGGER trg_Products_PreventNegativeStock
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE StockQuantity < 0)
    BEGIN
        RAISERROR('Stock quantity cannot be negative.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


/* =====================================================================================
   7. ADVANCED QUERIES: JOINS, AGGREGATIONS, SUBQUERIES, WINDOW FUNCTIONS
   (Run these individually to see results/analysis)
   ===================================================================================== */

-- 7.1 INNER JOIN: list every order item with customer and product names
SELECT o.OrderID, c.FirstName + ' ' + c.LastName AS Customer,
       p.ProductName, oi.Quantity, oi.LineTotal
FROM Orders o
INNER JOIN Customers c  ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems oi ON oi.OrderID   = o.OrderID
INNER JOIN Products p   ON p.ProductID  = oi.ProductID
ORDER BY o.OrderID;
GO

-- 7.2 LEFT JOIN: show all customers even if they have never ordered
SELECT c.CustomerID, c.FirstName + ' ' + c.LastName AS Customer,
       COUNT(o.OrderID) AS OrdersPlaced
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY OrdersPlaced DESC;
GO

-- 7.3 Aggregation: total revenue and average order value per category
SELECT cat.CategoryName,
       SUM(oi.LineTotal)                AS TotalRevenue,
       AVG(oi.LineTotal)                AS AvgLineValue,
       COUNT(DISTINCT o.OrderID)        AS OrdersCount
FROM Categories cat
JOIN Products p     ON p.CategoryID = cat.CategoryID
JOIN OrderItems oi  ON oi.ProductID = p.ProductID
JOIN Orders o       ON o.OrderID    = oi.OrderID
GROUP BY cat.CategoryName
ORDER BY TotalRevenue DESC;
GO

-- 7.4 Subquery: customers who spent more than the average customer total spend
SELECT CustomerID, CustomerName, TotalSpent
FROM vw_CustomerOrderSummary
WHERE TotalSpent > (
    SELECT AVG(TotalSpent) FROM vw_CustomerOrderSummary
)
ORDER BY TotalSpent DESC;
GO

-- 7.5 Subquery: products that have never been ordered
SELECT ProductID, ProductName
FROM Products
WHERE ProductID NOT IN (
    SELECT DISTINCT ProductID FROM OrderItems
);
GO

-- 7.6 Correlated subquery: each customer's most recent order date
SELECT c.CustomerID, c.FirstName + ' ' + c.LastName AS Customer,
       (SELECT MAX(o.OrderDate)
        FROM Orders o
        WHERE o.CustomerID = c.CustomerID) AS LastOrderDate
FROM Customers c
ORDER BY LastOrderDate DESC;
GO

-- 7.7 Window function: running total of revenue by order date
SELECT o.OrderID, o.OrderDate, o.TotalAmount,
       SUM(o.TotalAmount) OVER (ORDER BY o.OrderDate
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM Orders o
ORDER BY o.OrderDate;
GO

-- 7.8 Window function: rank products by revenue within each category
SELECT cat.CategoryName, p.ProductName,
       SUM(oi.LineTotal) AS Revenue,
       RANK() OVER (PARTITION BY cat.CategoryName ORDER BY SUM(oi.LineTotal) DESC) AS RevenueRank
FROM Categories cat
JOIN Products p    ON p.CategoryID = cat.CategoryID
JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY cat.CategoryName, p.ProductName
ORDER BY cat.CategoryName, RevenueRank;
GO

-- 7.9 Window function: each customer's orders with row number and total spend to date
SELECT c.FirstName + ' ' + c.LastName AS Customer, o.OrderID, o.OrderDate, o.TotalAmount,
       ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS OrderSequence,
       SUM(o.TotalAmount) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS CumulativeSpend
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID
ORDER BY Customer, OrderSequence;
GO

-- 7.10 Window function: top 3 best-selling products overall (using DENSE_RANK)
SELECT * FROM (
    SELECT p.ProductName, SUM(oi.Quantity) AS TotalUnitsSold,
           DENSE_RANK() OVER (ORDER BY SUM(oi.Quantity) DESC) AS SalesRank
    FROM Products p
    JOIN OrderItems oi ON oi.ProductID = p.ProductID
    GROUP BY p.ProductName
) ranked
WHERE SalesRank <= 3;
GO


/* =====================================================================================
   8. ROLE-BASED ACCESS CONTROL (RBAC)
   ===================================================================================== */

-- 8.1 Create SQL Server logins (server level) -- change passwords before real use
CREATE LOGIN AdminLogin       WITH PASSWORD = 'Adm!n#2026Secure';
CREATE LOGIN SalesLogin       WITH PASSWORD = 'Sal3s#2026Secure';
CREATE LOGIN AnalystLogin     WITH PASSWORD = 'Anly#2026Secure';
GO

-- 8.2 Create database users mapped to those logins
CREATE USER AdminUser   FOR LOGIN AdminLogin;
CREATE USER SalesUser   FOR LOGIN SalesLogin;
CREATE USER AnalystUser FOR LOGIN AnalystLogin;
GO

-- 8.3 Create custom database roles
CREATE ROLE db_admin_role;
CREATE ROLE db_sales_role;
CREATE ROLE db_analyst_role;
GO

-- 8.4 Assign users to roles
ALTER ROLE db_admin_role   ADD MEMBER AdminUser;
ALTER ROLE db_sales_role   ADD MEMBER SalesUser;
ALTER ROLE db_analyst_role ADD MEMBER AnalystUser;
GO

-- 8.5 Grant permissions per role
-- Admin: full control over all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO db_admin_role;

-- Sales: can manage orders and order items, read-only on products/customers
GRANT SELECT, INSERT, UPDATE ON Orders      TO db_sales_role;
GRANT SELECT, INSERT, UPDATE ON OrderItems  TO db_sales_role;
GRANT SELECT ON Customers                   TO db_sales_role;
GRANT SELECT ON Products                    TO db_sales_role;

-- Analyst: read-only access to everything, mainly the views
GRANT SELECT ON vw_OrderDetails            TO db_analyst_role;
GRANT SELECT ON vw_CustomerOrderSummary    TO db_analyst_role;
GRANT SELECT ON vw_ProductSales            TO db_analyst_role;
GRANT SELECT ON Orders                     TO db_analyst_role;
GRANT SELECT ON OrderItems                 TO db_analyst_role;
GRANT SELECT ON Products                   TO db_analyst_role;
GRANT SELECT ON Customers                  TO db_analyst_role;
GO

-- 8.6 Explicitly deny sensitive access (example: analysts cannot see AuditLog)
DENY SELECT ON AuditLog TO db_analyst_role;
GO


/* =====================================================================================
   9. STORED PROCEDURES (bonus – reusable analysis)
   ===================================================================================== */

-- 9.1 Get full order history for a given customer
CREATE PROCEDURE usp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.OrderID, o.OrderDate, o.OrderStatus, o.TotalAmount
    FROM Orders o
    WHERE o.CustomerID = @CustomerID
    ORDER BY o.OrderDate DESC;
END;
GO

-- 9.2 Monthly sales report
CREATE PROCEDURE usp_MonthlySalesReport
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        DATENAME(MONTH, o.OrderDate) AS OrderMonth,
        MONTH(o.OrderDate)           AS MonthNumber,
        COUNT(DISTINCT o.OrderID)    AS TotalOrders,
        SUM(o.TotalAmount)           AS TotalRevenue
    FROM Orders o
    WHERE YEAR(o.OrderDate) = @Year
    GROUP BY DATENAME(MONTH, o.OrderDate), MONTH(o.OrderDate)
    ORDER BY MonthNumber;
END;
GO

-- Example executions (uncomment to test):
-- EXEC usp_GetCustomerOrders @CustomerID = 1;
-- EXEC usp_MonthlySalesReport @Year = 2026;


/* =====================================================================================
   END OF SCRIPT
   Run sections in order. Sections 7 and 9 are safe to re-run any time for analysis.
   Sections 1-6 and 8 should be run only once during initial setup.
   ===================================================================================== */

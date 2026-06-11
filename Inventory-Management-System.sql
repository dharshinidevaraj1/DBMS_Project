-- ============================================================
--  Inventory Management System — Full Database Script
--  MySQL 8.0+
--  Covers: DDL, Constraints, Joins, Queries, Views,
--          Stored Procedures, Triggers, Functions
-- ============================================================

CREATE DATABASE IF NOT EXISTS inventory_db;
USE inventory_db;


-- ============================================================
-- SECTION 1: TABLE CREATION
-- ============================================================

-- Categories first — Products will reference this
CREATE TABLE Categories (
    CategoryID   INT          AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    Description  TEXT         DEFAULT NULL,
    CreatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- Suppliers
CREATE TABLE Suppliers (
    SupplierID INT          AUTO_INCREMENT PRIMARY KEY,
    Name       VARCHAR(150) NOT NULL,
    Contact    VARCHAR(20)  NOT NULL,
    Email      VARCHAR(150) NOT NULL UNIQUE,
    CreatedAt  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- Products — links to both Categories and Suppliers
CREATE TABLE Products (
    ProductID  INT            AUTO_INCREMENT PRIMARY KEY,
    Name       VARCHAR(200)   NOT NULL,
    Price      DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    CategoryID INT            NOT NULL,
    SupplierID INT            DEFAULT NULL,
    SKU        VARCHAR(50)    NOT NULL UNIQUE,
    IsActive   TINYINT(1)     NOT NULL DEFAULT 1,
    CreatedAt  DATETIME       DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Inventory — one row per product, tracks stock vs reorder threshold
CREATE TABLE Inventory (
    InventoryID INT      AUTO_INCREMENT PRIMARY KEY,
    ProductID   INT      NOT NULL UNIQUE,
    Quantity    INT      NOT NULL DEFAULT 0  CHECK (Quantity >= 0),
    Threshold   INT      NOT NULL DEFAULT 10 CHECK (Threshold >= 0),
    LastUpdated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Customers — auto increment ID, loyalty points earned per order
CREATE TABLE Customers (
    CustomerID    INT          AUTO_INCREMENT PRIMARY KEY,
    Name          VARCHAR(150) NOT NULL,
    Phone         VARCHAR(20)  NOT NULL UNIQUE,
    Email         VARCHAR(150) DEFAULT NULL,
    LoyaltyPoints INT          NOT NULL DEFAULT 0 CHECK (LoyaltyPoints >= 0),
    JoinedAt      DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- Transactions — every purchase goes here
CREATE TABLE Transactions (
    TransactionID   INT            AUTO_INCREMENT PRIMARY KEY,
    ProductID       INT            NOT NULL,
    CustomerID      INT            DEFAULT NULL,
    Quantity        INT            NOT NULL CHECK (Quantity > 0),
    AmountPaid      DECIMAL(12, 2) NOT NULL,
    TransactionDate DATETIME       DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID)  REFERENCES Products(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Alert log — softer alternative to hard SIGNAL for low-stock warnings
CREATE TABLE StockAlerts (
    AlertID         INT      AUTO_INCREMENT PRIMARY KEY,
    ProductID       INT      NOT NULL,
    CurrentQuantity INT,
    Threshold       INT,
    AlertTime       DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);


-- ============================================================
-- SECTION 2: SCHEMA ALTERATIONS
-- ============================================================

-- ADD a discount column to Products
ALTER TABLE Products ADD COLUMN DiscountPct DECIMAL(5,2) DEFAULT 0.00;

-- ADD a city field to Suppliers
ALTER TABLE Suppliers ADD COLUMN City VARCHAR(100) DEFAULT NULL;

-- CHANGE data type — widen the Name column in Suppliers
ALTER TABLE Suppliers MODIFY COLUMN Name VARCHAR(200) NOT NULL;

-- DROP a column we no longer need
ALTER TABLE Suppliers DROP COLUMN City;

-- CHANGE column name — rename DiscountPct to Discount for brevity
ALTER TABLE Products CHANGE DiscountPct Discount DECIMAL(5,2) DEFAULT 0.00;


-- ============================================================
-- SECTION 3: SAMPLE DATA
-- ============================================================

INSERT INTO Categories (CategoryName, Description) VALUES
('Electronics',  'Gadgets, devices and accessories'),
('Groceries',    'Daily food and household essentials'),
('Clothing',     'Apparel and fashion items'),
('Stationery',   'Office and school supplies'),
('Furniture',    'Home and office furniture');

INSERT INTO Suppliers (Name, Contact, Email) VALUES
('TechSource Pvt Ltd',  '9876543210', 'techsource@mail.com'),
('GreenFarm Foods',     '9123456780', 'greenfarm@mail.com'),
('FashionHub',          '9000011122', 'fashionhub@mail.com'),
('OfficeWorld',         '9988776655', 'officeworld@mail.com');

INSERT INTO Products (Name, Price, CategoryID, SupplierID, SKU) VALUES
('Wireless Earbuds',        1499.00, 1, 1, 'ELEC-001'),
('Bluetooth Speaker',       2499.00, 1, 1, 'ELEC-002'),
('Basmati Rice 5kg',         350.00, 2, 2, 'GROC-001'),
('Refined Sunflower Oil 1L', 180.00, 2, 2, 'GROC-002'),
('Men\'s Casual T-Shirt',    499.00, 3, 3, 'CLTH-001'),
('Women\'s Kurti',           799.00, 3, 3, 'CLTH-002'),
('A4 Notebook 200 Pages',     85.00, 4, 4, 'STAT-001'),
('Ballpoint Pen Pack of 10',  60.00, 4, 4, 'STAT-002'),
('Ergonomic Office Chair',  7999.00, 5, NULL, 'FURN-001'),
('Study Table',             5499.00, 5, NULL, 'FURN-002');

INSERT INTO Inventory (ProductID, Quantity, Threshold) VALUES
(1,  45,  10),
(2,   8,  10),   -- below threshold
(3, 120,  20),
(4, 200,  30),
(5,  60,  15),
(6,   5,  10),   -- below threshold
(7, 300,  50),
(8, 400,  50),
(9,   3,   5),   -- below threshold
(10,  12,  10);

INSERT INTO Customers (Name, Phone, Email, LoyaltyPoints) VALUES
('Arjun Sharma', '9876501234', 'arjun@mail.com',  120),
('Priya Menon',  '9123409876', 'priya@mail.com',  250),
('Ravi Kumar',   '9000099999', 'ravi@mail.com',    80),
('Sneha Reddy',  '9988700011', 'sneha@mail.com',    0),
('Karthik Nair', '9345612345',  NULL,              50);

INSERT INTO Transactions (ProductID, CustomerID, Quantity, AmountPaid, TransactionDate) VALUES
(1, 1, 2, 2998.00, '2025-05-01 10:30:00'),
(3, 2, 5, 1750.00, '2025-05-03 14:00:00'),
(5, 3, 1,  499.00, '2025-05-05 09:15:00'),
(2, 1, 1, 2499.00, '2025-05-08 11:00:00'),
(7, 4,10,  850.00, '2025-05-10 16:45:00'),
(1, 5, 1, 1499.00, '2025-05-12 13:30:00'),
(4, 2, 3,  540.00, '2025-05-15 10:00:00'),
(6, 3, 2, 1598.00, '2025-05-18 17:00:00'),
(3, 1, 2,  700.00, '2025-04-20 08:00:00'),
(8, 4, 5,  300.00, '2025-04-28 12:00:00');


-- ============================================================
-- SECTION 4: JOINS AND QUERIES
-- ============================================================

-- INNER JOIN: Products that have an inventory record (matched rows only)
SELECT
    p.ProductID,
    p.Name        AS ProductName,
    p.Price,
    i.Quantity    AS StockQty,
    i.Threshold   AS ReorderAt
FROM Products p
INNER JOIN Inventory i ON p.ProductID = i.ProductID;


-- LEFT JOIN: All products, even ones with no inventory record yet
SELECT
    p.ProductID,
    p.Name                             AS ProductName,
    p.Price,
    IFNULL(i.Quantity,  'No Record')   AS StockQty,
    IFNULL(i.Threshold, 'N/A')         AS ReorderAt
FROM Products p
LEFT JOIN Inventory i ON p.ProductID = i.ProductID;


-- Low-stock alert: Products where current stock is below reorder threshold
SELECT
    p.ProductID,
    p.Name                           AS ProductName,
    i.Quantity                       AS CurrentStock,
    i.Threshold                      AS ReorderLevel,
    (i.Threshold - i.Quantity)       AS ShortfallBy
FROM Products p
INNER JOIN Inventory i ON p.ProductID = i.ProductID
WHERE i.Quantity < i.Threshold
ORDER BY ShortfallBy DESC;


-- Top 5 best-selling products by total units sold
SELECT
    p.ProductID,
    p.Name              AS ProductName,
    SUM(t.Quantity)     AS TotalUnitsSold
FROM Products p
INNER JOIN Transactions t ON p.ProductID = t.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalUnitsSold DESC
LIMIT 5;


-- RIGHT JOIN: Suppliers who have no products listed under them
SELECT
    s.SupplierID,
    s.Name    AS SupplierName,
    s.Email,
    p.ProductID,
    p.Name    AS ProductName
FROM Products p
RIGHT JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.ProductID IS NULL;


-- FULL OUTER JOIN workaround using UNION:
-- Rows in Products with no Inventory match, plus
-- rows in Inventory with no Products match
SELECT
    p.ProductID,
    p.Name      AS ProductName,
    i.InventoryID,
    i.Quantity
FROM Products p
LEFT JOIN Inventory i ON p.ProductID = i.ProductID
WHERE i.InventoryID IS NULL

UNION

SELECT
    p.ProductID,
    p.Name      AS ProductName,
    i.InventoryID,
    i.Quantity
FROM Products p
RIGHT JOIN Inventory i ON p.ProductID = i.ProductID
WHERE p.ProductID IS NULL;


-- Total revenue per product (Price × Quantity across all Transactions)
SELECT
    p.ProductID,
    p.Name              AS ProductName,
    SUM(t.Quantity)     AS TotalQtySold,
    SUM(t.AmountPaid)   AS TotalRevenue
FROM Products p
INNER JOIN Transactions t ON p.ProductID = t.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalRevenue DESC;


-- Products that have NEVER been sold in the last 30 days
SELECT
    p.ProductID,
    p.Name   AS ProductName,
    p.Price
FROM Products p
WHERE p.ProductID NOT IN (
    SELECT DISTINCT ProductID
    FROM Transactions
    WHERE TransactionDate >= DATE_SUB(NOW(), INTERVAL 30 DAY)
);


-- GROUP BY + HAVING: Categories where the average product price is above ₹100
SELECT
    c.CategoryName,
    COUNT(p.ProductID)       AS TotalProducts,
    ROUND(AVG(p.Price), 2)  AS AvgPrice
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
HAVING AVG(p.Price) > 100
ORDER BY AvgPrice DESC;


-- Subquery / Nested query: Most expensive product in each category
SELECT
    p.ProductID,
    p.Name          AS ProductName,
    p.Price,
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
)
ORDER BY p.Price DESC;


-- ============================================================
-- SECTION 5: VIEW
-- ============================================================

-- ProductStockView: one clean view showing product + category + stock info
CREATE OR REPLACE VIEW ProductStockView AS
SELECT
    p.ProductID,
    p.Name            AS ProductName,
    p.Price,
    c.CategoryName,
    IFNULL(i.Quantity,  0) AS CurrentStock,
    IFNULL(i.Threshold, 0) AS ReorderThreshold,
    CASE
        WHEN i.Quantity IS NULL       THEN 'Not Tracked'
        WHEN i.Quantity < i.Threshold THEN 'Low Stock'
        ELSE                               'In Stock'
    END AS StockStatus
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory  i ON p.ProductID  = i.ProductID;

-- Using the view:
SELECT * FROM ProductStockView;
SELECT * FROM ProductStockView WHERE StockStatus = 'Low Stock';


-- ============================================================
-- SECTION 6: FUNCTIONS
-- ============================================================

DELIMITER $$

-- How many loyalty points does a customer earn on a given spend?
-- Rule: 1 point per ₹50 spent
CREATE FUNCTION CalculateLoyaltyPoints(amount DECIMAL(10,2))
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN FLOOR(amount / 50);
END$$


-- Quick check: is a given product running low?
CREATE FUNCTION IsLowStock(p_ProductID INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE qty       INT;
    DECLARE threshold INT;

    SELECT Quantity, Threshold
    INTO   qty, threshold
    FROM   Inventory
    WHERE  ProductID = p_ProductID;

    IF qty IS NULL THEN
        RETURN 'Not Tracked';
    ELSEIF qty < threshold THEN
        RETURN 'Low Stock';
    ELSE
        RETURN 'In Stock';
    END IF;
END$$

DELIMITER ;

-- Try them out:
SELECT CalculateLoyaltyPoints(2998.00);   -- 59 points
SELECT IsLowStock(2);                      -- Low Stock
SELECT IsLowStock(1);                      -- In Stock


-- ============================================================
-- SECTION 7: STORED PROCEDURE
-- ============================================================

DELIMITER $$

-- AddProductWithInventory:
-- Adds a new product AND immediately creates its inventory
-- row with zero stock, so it's tracked from day one.
CREATE PROCEDURE AddProductWithInventory(
    IN p_Name       VARCHAR(200),
    IN p_Price      DECIMAL(10,2),
    IN p_CategoryID INT,
    IN p_SupplierID INT,
    IN p_SKU        VARCHAR(50),
    IN p_Threshold  INT
)
BEGIN
    DECLARE new_id INT;

    INSERT INTO Products (Name, Price, CategoryID, SupplierID, SKU)
    VALUES (p_Name, p_Price, p_CategoryID, p_SupplierID, p_SKU);

    SET new_id = LAST_INSERT_ID();

    INSERT INTO Inventory (ProductID, Quantity, Threshold)
    VALUES (new_id, 0, p_Threshold);

    SELECT CONCAT(
        'Product "', p_Name,
        '" added successfully with ProductID = ', new_id,
        '. Inventory initialised to 0.'
    ) AS Message;
END$$

DELIMITER ;

-- Call it:
CALL AddProductWithInventory('USB-C Hub 7-in-1', 1299.00, 1, 1, 'ELEC-003', 10);


-- ============================================================
-- SECTION 8: TRIGGERS
-- ============================================================

DELIMITER $$

-- TRIGGER 1:
-- After every purchase (INSERT into Transactions) —
-- reduce Inventory.Quantity by the sold amount, and
-- add the earned loyalty points to the customer's account.
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    -- Deduct stock
    UPDATE Inventory
    SET    Quantity    = Quantity - NEW.Quantity,
           LastUpdated = NOW()
    WHERE  ProductID   = NEW.ProductID;

    -- Reward customer (only if the transaction is tied to a customer)
    IF NEW.CustomerID IS NOT NULL THEN
        UPDATE Customers
        SET    LoyaltyPoints = LoyaltyPoints + CalculateLoyaltyPoints(NEW.AmountPaid)
        WHERE  CustomerID    = NEW.CustomerID;
    END IF;
END$$


-- TRIGGER 2:
-- After every Inventory update, if stock has dropped below
-- the reorder threshold, log a warning in StockAlerts.
-- (Using a log table instead of SIGNAL so the update itself
--  isn't rolled back — change to SIGNAL if you want hard stops.)
CREATE TRIGGER trg_check_stock_after_update
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    IF NEW.Quantity < NEW.Threshold THEN
        INSERT INTO StockAlerts (ProductID, CurrentQuantity, Threshold)
        VALUES (NEW.ProductID, NEW.Quantity, NEW.Threshold);
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SECTION 9: QUICK VERIFICATION QUERIES
-- ============================================================

-- See all stock alerts logged so far
SELECT
    sa.AlertID,
    p.Name    AS ProductName,
    sa.CurrentQuantity,
    sa.Threshold,
    sa.AlertTime
FROM StockAlerts sa
INNER JOIN Products p ON sa.ProductID = p.ProductID
ORDER BY sa.AlertTime DESC;

-- Full product view with live stock status
SELECT * FROM ProductStockView ORDER BY StockStatus, ProductName;

-- Customer loyalty summary
SELECT
    CustomerID,
    Name,
    Phone,
    LoyaltyPoints
FROM Customers
ORDER BY LoyaltyPoints DESC;


-- ============================================================
-- END OF SCRIPT
-- ============================================================

-- ============================================
-- LAB 6: E-COMMERCE PLATFORM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_6;
CREATE DATABASE Lab_6;
USE Lab_6;

-- ============================================
-- a) SCHEMA DESIGN
-- ============================================

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    loyalty_status ENUM('Bronze', 'Silver', 'Gold', 'None') DEFAULT 'None',
    total_spending DECIMAL(12,2) DEFAULT 0
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE DEFAULT (CURRENT_DATE),
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Confirmed', 'Delivered') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE OrderItems (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT CHECK (quantity > 0),
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT (CURRENT_DATE),
    method ENUM('Card', 'MobileMoney', 'Cash'),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- ============================================
-- b) SAMPLE DATA
-- ============================================

INSERT INTO Customers (name, email, loyalty_status) VALUES
('John Doe', 'john@example.com', 'Gold'),
('Sarah K', 'sarah@example.com', 'Silver'),
('Peter A', 'peter@example.com', 'Bronze'),
('Mary N', 'mary@example.com', 'None');

INSERT INTO Products (name, price, stock_quantity) VALUES
('Laptop', 1500000, 20),
('Smartphone', 800000, 50),
('Headphones', 150000, 100),
('USB Cable', 5000, 200);

INSERT INTO Orders (customer_id, total_amount, status) VALUES
(1, 0, 'Pending'),
(2, 0, 'Pending');

INSERT INTO OrderItems (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1500000),
(1, 3, 2, 150000),
(2, 2, 1, 800000);

INSERT INTO Payments (order_id, amount, method) VALUES
(1, 1800000, 'Card'),
(2, 800000, 'MobileMoney');

-- ============================================
-- c) TRIGGER: Auto Reduce Stock on OrderItems Insert
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_reduce_stock
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

DELIMITER ;

-- ============================================
-- d) STORED PROCEDURE: Apply Dynamic Discount
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_apply_discount(IN cust_id INT, IN order_amt DECIMAL(10,2))
BEGIN
    DECLARE discount DECIMAL(5,2);
    DECLARE loyalty VARCHAR(20);

    SELECT loyalty_status INTO loyalty
    FROM Customers WHERE customer_id = cust_id;

    SET discount = CASE loyalty
        WHEN 'Gold' THEN 0.15
        WHEN 'Silver' THEN 0.10
        WHEN 'Bronze' THEN 0.05
        ELSE 0.00
    END;

    SELECT order_amt * (1 - discount) AS final_amount;
END$$

DELIMITER ;

-- ============================================
-- e) VIEW: Customer Details with Recent Purchases & Total Spending
-- ============================================

CREATE VIEW vw_customer_summary AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.loyalty_status,
    MAX(o.order_date) AS last_purchase_date,
    SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.email, c.loyalty_status;

-- ============================================
-- f) INDEXING FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_order_date ON Orders(order_date);
CREATE INDEX idx_customer_id ON Orders(customer_id);
CREATE INDEX idx_product_name ON Products(name);

-- ============================================
-- TESTING
-- ============================================

-- Test trigger: Insert new order item and reduce stock
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price)
VALUES (2, 4, 5, 5000);

-- Check updated stock
SELECT * FROM Products;

-- Test stored procedure for discount
CALL sp_apply_discount(1, 2000000);

-- View customer summary
SELECT * FROM vw_customer_summary;

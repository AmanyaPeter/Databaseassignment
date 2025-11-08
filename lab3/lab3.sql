-- ============================================
-- LAB 3: RETAIL STORE INVENTORY SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_3;
CREATE DATABASE Lab_3;
USE Lab_3;

-- ============================================
-- a) SCHEMA DESIGN
-- ============================================

CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    stock_quantity INT DEFAULT 0 CHECK (stock_quantity >= 0),
    category_id INT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    order_date DATE DEFAULT (CURRENT_DATE),
    status ENUM('Placed','Delivered') DEFAULT 'Placed',
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================
-- b) SAMPLE DATA
-- ============================================

INSERT INTO Categories (category_name, description)
VALUES ('Electronics', 'Electronic items'),
       ('Groceries', 'Daily essentials');

INSERT INTO Suppliers (name, contact, email, phone)
VALUES ('TechWorld', 'Mr. Musa', 'musa@techworld.com', '+256700111222'),
       ('FreshMart', 'Ms. Joy', 'joy@freshmart.com', '+256700333444');

INSERT INTO Products (name, description, unit_price, stock_quantity, category_id)
VALUES ('Smartphone', 'Android phone', 800000, 50, 1),
       ('Television', '42-inch LED TV', 1200000, 30, 1),
       ('Rice', '5kg Bag', 25000, 100, 2);

INSERT INTO Orders (product_id, supplier_id, quantity, status)
VALUES (1, 1, 5, 'Placed'),
       (3, 2, 10, 'Delivered');

-- ============================================
-- c) TRIGGER: UPDATE STOCK AFTER ORDER
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_update_stock_after_order
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    UPDATE Products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

DELIMITER ;

-- ============================================
-- d) VIEW: TOTAL INVENTORY PER SUPPLIER AND CATEGORY
-- ============================================

CREATE VIEW vw_inventory_by_supplier AS
SELECT s.name AS supplier, 
       c.category_name AS category,
       SUM(p.stock_quantity) AS total_stock
FROM Suppliers s
JOIN Orders o ON s.supplier_id = o.supplier_id
JOIN Products p ON o.product_id = p.product_id
JOIN Categories c ON p.category_id = c.category_id
GROUP BY s.name, c.category_name;

-- ============================================
-- e) SQL QUERIES
-- ============================================

-- (i) Low-stock products (below 20)
SELECT name AS product, stock_quantity
FROM Products
WHERE stock_quantity < 20;

-- (ii) Top-selling categories
SELECT c.category_name, SUM(o.quantity) AS total_sold
FROM Orders o
JOIN Products p ON o.product_id = p.product_id
JOIN Categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sold DESC;

-- (iii) Suppliers providing more than 5 products
SELECT s.name AS supplier, COUNT(p.product_id) AS total_products
FROM Suppliers s
JOIN Orders o ON s.supplier_id = o.supplier_id
JOIN Products p ON o.product_id = p.product_id
GROUP BY s.supplier_id
HAVING COUNT(p.product_id) > 5;

-- ============================================
-- TEST VIEW
-- ============================================

SELECT * FROM vw_inventory_by_supplier;

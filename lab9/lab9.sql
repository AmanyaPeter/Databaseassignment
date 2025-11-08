-- ============================================
-- LAB 9: HEALTH INSURANCE CLAIMS
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_9;
CREATE DATABASE Lab_9;
USE Lab_9;

-- ============================================
-- a) SCHEMA DESIGN
-- ============================================

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50)
);

CREATE TABLE Policies (
    policy_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    policy_number VARCHAR(50) UNIQUE NOT NULL,
    coverage_amount DECIMAL(12,2) NOT NULL CHECK (coverage_amount > 0),
    premium DECIMAL(12,2) NOT NULL CHECK (premium > 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Hospitals (
    hospital_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    contact VARCHAR(50)
);

CREATE TABLE Claims (
    claim_id INT PRIMARY KEY AUTO_INCREMENT,
    policy_id INT NOT NULL,
    hospital_id INT NOT NULL,
    claim_amount DECIMAL(12,2) NOT NULL CHECK (claim_amount > 0),
    claim_date DATE DEFAULT (CURRENT_DATE()),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    FOREIGN KEY (policy_id) REFERENCES Policies(policy_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES Hospitals(hospital_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================
-- b) SAMPLE DATA
-- ============================================

INSERT INTO Customers (name, contact) VALUES
('John Doe', '+256701234567'),
('Sarah K', '+256702234568'),
('Peter A', '+256703234569');

INSERT INTO Policies (customer_id, policy_number, coverage_amount, premium) VALUES
(1, 'POL1001', 5000000.00, 200000.00),
(2, 'POL1002', 3000000.00, 150000.00),
(3, 'POL1003', 7000000.00, 250000.00);

INSERT INTO Hospitals (name, location, contact) VALUES
('Kampala General Hospital', 'Kampala', '+256701112233'),
('Mbarara Hospital', 'Mbarara', '+256702223344');

INSERT INTO Claims (policy_id, hospital_id, claim_amount, status) VALUES
(1, 1, 2000000.00, 'Pending'),
(2, 1, 1000000.00, 'Approved'),
(3, 2, 3000000.00, 'Pending');

-- ============================================
-- c) VIEW: Pending Claims by Hospital
-- ============================================

CREATE VIEW vw_pending_claims AS
SELECT h.name AS hospital,
       COUNT(c.claim_id) AS pending_claims,
       SUM(c.claim_amount) AS total_claim_amount
FROM Claims c
JOIN Hospitals h ON c.hospital_id = h.hospital_id
WHERE c.status = 'Pending'
GROUP BY h.name;

-- ============================================
-- d) FUNCTION: Total Reimbursed per Customer
-- ============================================

DELIMITER $$

CREATE FUNCTION fn_total_reimbursed(cust_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(15,2);

    SELECT SUM(c.claim_amount) INTO total
    FROM Claims c
    JOIN Policies p ON c.policy_id = p.policy_id
    WHERE p.customer_id = cust_id AND c.status = 'Approved';

    RETURN IFNULL(total, 0.00);
END$$

DELIMITER ;

-- ============================================
-- e) INDEXES
-- ============================================

CREATE INDEX idx_policy_number ON Policies(policy_number);
CREATE INDEX idx_claim_status ON Claims(status);

-- ============================================
-- f) TESTING
-- ============================================

-- View pending claims
SELECT * FROM vw_pending_claims;

-- Test total reimbursed function
SELECT customer_id, name, fn_total_reimbursed(customer_id) AS total_reimbursed
FROM Customers;

-- Test concurrent updates (example)
START TRANSACTION;
UPDATE Claims SET status = 'Approved' WHERE claim_id = 1;
-- In another session, attempt conflicting update and see isolation effect
ROLLBACK;

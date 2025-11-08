-- ============================================
-- LAB 5: BANKING TRANSACTION SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS BankingSystem;
CREATE DATABASE BankingSystem;
USE BankingSystem;

-- ============================================
-- SCHEMA DESIGN WITH REFERENTIAL INTEGRITY
-- ============================================

-- Table: Customers
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) NOT NULL,
    address VARCHAR(200),
    date_of_birth DATE NOT NULL,
    registration_date DATE DEFAULT (CURRENT_DATE),
    status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Table: Accounts
CREATE TABLE Accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type ENUM('Savings', 'Current', 'Fixed Deposit') NOT NULL,
    balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (balance >= 0),
    opening_date DATE DEFAULT (CURRENT_DATE),
    status ENUM('Active', 'Closed', 'Frozen') DEFAULT 'Active',
    interest_rate DECIMAL(5, 2) DEFAULT 0.00,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    INDEX idx_customer (customer_id),
    INDEX idx_account_number (account_number),
    INDEX idx_status (status)
);

-- Table: Transactions
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    transaction_type ENUM('Deposit', 'Withdrawal', 'Transfer_Out', 'Transfer_In') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(200),
    balance_after DECIMAL(15, 2),
    reference_number VARCHAR(50) UNIQUE,
    related_account_id INT,
    status ENUM('Pending', 'Completed', 'Failed', 'Reversed') DEFAULT 'Completed',
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (related_account_id) REFERENCES Accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_account (account_id),
    INDEX idx_date (transaction_date),
    INDEX idx_type (transaction_type),
    INDEX idx_reference (reference_number)
);

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert Customers
INSERT INTO Customers (first_name, last_name, email, phone, address, date_of_birth) VALUES
('John', 'Mugisha', 'john.mugisha@email.com', '+256701234567', 'Kampala, Uganda', '1985-03-15'),
('Sarah', 'Nalule', 'sarah.nalule@email.com', '+256702234568', 'Entebbe, Uganda', '1990-07-22'),
('David', 'Okello', 'david.okello@email.com', '+256703234569', 'Mbarara, Uganda', '1988-11-10'),
('Grace', 'Namukasa', 'grace.namukasa@email.com', '+256704234570', 'Jinja, Uganda', '1992-05-18'),
('Peter', 'Opio', 'peter.opio@email.com', '+256705234571', 'Gulu, Uganda', '1987-09-25'),
('Mary', 'Akello', 'mary.akello@email.com', '+256706234572', 'Mbale, Uganda', '1991-02-14'),
('James', 'Ssemakula', 'james.ssemakula@email.com', '+256707234573', 'Kampala, Uganda', '1989-12-08'),
('Rebecca', 'Atim', 'rebecca.atim@email.com', '+256708234574', 'Fort Portal, Uganda', '1993-06-30');

-- Insert Accounts
INSERT INTO Accounts (customer_id, account_number, account_type, balance, interest_rate) VALUES
(1, 'ACC1001234567', 'Savings', 5000000.00, 5.00),
(1, 'ACC1001234568', 'Current', 2000000.00, 0.00),
(2, 'ACC1002234567', 'Savings', 8000000.00, 5.00),
(3, 'ACC1003234567', 'Current', 3500000.00, 0.00),
(4, 'ACC1004234567', 'Savings', 6000000.00, 5.00),
(4, 'ACC1004234568', 'Fixed Deposit', 10000000.00, 8.00),
(5, 'ACC1005234567', 'Savings', 4500000.00, 5.00),
(6, 'ACC1006234567', 'Current', 7000000.00, 0.00),
(7, 'ACC1007234567', 'Savings', 5500000.00, 5.00),
(8, 'ACC1008234567', 'Savings', 3000000.00, 5.00);

-- Insert Sample Transactions
INSERT INTO Transactions (account_id, transaction_type, amount, description, balance_after, reference_number) VALUES
(1, 'Deposit', 1000000.00, 'Initial Deposit', 1000000.00, 'TXN20240101001'),
(1, 'Deposit', 4000000.00, 'Salary Deposit', 5000000.00, 'TXN20240115001'),
(2, 'Deposit', 2000000.00, 'Business Income', 2000000.00, 'TXN20240120001'),
(3, 'Deposit', 8000000.00, 'Initial Deposit', 8000000.00, 'TXN20240201001');

-- ============================================
-- c) TRIGGER: Prevent Withdrawals Exceeding Balance
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_check_withdrawal_balance
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15, 2);
    
    -- Get current account balance
    SELECT balance INTO current_balance
    FROM Accounts
    WHERE account_id = NEW.account_id;
    
    -- Check if withdrawal or transfer out
    IF NEW.transaction_type IN ('Withdrawal', 'Transfer_Out') THEN
        IF NEW.amount > current_balance THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient funds: Withdrawal amount exceeds current balance';
        END IF;
    END IF;
    
    -- Calculate balance after transaction
    IF NEW.transaction_type IN ('Deposit', 'Transfer_In') THEN
        SET NEW.balance_after = current_balance + NEW.amount;
    ELSE
        SET NEW.balance_after = current_balance - NEW.amount;
    END IF;
END$$

-- Trigger to update account balance after transaction
CREATE TRIGGER trg_update_account_balance
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type IN ('Deposit', 'Transfer_In') THEN
        UPDATE Accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;
    ELSEIF NEW.transaction_type IN ('Withdrawal', 'Transfer_Out') THEN
        UPDATE Accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- d) FUNCTION: Return Current Account Balance
-- ============================================

DELIMITER $$

CREATE FUNCTION fn_get_account_balance(acc_id INT)
RETURNS DECIMAL(15, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE acc_balance DECIMAL(15, 2);
    
    SELECT balance INTO acc_balance
    FROM Accounts
    WHERE account_id = acc_id;
    
    RETURN IFNULL(acc_balance, 0.00);
END$$

DELIMITER ;

-- Test the function
SELECT account_number, fn_get_account_balance(account_id) AS current_balance
FROM Accounts;

-- ============================================
-- d) STORED PROCEDURE: Daily Total Transactions Per Customer
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_daily_transactions_by_customer(IN target_date DATE)
BEGIN
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        a.account_number,
        COUNT(t.transaction_id) AS transaction_count,
        SUM(CASE WHEN t.transaction_type IN ('Deposit', 'Transfer_In') 
            THEN t.amount ELSE 0 END) AS total_credits,
        SUM(CASE WHEN t.transaction_type IN ('Withdrawal', 'Transfer_Out') 
            THEN t.amount ELSE 0 END) AS total_debits,
        (SUM(CASE WHEN t.transaction_type IN ('Deposit', 'Transfer_In') 
            THEN t.amount ELSE 0 END) -
         SUM(CASE WHEN t.transaction_type IN ('Withdrawal', 'Transfer_Out') 
            THEN t.amount ELSE 0 END)) AS net_change
    FROM Customers c
    JOIN Accounts a ON c.customer_id = a.customer_id
    LEFT JOIN Transactions t ON a.account_id = t.account_id
        AND DATE(t.transaction_date) = target_date
    GROUP BY c.customer_id, c.first_name, c.last_name, a.account_number
    HAVING transaction_count > 0
    ORDER BY customer_name, account_number;
END$$

DELIMITER ;

-- Test the procedure
CALL sp_daily_transactions_by_customer('2024-01-01');

-- ============================================
-- b) TRANSACTION MANAGEMENT: Fund Transfer with COMMIT/ROLLBACK
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_fund_transfer(
    IN from_account INT,
    IN to_account INT,
    IN transfer_amount DECIMAL(15, 2),
    IN transfer_desc VARCHAR(200),
    OUT result_message VARCHAR(200)
)
BEGIN
    DECLARE from_balance DECIMAL(15, 2);
    DECLARE ref_number VARCHAR(50);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET result_message = 'Transfer failed: Transaction rolled back due to error';
    END;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check source account balance
    SELECT balance INTO from_balance
    FROM Accounts
    WHERE account_id = from_account AND status = 'Active';
    
    IF from_balance IS NULL THEN
        SET result_message = 'Transfer failed: Source account not found or inactive';
        ROLLBACK;
    ELSEIF from_balance < transfer_amount THEN
        SET result_message = 'Transfer failed: Insufficient funds';
        ROLLBACK;
    ELSE
        -- Generate reference number
        SET ref_number = CONCAT('TRF', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
        
        -- Debit from source account
        INSERT INTO Transactions (account_id, transaction_type, amount, description, reference_number, related_account_id)
        VALUES (from_account, 'Transfer_Out', transfer_amount, transfer_desc, ref_number, to_account);
        
        -- Credit to destination account
        INSERT INTO Transactions (account_id, transaction_type, amount, description, reference_number, related_account_id)
        VALUES (to_account, 'Transfer_In', transfer_amount, transfer_desc, ref_number, from_account);
        
        -- Commit transaction
        COMMIT;
        SET result_message = CONCAT('Transfer successful: Reference ', ref_number);
    END IF;
END$$

DELIMITER ;

-- Test fund transfer
SET @result = '';
CALL sp_fund_transfer(1, 3, 500000.00, 'Payment for services', @result);
SELECT @result AS transfer_result;

-- Verify balances
SELECT account_number, balance FROM Accounts WHERE account_id IN (1, 3);

-- ============================================
-- e) ISOLATION LEVELS DEMONSTRATION
-- ============================================

-- Set isolation level
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Demonstrate concurrent transactions
-- Session 1:
START TRANSACTION;
UPDATE Accounts SET balance = balance - 100000 WHERE account_id = 1;
-- Don't commit yet

-- Session 2 (in another connection):
-- With READ COMMITTED, this will wait for Session 1 to commit
SELECT balance FROM Accounts WHERE account_id = 1;

-- Session 1:
COMMIT;

-- Now Session 2 will see the updated balance

-- ============================================
-- ADDITIONAL QUERIES AND VIEWS
-- ============================================

-- View: Customer Account Summary
CREATE OR REPLACE VIEW vw_customer_account_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.phone,
    COUNT(a.account_id) AS total_accounts,
    SUM(a.balance) AS total_balance,
    MAX(a.opening_date) AS latest_account_date
FROM Customers c
LEFT JOIN Accounts a ON c.customer_id = a.customer_id
WHERE c.status = 'Active' AND a.status = 'Active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.phone;

-- Query the view
SELECT * FROM vw_customer_account_summary
ORDER BY total_balance DESC;

-- View: Transaction History with Details
CREATE OR REPLACE VIEW vw_transaction_history AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    a.account_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    t.transaction_type,
    t.amount,
    t.balance_after,
    t.description,
    t.reference_number,
    t.status
FROM Transactions t
JOIN Accounts a ON t.account_id = a.account_id
JOIN Customers c ON a.customer_id = c.customer_id
ORDER BY t.transaction_date DESC;

-- Find accounts with high transaction volumes
SELECT 
    a.account_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_transaction_value
FROM Accounts a
JOIN Customers c ON a.customer_id = c.customer_id
LEFT JOIN Transactions t ON a.account_id = t.account_id
    AND t.transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY a.account_number, c.first_name, c.last_name
HAVING transaction_count > 0
ORDER BY transaction_count DESC;

-- Monthly transaction summary
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount
FROM Transactions
WHERE transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m'), transaction_type
ORDER BY month DESC, transaction_type;

-- Test insufficient funds trigger
-- This should fail
INSERT INTO Transactions (account_id, transaction_type, amount, description)
VALUES (1, 'Withdrawal', 999999999.00, 'Test withdrawal - should fail');
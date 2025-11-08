-- ============================================
-- LAB 5: BANKING TRANSACTION SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS BankingSystem_lab_5;
CREATE DATABASE BankingSystem_lab_5;
USE BankingSystem_lab_5;

-- ============================================
-- a) EER MODEL IMPLEMENTATION: SCHEMA DESIGN
-- ============================================

-- Table: Customers
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    date_of_birth DATE,
    status ENUM('Active','Inactive') DEFAULT 'Active'
);

-- Table: Accounts
CREATE TABLE Accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Table: Transactions
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    transaction_type ENUM('Deposit','Withdrawal','Transfer_Out','Transfer_In') NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    reference_number VARCHAR(50) UNIQUE,
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO Customers (first_name, last_name, email, phone, date_of_birth)
VALUES ('John','Mugisha','john.mugisha@email.com','+256700000001','1990-05-10'),
       ('Sarah','Nalule','sarah.nalule@email.com','+256700000002','1992-07-15');

INSERT INTO Accounts (customer_id, account_number, balance)
VALUES (1, 'ACC1001', 500000.00),
       (2, 'ACC1002', 300000.00);

-- ============================================
-- c) TRIGGER: Prevent Withdrawals Exceeding Balance
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_prevent_overdraw
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(15,2);
    SELECT balance INTO current_balance FROM Accounts WHERE account_id = NEW.account_id;
    
    IF NEW.transaction_type IN ('Withdrawal','Transfer_Out') AND NEW.amount > current_balance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
END$$

-- Trigger to update balance after transaction
CREATE TRIGGER trg_update_balance
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type IN ('Deposit','Transfer_In') THEN
        UPDATE Accounts SET balance = balance + NEW.amount WHERE account_id = NEW.account_id;
    ELSEIF NEW.transaction_type IN ('Withdrawal','Transfer_Out') THEN
        UPDATE Accounts SET balance = balance - NEW.amount WHERE account_id = NEW.account_id;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- d) FUNCTION: Return Current Account Balance
-- ============================================

DELIMITER $$

CREATE FUNCTION fn_get_balance(acc_id INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE bal DECIMAL(15,2);
    SELECT balance INTO bal FROM Accounts WHERE account_id = acc_id;
    RETURN IFNULL(bal,0.00);
END$$

DELIMITER ;

-- ============================================
-- d) PROCEDURE: Daily Total Transactions per Customer
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_daily_transactions(IN trans_date DATE)
BEGIN
    SELECT c.customer_id,
           CONCAT(c.first_name,' ',c.last_name) AS customer_name,
           COUNT(t.transaction_id) AS total_transactions,
           SUM(t.amount) AS total_amount
    FROM Customers c
    JOIN Accounts a ON c.customer_id = a.customer_id
    JOIN Transactions t ON a.account_id = t.account_id
    WHERE DATE(t.transaction_date) = trans_date
    GROUP BY c.customer_id, customer_name;
END$$

DELIMITER ;

-- ============================================
-- b) TRANSACTION MANAGEMENT: Fund Transfer
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_transfer_funds(
    IN from_acc INT,
    IN to_acc INT,
    IN amt DECIMAL(15,2)
)
BEGIN
    DECLARE from_bal DECIMAL(15,2);
    DECLARE ref_no VARCHAR(50);

    START TRANSACTION;
    
    SELECT balance INTO from_bal FROM Accounts WHERE account_id = from_acc FOR UPDATE;
    
    IF from_bal < amt THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer failed: Insufficient funds';
    ELSE
        SET ref_no = CONCAT('TRF', UNIX_TIMESTAMP());
        
        INSERT INTO Transactions(account_id, transaction_type, amount, reference_number)
        VALUES (from_acc,'Transfer_Out',amt,ref_no),
               (to_acc,'Transfer_In',amt,ref_no);
               
        COMMIT;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- e) ISOLATION LEVEL DEMONSTRATION
-- ============================================

-- Example: read committed level
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- In one session:
-- START TRANSACTION;
-- UPDATE Accounts SET balance = balance - 10000 WHERE account_id = 1;
-- (Don’t COMMIT yet)

-- In another session:
-- SELECT balance FROM Accounts WHERE account_id = 1;  -- waits or reads committed version

-- ============================================
-- TESTING SECTION
-- ============================================

-- Deposit
INSERT INTO Transactions (account_id, transaction_type, amount, reference_number)
VALUES (1, 'Deposit', 100000.00, 'TXN001');

-- Withdrawal (valid)
INSERT INTO Transactions (account_id, transaction_type, amount, reference_number)
VALUES (2, 'Withdrawal', 50000.00, 'TXN002');

-- Withdrawal (should fail)
-- INSERT INTO Transactions (account_id, transaction_type, amount, reference_number)
-- VALUES (2, 'Withdrawal', 999999.00, 'TXN003');


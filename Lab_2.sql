-- ============================================
-- LAB 2: EMPLOYEE MANAGEMENT SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS EmployeeManagement;
CREATE DATABASE EmployeeManagement;
USE EmployeeManagement;

-- ============================================
-- SCHEMA DESIGN WITH CONSTRAINTS
-- ============================================

-- Table: Departments
CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(100),
    manager_id INT,
    created_date DATE DEFAULT (CURRENT_DATE)
);

-- Table: Employees
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    hire_date DATE NOT NULL,
    department_id INT,
    job_title VARCHAR(50),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_department (department_id),
    INDEX idx_hire_date (hire_date)
);

-- Table: Salaries
CREATE TABLE Salaries (
    salary_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    salary_amount DECIMAL(10, 2) NOT NULL CHECK (salary_amount > 0),
    effective_date DATE NOT NULL,
    end_date DATE,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_employee (employee_id),
    INDEX idx_effective_date (effective_date)
);

-- Table: SalaryAudit (for trigger logging)
CREATE TABLE SalaryAudit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    change_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100),
    action_type ENUM('INSERT', 'UPDATE', 'DELETE'),
    INDEX idx_employee_audit (employee_id),
    INDEX idx_change_date (change_date)
);

-- Add manager foreign key to Departments after Employees table exists
ALTER TABLE Departments
ADD FOREIGN KEY (manager_id) REFERENCES Employees(employee_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL;

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert Departments
INSERT INTO Departments (department_name, location) VALUES
('Information Technology', 'Building A'),
('Human Resources', 'Building B'),
('Finance', 'Building C'),
('Operations', 'Building D'),
('Marketing', 'Building E');

-- Insert Employees
INSERT INTO Employees (first_name, last_name, email, phone, hire_date, department_id, job_title) VALUES
('Joseph', 'Kamau', 'j.kamau@company.com', '+256701111001', '2020-01-15', 1, 'IT Manager'),
('Grace', 'Nalule', 'g.nalule@company.com', '+256701111002', '2020-03-20', 1, 'Database Administrator'),
('Robert', 'Okwir', 'r.okwir@company.com', '+256701111003', '2021-05-10', 1, 'Software Developer'),
('Susan', 'Namatovu', 's.namatovu@company.com', '+256701111004', '2019-08-01', 2, 'HR Manager'),
('Patrick', 'Ochieng', 'p.ochieng@company.com', '+256701111005', '2021-11-15', 2, 'HR Officer'),
('Alice', 'Kemigisha', 'a.kemigisha@company.com', '+256701111006', '2018-02-20', 3, 'Finance Manager'),
('David', 'Musoke', 'd.musoke@company.com', '+256701111007', '2020-07-10', 3, 'Accountant'),
('Ruth', 'Apio', 'r.apio@company.com', '+256701111008', '2022-01-05', 3, 'Financial Analyst'),
('Mark', 'Tumusiime', 'm.tumusiime@company.com', '+256701111009', '2019-06-12', 4, 'Operations Manager'),
('Jane', 'Nabirye', 'j.nabirye@company.com', '+256701111010', '2021-09-18', 5, 'Marketing Manager'),
('Andrew', 'Odongo', 'a.odongo@company.com', '+256701111011', '2023-03-01', 1, 'Junior Developer'),
('Linda', 'Atim', 'l.atim@company.com', '+256701111012', '2022-08-15', 5, 'Marketing Officer');

-- Update department managers
UPDATE Departments SET manager_id = 1 WHERE department_id = 1;
UPDATE Departments SET manager_id = 4 WHERE department_id = 2;
UPDATE Departments SET manager_id = 6 WHERE department_id = 3;
UPDATE Departments SET manager_id = 9 WHERE department_id = 4;
UPDATE Departments SET manager_id = 10 WHERE department_id = 5;

-- Insert Current Salaries
INSERT INTO Salaries (employee_id, salary_amount, effective_date) VALUES
(1, 8500000.00, '2020-01-15'),
(2, 6500000.00, '2020-03-20'),
(3, 5000000.00, '2021-05-10'),
(4, 8000000.00, '2019-08-01'),
(5, 4500000.00, '2021-11-15'),
(6, 9000000.00, '2018-02-20'),
(7, 5500000.00, '2020-07-10'),
(8, 4800000.00, '2022-01-05'),
(9, 7500000.00, '2019-06-12'),
(10, 7000000.00, '2021-09-18'),
(11, 3500000.00, '2023-03-01'),
(12, 4200000.00, '2022-08-15');

-- ============================================
-- c) TRIGGERS FOR SALARY AUDIT LOGGING
-- ============================================

DELIMITER $$

-- Trigger: After INSERT on Salaries
CREATE TRIGGER trg_salary_insert_audit
AFTER INSERT ON Salaries
FOR EACH ROW
BEGIN
    INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
    VALUES (NEW.employee_id, NULL, NEW.salary_amount, USER(), 'INSERT');
END$$

-- Trigger: After UPDATE on Salaries
CREATE TRIGGER trg_salary_update_audit
AFTER UPDATE ON Salaries
FOR EACH ROW
BEGIN
    INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
    VALUES (NEW.employee_id, OLD.salary_amount, NEW.salary_amount, USER(), 'UPDATE');
END$$

-- Trigger: After DELETE on Salaries
CREATE TRIGGER trg_salary_delete_audit
AFTER DELETE ON Salaries
FOR EACH ROW
BEGIN
    INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
    VALUES (OLD.employee_id, OLD.salary_amount, NULL, USER(), 'DELETE');
END$$

DELIMITER ;

-- Test the trigger
UPDATE Salaries SET salary_amount = 5200000.00 WHERE employee_id = 3;

-- View audit log
SELECT * FROM SalaryAudit;

-- ============================================
-- d) STORED PROCEDURE: Increase salary by 10% for below-average earners
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_increase_below_average_salary()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_employee_id INT;
    DECLARE v_current_salary DECIMAL(10, 2);
    DECLARE v_dept_id INT;
    DECLARE v_dept_avg DECIMAL(10, 2);
    
    -- Cursor to iterate through employees
    DECLARE emp_cursor CURSOR FOR
        SELECT e.employee_id, s.salary_amount, e.department_id
        FROM Employees e
        JOIN Salaries s ON e.employee_id = s.employee_id
        WHERE s.end_date IS NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN emp_cursor;
    
    read_loop: LOOP
        FETCH emp_cursor INTO v_employee_id, v_current_salary, v_dept_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calculate department average
        SELECT AVG(s.salary_amount) INTO v_dept_avg
        FROM Employees e
        JOIN Salaries s ON e.employee_id = s.employee_id
        WHERE e.department_id = v_dept_id
        AND s.end_date IS NULL;
        
        -- Increase salary if below average
        IF v_current_salary < v_dept_avg THEN
            UPDATE Salaries
            SET salary_amount = salary_amount * 1.10
            WHERE employee_id = v_employee_id
            AND end_date IS NULL;
        END IF;
        
    END LOOP;
    
    CLOSE emp_cursor;
    
    SELECT 'Salary increase completed for below-average earners' AS message;
END$$

DELIMITER ;

-- Execute the stored procedure
CALL sp_increase_below_average_salary();

-- ============================================
-- e) REQUIRED SQL QUERIES
-- ============================================

-- e(i) List employees above the average salary
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.department_name,
    s.salary_amount,
    (SELECT AVG(salary_amount) FROM Salaries WHERE end_date IS NULL) AS overall_avg_salary
FROM Employees e
JOIN Salaries s ON e.employee_id = s.employee_id
JOIN Departments d ON e.department_id = d.department_id
WHERE s.end_date IS NULL
AND s.salary_amount > (SELECT AVG(salary_amount) FROM Salaries WHERE end_date IS NULL)
ORDER BY s.salary_amount DESC;

-- e(ii) Compute total salary per department
SELECT 
    d.department_id,
    d.department_name,
    d.location,
    COUNT(e.employee_id) AS employee_count,
    SUM(s.salary_amount) AS total_salary,
    AVG(s.salary_amount) AS average_salary,
    MIN(s.salary_amount) AS min_salary,
    MAX(s.salary_amount) AS max_salary
FROM Departments d
LEFT JOIN Employees e ON d.department_id = e.department_id
LEFT JOIN Salaries s ON e.employee_id = s.employee_id AND s.end_date IS NULL
GROUP BY d.department_id, d.department_name, d.location
ORDER BY total_salary DESC;

-- e(iii) Show newly hired employees (hired in last 12 months)
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.email,
    e.hire_date,
    DATEDIFF(CURRENT_DATE, e.hire_date) AS days_employed,
    d.department_name,
    e.job_title,
    s.salary_amount
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
LEFT JOIN Salaries s ON e.employee_id = s.employee_id AND s.end_date IS NULL
WHERE e.hire_date >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
ORDER BY e.hire_date DESC;

-- ============================================
-- ADDITIONAL USEFUL VIEWS AND QUERIES
-- ============================================

-- Create comprehensive employee view
CREATE OR REPLACE VIEW vw_employee_details AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.email,
    e.phone,
    e.hire_date,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE) AS years_employed,
    e.job_title,
    d.department_name,
    d.location,
    s.salary_amount AS current_salary,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name
FROM Employees e
LEFT JOIN Departments d ON e.department_id = d.department_id
LEFT JOIN Salaries s ON e.employee_id = s.employee_id AND s.end_date IS NULL
LEFT JOIN Employees m ON d.manager_id = m.employee_id;

-- Query the view
SELECT * FROM vw_employee_details
ORDER BY department_name, employee_name;

-- Salary comparison by department
SELECT 
    d.department_name,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    s.salary_amount,
    AVG(s2.salary_amount) AS dept_avg_salary,
    (s.salary_amount - AVG(s2.salary_amount)) AS diff_from_avg
FROM Employees e
JOIN Salaries s ON e.employee_id = s.employee_id
JOIN Departments d ON e.department_id = d.department_id
JOIN Employees e2 ON e2.department_id = d.department_id
JOIN Salaries s2 ON e2.employee_id = s2.employee_id
WHERE s.end_date IS NULL AND s2.end_date IS NULL
GROUP BY d.department_name, e.first_name, e.last_name, s.salary_amount
ORDER BY d.department_name, s.salary_amount DESC;
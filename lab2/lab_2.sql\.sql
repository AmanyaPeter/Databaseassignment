-- ============================================
-- LAB 2: EMPLOYEE MANAGEMENT SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_2;
CREATE DATABASE Lab_2;
USE Lab_2;

-- ============================================
-- SCHEMA DESIGN WITH CONSTRAINTS
-- ============================================

-- Table: Departments
CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) UNIQUE NOT NULL
);

-- Table: Employees
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    department_id INT,
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
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_employee (employee_id)
);

-- Table: SalaryAudit (where information from the trigger will go)
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

-- ============================================
-- SAMPLE DATA FOR TESTING
-- ============================================

INSERT INTO Departments (department_name)
VALUES ('Human Resources'), ('IT'), ('Finance');

INSERT INTO Employees (first_name, last_name, email, hire_date, department_id)
VALUES
('John', 'Okello', 'john.okello@must.ac.ug', '2023-04-05', 1),
('Sarah', 'Nanyonga', 'sarah.nanyonga@must.ac.ug', '2024-02-10', 2),
('Brian', 'Mugisha', 'brian.mugisha@must.ac.ug', '2025-01-20', 2),
('Grace', 'Atwine', 'grace.atwine@must.ac.ug', '2023-12-15', 3);

INSERT INTO Salaries (employee_id, salary_amount)
VALUES 
(1, 3000000.00),
(2, 4500000.00),
(3, 5000000.00),
(4, 2000000.00);

-- ============================================
-- (c) TRIGGERS FOR SALARY AUDIT LOGGING
-- ============================================

DELIMITER $$

-- Trigger: After INSERT in Salaries Table
CREATE TRIGGER trg_salary_insert_audit
AFTER INSERT ON Salaries
FOR EACH ROW
BEGIN
    INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
    VALUES (NEW.employee_id, NULL, NEW.salary_amount, USER(), 'INSERT');
END$$

-- Trigger: After UPDATE in Salaries Table
CREATE TRIGGER trg_salary_update_audit
AFTER UPDATE ON Salaries
FOR EACH ROW
BEGIN
    IF OLD.salary_amount <> NEW.salary_amount THEN
        INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
        VALUES (NEW.employee_id, OLD.salary_amount, NEW.salary_amount, USER(), 'UPDATE');
    END IF;
END$$

-- Trigger: After DELETE from Salaries Table
CREATE TRIGGER trg_salary_delete_audit
AFTER DELETE ON Salaries
FOR EACH ROW
BEGIN
    INSERT INTO SalaryAudit (employee_id, old_salary, new_salary, changed_by, action_type)
    VALUES (OLD.employee_id, OLD.salary_amount, NULL, USER(), 'DELETE');
END$$

DELIMITER ;

-- ============================================
-- (d) STORED PROCEDURE: INCREASE BELOW-AVERAGE SALARIES BY 10%
-- ============================================

DELIMITER $$

CREATE PROCEDURE IncreaseBelowAverageSalaries()
BEGIN
    UPDATE Salaries s
    JOIN Employees e ON s.employee_id = e.employee_id
    JOIN (
        SELECT e.department_id, AVG(s.salary_amount) AS avg_salary
        FROM Salaries s
        JOIN Employees e ON s.employee_id = e.employee_id
        GROUP BY e.department_id
    ) dept_avg ON e.department_id = dept_avg.department_id
    SET s.salary_amount = s.salary_amount * 1.10
    WHERE s.salary_amount < dept_avg.avg_salary;
END$$

DELIMITER ;



-- ============================================
-- (e) SQL QUERIES
-- ============================================

-- (i) List employees above the average salary per department
SELECT e.employee_id, e.first_name, e.last_name, s.salary_amount, d.department_name
FROM Employees e
JOIN Salaries s ON e.employee_id = s.employee_id
JOIN Departments d ON e.department_id = d.department_id
JOIN (
    SELECT e.department_id, AVG(s.salary_amount) AS avg_sal
    FROM Employees e
    JOIN Salaries s ON e.employee_id = s.employee_id
    GROUP BY e.department_id
) avg_salaries ON e.department_id = avg_salaries.department_id
WHERE s.salary_amount > avg_salaries.avg_sal;

-- (ii) Compute total salary per department
SELECT d.department_name, SUM(s.salary_amount) AS total_salary
FROM Departments d
JOIN Employees e ON d.department_id = e.department_id
JOIN Salaries s ON e.employee_id = s.employee_id
GROUP BY d.department_name;

-- (iii) Show newly hired employees (in last 30 days)
SELECT employee_id, first_name, last_name, hire_date
FROM Employees
WHERE hire_date >= CURDATE() - INTERVAL 30 DAY;


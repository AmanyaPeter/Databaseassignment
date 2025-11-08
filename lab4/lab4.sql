-- ============================================
-- LAB 4: HOSPITAL MANAGEMENT SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_4;
CREATE DATABASE Lab_4;
USE Lab_4;

-- ============================================
-- a) DATABASE DESIGN (Normalized up to 3NF)
-- ============================================

CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    total_beds INT NOT NULL CHECK (total_beds >= 0),
    available_beds INT NOT NULL CHECK (available_beds >= 0)
);

CREATE TABLE Doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    dob DATE,
    contact VARCHAR(20),
    address VARCHAR(255)
);

CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO Departments (name, total_beds, available_beds)
VALUES ('Cardiology', 20, 10),
       ('Neurology', 15, 8),
       ('Pediatrics', 25, 20);

INSERT INTO Doctors (name, specialization, department_id)
VALUES ('Dr. Jane', 'Cardiologist', 1),
       ('Dr. Brian', 'Neurologist', 2),
       ('Dr. Mary', 'Pediatrician', 3);

INSERT INTO Patients (name, dob, contact, address)
VALUES ('John Doe', '1990-02-15', '+256700111222', 'Mbarara'),
       ('Sarah K', '1988-06-12', '+256700333444', 'Kampala'),
       ('Peter A', '2000-09-05', '+256700555666', 'Ntungamo');

INSERT INTO Appointments (patient_id, doctor_id, admission_date, discharge_date)
VALUES (1, 1, '2025-11-01', '2025-11-05'),
       (2, 2, '2025-11-02', '2025-11-07'),
       (3, 3, '2025-11-03', NULL);

-- ============================================
-- d) TRIGGERS TO UPDATE BED COUNT
-- ============================================

DELIMITER $$

-- After new admission (INSERT)
CREATE TRIGGER trg_decrease_beds_after_admission
AFTER INSERT ON Appointments
FOR EACH ROW
BEGIN
    UPDATE Departments d
    JOIN Doctors doc ON doc.department_id = d.department_id
    SET d.available_beds = d.available_beds - 1
    WHERE doc.doctor_id = NEW.doctor_id
      AND d.available_beds > 0;
END$$

-- After patient discharge (UPDATE)
CREATE TRIGGER trg_increase_beds_after_discharge
AFTER UPDATE ON Appointments
FOR EACH ROW
BEGIN
    IF NEW.discharge_date IS NOT NULL AND OLD.discharge_date IS NULL THEN
        UPDATE Departments d
        JOIN Doctors doc ON doc.department_id = d.department_id
        SET d.available_beds = d.available_beds + 1
        WHERE doc.doctor_id = NEW.doctor_id;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- c) STORED PROCEDURE: PATIENT STAY & AVERAGE DURATION
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_patient_stay_summary(IN dept_id INT)
BEGIN
    SELECT d.name AS department,
           p.name AS patient,
           DATEDIFF(a.discharge_date, a.admission_date) AS stay_days
    FROM Appointments a
    JOIN Doctors doc ON a.doctor_id = doc.doctor_id
    JOIN Departments d ON doc.department_id = d.department_id
    JOIN Patients p ON a.patient_id = p.patient_id
    WHERE d.department_id = dept_id AND a.discharge_date IS NOT NULL;

    SELECT d.name AS department,
           ROUND(AVG(DATEDIFF(a.discharge_date, a.admission_date)), 2) AS avg_stay_days
    FROM Appointments a
    JOIN Doctors doc ON a.doctor_id = doc.doctor_id
    JOIN Departments d ON doc.department_id = d.department_id
    WHERE d.department_id = dept_id AND a.discharge_date IS NOT NULL
    GROUP BY d.department_id;
END$$

DELIMITER ;

-- ============================================
-- e) QUERIES & VIEW
-- ============================================

-- (i) Top 3 departments by patient load
SELECT d.name AS department, COUNT(a.appointment_id) AS total_patients
FROM Departments d
JOIN Doctors doc ON d.department_id = doc.department_id
JOIN Appointments a ON doc.doctor_id = a.doctor_id
GROUP BY d.name
ORDER BY total_patients DESC
LIMIT 3;

-- (ii) View combining patient, doctor, and department info
CREATE VIEW vw_patient_doctor_department AS
SELECT p.name AS patient_name,
       doc.name AS doctor_name,
       doc.specialization,
       d.name AS department,
       a.admission_date,
       a.discharge_date
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors doc ON a.doctor_id = doc.doctor_id
JOIN Departments d ON doc.department_id = d.department_id;

-- ============================================
-- TESTS
-- ============================================

-- View hospital summary
SELECT * FROM vw_patient_doctor_department;

-- Call stay duration summary for Cardiology
CALL sp_patient_stay_summary(1);

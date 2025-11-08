-- ============================================
-- LAB 10: SMART CITY PARKING SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS SmartCityParking;
CREATE DATABASE SmartCityParking;
USE SmartCityParking;

-- ============================================
-- SCHEMA DESIGN WITH CONSTRAINTS
-- ============================================

-- Table: Vehicles
CREATE TABLE Vehicles (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    contact VARCHAR(20)
);

-- Table: ParkingSlots
CREATE TABLE ParkingSlots (
    slot_id INT PRIMARY KEY AUTO_INCREMENT,
    slot_number VARCHAR(20) UNIQUE NOT NULL,
    parking_area VARCHAR(50) NOT NULL,
    status ENUM('Available', 'Occupied') DEFAULT 'Available'
);

-- Table: ParkingSessions
CREATE TABLE ParkingSessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    slot_id INT NOT NULL,
    entry_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    exit_time DATETIME,
    fee DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES ParkingSlots(slot_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_vehicle (vehicle_id),
    INDEX idx_slot (slot_id),
    INDEX idx_entry_time (entry_time)
);

-- Table: Payments
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Cash','Mobile','Card') DEFAULT 'Cash',
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES ParkingSessions(session_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_session (session_id)
);

-- ============================================
-- TRIGGER: Calculate Parking Fee on Exit
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_calculate_parking_fee
BEFORE UPDATE ON ParkingSessions
FOR EACH ROW
BEGIN
    DECLARE duration_hours DECIMAL(10,2);
    DECLARE rate DECIMAL(10,2);

    IF NEW.exit_time IS NOT NULL AND OLD.exit_time IS NULL THEN
        SET duration_hours = TIMESTAMPDIFF(HOUR, NEW.entry_time, NEW.exit_time);
        SET rate = 5000.00; -- UGX per hour
        SET NEW.fee = duration_hours * rate;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- STORED PROCEDURE: Daily Revenue Summary
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_daily_revenue(IN target_date DATE)
BEGIN
    SELECT pl.parking_area,
           COUNT(ps.session_id) AS sessions,
           SUM(ps.fee) AS total_revenue
    FROM ParkingSessions ps
    JOIN ParkingSlots pl ON ps.slot_id = pl.slot_id
    WHERE DATE(ps.entry_time) = target_date
    GROUP BY pl.parking_area;
END$$

DELIMITER ;

-- ============================================
-- ROLE-BASED PRIVILEGES
-- ============================================

-- Create users
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin_pass';
CREATE USER 'attendant'@'localhost' IDENTIFIED BY 'attendant_pass';

-- Grant privileges to attendant
GRANT SELECT, INSERT, UPDATE ON ParkingSessions TO 'attendant'@'localhost';
GRANT SELECT ON Vehicles TO 'attendant'@'localhost';
GRANT SELECT ON ParkingSlots TO 'attendant'@'localhost';


-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

INSERT INTO Vehicles (plate_number, owner_name, contact) VALUES
('UAA123A', 'John Mugisha', '+256701234567'),
('UAB456B', 'Sarah Nalule', '+256702234568'),
('UAC789C', 'David Okello', '+256703234569');

INSERT INTO ParkingSlots (slot_number, parking_area, status) VALUES
('SLOT1', 'Area A', 'Available'),
('SLOT2', 'Area A', 'Available'),
('SLOT3', 'Area B', 'Available');

INSERT INTO ParkingSessions (vehicle_id, slot_id, entry_time) VALUES
(1, 1, '2025-11-08 08:00:00'),
(2, 2, '2025-11-08 09:30:00');

-- ============================================
-- TESTING FEE CALCULATION
-- ============================================

-- Update exit time to trigger fee calculation
UPDATE ParkingSessions
SET exit_time = '2025-11-08 12:30:00'
WHERE session_id = 1;

SELECT * FROM ParkingSessions;

-- ============================================
-- TESTING DAILY REVENUE PROCEDURE
-- ============================================

CALL sp_daily_revenue('2025-11-08');

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_plate_number ON Vehicles(plate_number);
CREATE INDEX idx_slot_number ON ParkingSlots(slot_number);
CREATE INDEX idx_session_entry ON ParkingSessions(entry_time);

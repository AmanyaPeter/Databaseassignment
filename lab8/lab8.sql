-- ============================================
-- LAB 8: AIRLINE RESERVATION SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_8;
CREATE DATABASE Lab_8;
USE Lab_8;

-- ============================================
-- a) SCHEMA DESIGN
-- ============================================

CREATE TABLE Flights (
    flight_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_number VARCHAR(20) UNIQUE NOT NULL,
    route VARCHAR(100) NOT NULL,
    total_seats INT NOT NULL CHECK (total_seats > 0),
    departure_time DATETIME NOT NULL
);

CREATE TABLE Passengers (
    passenger_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    passport_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(15)
);

CREATE TABLE Bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_id INT,
    passenger_id INT,
    booking_date DATE DEFAULT (CURRENT_DATE()),
    seat_number VARCHAR(10),
    status ENUM('Pending', 'Confirmed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (flight_id) REFERENCES Flights(flight_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT (CURRENT_DATE()),
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================
-- b) SAMPLE DATA
-- ============================================

INSERT INTO Flights (flight_number, route, total_seats, departure_time) VALUES
('FL100', 'Kampala - Nairobi', 100, '2025-11-10 08:00:00'),
('FL200', 'Kampala - Entebbe', 50, '2025-11-11 14:00:00'),
('FL300', 'Nairobi - Kigali', 120, '2025-11-12 09:00:00');

INSERT INTO Passengers (name, passport_number, email, phone) VALUES
('John Doe', 'P1234567', 'john@example.com', '+256701234567'),
('Sarah K', 'P2345678', 'sarah@example.com', '+256702234568'),
('Peter A', 'P3456789', 'peter@example.com', '+256703234569');

INSERT INTO Bookings (flight_id, passenger_id, status) VALUES
(1, 1, 'Confirmed'),
(1, 2, 'Confirmed'),
(2, 3, 'Pending');

INSERT INTO Payments (booking_id, amount) VALUES
(1, 1000.00),
(2, 1000.00);

-- ============================================
-- c) TRIGGER: Prevent Overbooking
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_prevent_overbooking
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE booked_seats INT DEFAULT 0;
    DECLARE total_capacity INT DEFAULT 0;

    SELECT COUNT(*), f.total_seats INTO booked_seats, total_capacity
    FROM Bookings b
    JOIN Flights f ON b.flight_id = f.flight_id
    WHERE b.flight_id = NEW.flight_id AND b.status = 'Confirmed'
    GROUP BY f.total_seats;

    IF booked_seats >= total_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Flight fully booked';
    END IF;
END$$

DELIMITER ;

-- ============================================
-- d) STORED PROCEDURE: Flight Occupancy & Revenue
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_flight_occupancy(IN route_name VARCHAR(100))
BEGIN
    SELECT f.flight_number,
           COUNT(b.booking_id) AS bookings,
           f.total_seats,
           (COUNT(b.booking_id) / f.total_seats * 100) AS occupancy_rate,
           SUM(p.amount) AS total_revenue
    FROM Flights f
    LEFT JOIN Bookings b ON f.flight_id = b.flight_id AND b.status = 'Confirmed'
    LEFT JOIN Payments p ON b.booking_id = p.booking_id
    WHERE f.route = route_name
    GROUP BY f.flight_number, f.total_seats;
END$$

DELIMITER ;

-- ============================================
-- e) VIEW: Passengers with More Than 3 Flights in a Month
-- ============================================

CREATE VIEW vw_frequent_passengers AS
SELECT p.passenger_id,
       p.name AS passenger_name,
       COUNT(b.booking_id) AS flights_booked,
       MONTH(b.booking_date) AS month,
       YEAR(b.booking_date) AS year
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
WHERE b.status = 'Confirmed'
GROUP BY p.passenger_id, MONTH(b.booking_date), YEAR(b.booking_date)
HAVING COUNT(b.booking_id) > 3;

-- ============================================
-- f) INDEXING
-- ============================================

CREATE INDEX idx_flight_number ON Flights(flight_number);
CREATE INDEX idx_passenger_id ON Bookings(passenger_id);

-- ============================================
-- g) TESTING
-- ============================================

-- Test overbooking trigger
INSERT INTO Bookings (flight_id, passenger_id, status)
VALUES (1, 3, 'Confirmed');

-- Test stored procedure
CALL sp_flight_occupancy('Kampala - Nairobi');

-- View frequent passengers
SELECT * FROM vw_frequent_passengers;

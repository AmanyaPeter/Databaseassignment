-- ============================================
-- LAB 1: UNIVERSITY ENROLLMENT SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

-- DROP DATABASE IF EXISTS to start fresh
DROP DATABASE IF EXISTS  Lab_1;
CREATE DATABASE Lab_1;
USE Lab_1;

-- ============================================
-- SCHEMA DESIGN (Normalized to 3NF)
-- ============================================

-- Table: Students
CREATE TABLE Students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    date_of_birth DATE,
    enrollment_date DATE DEFAULT (CURRENT_DATE),
    INDEX idx_email (email)
);

-- Table: Lecturers
CREATE TABLE Lecturers (
    lecturer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50),
    phone VARCHAR(15),
    INDEX idx_department (department)
);

-- Table: Courses
CREATE TABLE Courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    credits INT CHECK (credits > 0),
    lecturer_id INT,
    FOREIGN KEY (lecturer_id) REFERENCES Lecturers(lecturer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_course_code (course_code)
);

-- Table: Enrollments (Junction table for Many-to-Many relationship)
CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_date DATE DEFAULT (CURRENT_DATE),
    grade VARCHAR(2),
    status ENUM('Active', 'Completed', 'Dropped') DEFAULT 'Active',
    FOREIGN KEY (student_id) REFERENCES Students(student_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    UNIQUE KEY unique_enrollment (student_id, course_id),
    INDEX idx_student (student_id),
    INDEX idx_course (course_id)
);

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert Lecturers
INSERT INTO Lecturers (first_name, last_name, email, department, phone) VALUES
('Dr. James', 'Mugisha', 'j.mugisha@must.ac.ug', 'Computer Science', '+256701234567'),
('Dr. Sarah', 'Nakato', 's.nakato@must.ac.ug', 'Computer Science', '+256702234568'),
('Prof. Peter', 'Okello', 'p.okello@must.ac.ug', 'Mathematics', '+256703234569'),
('Dr. Mary', 'Atim', 'm.atim@must.ac.ug', 'Computer Science', '+256704234570'),
('Dr. John', 'Ssebunya', 'j.ssebunya@must.ac.ug', 'Information Systems', '+256705234571');

-- Insert Courses
INSERT INTO Courses (course_code, course_name, credits, lecturer_id) VALUES
('CS201', 'Database Systems', 4, 1),
('CS202', 'Data Structures and Algorithms', 4, 2),
('CS203', 'Web Development', 3, 4),
('MT101', 'Discrete Mathematics', 3, 3),
('IS301', 'Systems Analysis and Design', 4, 5);

-- Insert Students (10 students as required)
INSERT INTO Students (first_name, last_name, email, phone, date_of_birth, enrollment_date) VALUES
('Allan', 'Kato', 'allan.kato@student.must.ac.ug', '+256771000001', '2003-05-15', '2023-08-01'),
('Betty', 'Namukasa', 'betty.namukasa@student.must.ac.ug', '+256771000002', '2002-11-20', '2023-08-01'),
('Charles', 'Opio', 'charles.opio@student.must.ac.ug', '+256771000003', '2003-03-10', '2023-08-01'),
('Diana', 'Aceng', 'diana.aceng@student.must.ac.ug', '+256771000004', '2002-07-25', '2023-08-01'),
('Emmanuel', 'Ssemakula', 'emmanuel.ssemakula@student.must.ac.ug', '+256771000005', '2003-01-30', '2023-08-01'),
('Flavia', 'Nabirye', 'flavia.nabirye@student.must.ac.ug', '+256771000006', '2002-09-18', '2023-08-01'),
('George', 'Tumwine', 'george.tumwine@student.must.ac.ug', '+256771000007', '2003-06-22', '2023-08-01'),
('Hilda', 'Akello', 'hilda.akello@student.must.ac.ug', '+256771000008', '2002-12-05', '2023-08-01'),
('Isaac', 'Byaruhanga', 'isaac.byaruhanga@student.must.ac.ug', '+256771000009', '2003-04-14', '2023-08-01'),
('Joan', 'Nankya', 'joan.nankya@student.must.ac.ug', '+256771000010', '2002-10-08', '2023-08-01');

-- Enroll students in courses (each student takes at least 2 courses)
INSERT INTO Enrollments (student_id, course_id, enrollment_date, status) VALUES
-- Allan: 3 courses
(1, 1, '2023-08-15', 'Active'),
(1, 2, '2023-08-15', 'Active'),
(1, 4, '2023-08-15', 'Active'),
-- Betty: 2 courses
(2, 1, '2023-08-15', 'Active'),
(2, 3, '2023-08-15', 'Active'),
-- Charles: 4 courses
(3, 1, '2023-08-15', 'Active'),
(3, 2, '2023-08-15', 'Active'),
(3, 3, '2023-08-15', 'Active'),
(3, 5, '2023-08-15', 'Active'),
-- Diana: 2 courses
(4, 2, '2023-08-15', 'Active'),
(4, 4, '2023-08-15', 'Active'),
-- Emmanuel: 3 courses
(5, 1, '2023-08-15', 'Active'),
(5, 3, '2023-08-15', 'Active'),
(5, 5, '2023-08-15', 'Active'),
-- Flavia: 2 courses
(6, 2, '2023-08-15', 'Active'),
(6, 5, '2023-08-15', 'Active'),
-- George: 3 courses
(7, 1, '2023-08-15', 'Active'),
(7, 4, '2023-08-15', 'Active'),
(7, 5, '2023-08-15', 'Active'),
-- Hilda: 2 courses
(8, 3, '2023-08-15', 'Active'),
(8, 4, '2023-08-15', 'Active'),
-- Isaac: 2 courses
(9, 2, '2023-08-15', 'Active'),
(9, 3, '2023-08-15', 'Active'),
-- Joan: 2 courses
(10, 4, '2023-08-15', 'Active'),
(10, 5, '2023-08-15', 'Active');

-- ============================================
-- REQUIRED SQL QUERIES
-- ============================================

-- d(i) List all students enrolled in a given course (e.g., CS201 - Database Systems)
SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    c.course_code,
    c.course_name,
    e.enrollment_date,
    e.status
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id
WHERE c.course_code = 'CS201'
ORDER BY s.last_name, s.first_name;

-- d(ii) Find students taking more than two courses
SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    COUNT(e.course_id) AS course_count
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
WHERE e.status = 'Active'
GROUP BY s.student_id, s.first_name, s.last_name, s.email
HAVING COUNT(e.course_id) > 2
ORDER BY course_count DESC, s.last_name;

-- d(iii) Compute enrollment count per course
SELECT 
    c.course_id,
    c.course_code,
    c.course_name,
    CONCAT(l.first_name, ' ', l.last_name) AS lecturer,
    COUNT(e.student_id) AS enrollment_count
FROM Courses c
LEFT JOIN Enrollments e ON c.course_id = e.course_id AND e.status = 'Active'
LEFT JOIN Lecturers l ON c.lecturer_id = l.lecturer_id
GROUP BY c.course_id, c.course_code, c.course_name, l.first_name, l.last_name
ORDER BY enrollment_count DESC;

-- ============================================
-- e) UPDATE OPERATION - Change email with referential integrity
-- ============================================

-- Update student's email address
UPDATE Students
SET email = 'allan.kato.updated@student.must.ac.ug'
WHERE student_id = 1;

-- Verify the update
SELECT student_id, first_name, last_name, email
FROM Students
WHERE student_id = 1;

-- ============================================
-- f) DELETE OPERATION - Remove courses with no enrolled students
-- ============================================

-- First, let's add a course with no enrollments for demonstration
INSERT INTO Courses (course_code, course_name, credits, lecturer_id) 
VALUES ('CS299', 'Special Topics in CS', 3, 2);

-- Delete courses with no enrolled students
DELETE FROM Courses
WHERE course_id NOT IN (
    SELECT DISTINCT course_id 
    FROM Enrollments
);

-- Verify deletion
SELECT * FROM Courses;

-- ============================================
-- ADDITIONAL USEFUL QUERIES
-- ============================================

-- View complete enrollment details
CREATE OR REPLACE VIEW vw_enrollment_details AS
SELECT 
    e.enrollment_id,
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.course_name,
    CONCAT(l.first_name, ' ', l.last_name) AS lecturer_name,
    e.enrollment_date,
    e.status,
    e.grade
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
LEFT JOIN Lecturers l ON c.lecturer_id = l.lecturer_id;

-- Query the view
SELECT * FROM vw_enrollment_details
WHERE status = 'Active'
ORDER BY course_code, student_name;

-- ============================================
-- PERFORMANCE ANALYSIS
-- ============================================

-- Analyze query performance for finding students in a course
EXPLAIN SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id
WHERE c.course_code = 'CS201';

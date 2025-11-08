-- ======================================
-- LAB 1: UNIVERSITY ENROLLMENT SYSTEM
-- ======================================

DROP DATABASE IF EXISTS  Lab_1;
CREATE DATABASE Lab_1;
USE Lab_1;

-- ================================
-- a) TABLE CREATION 
-- ================================

CREATE TABLE Lecturers (
    LecturerID INT AUTO_INCREMENT PRIMARY KEY,
    LecturerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Courses (
    CourseID INT AUTO_INCREMENT PRIMARY KEY,
    CourseName VARCHAR(100) NOT NULL,
    CourseCode VARCHAR(10),
    LecturerID INT,
    FOREIGN KEY (LecturerID) REFERENCES Lecturers(LecturerID)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Students (
    StudentID INT AUTO_INCREMENT PRIMARY KEY,
    StudentName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Enrollments (
    EnrollmentID INT AUTO_INCREMENT PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATE DEFAULT (CURRENT_DATE()),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT Uno_enrollment UNIQUE (StudentID, CourseID)
);

-- ==================================
-- b) NORMALIZED UP TO 3NF
-- (Already done through the design)
-- ==================================

-- ================================
-- c) INSERT SAMPLE DATA
-- ================================

INSERT INTO Lecturers (LecturerName, Email) VALUES
('Dr. Kato Brian', 'brian.kato@university.ac.ug'),
('Dr. Grace Nanyonga', 'grace.nanyonga@university.ac.ug'),
('Dr. Peter Okello', 'peter.okello@university.ac.ug');

INSERT INTO Courses (CourseName, LecturerID,CourseCode) VALUES
('Database Systems', 1,'CSC101'),
('Computer Networks', 1,'CSC102'),
('Software Engineering', 2,'CSC103'),
('Artificial Intelligence', 3,'CSC104'),
('Data Structures', 3,'CSC105');

INSERT INTO Students (StudentName, Email) VALUES
('Amanya Peter', 'peter.amanya@uni.ac.ug'),
('Doreen Miracle', 'doreen.miracle@uni.ac.ug'),
('Rwendeire Joshua', 'joshua.rwendeire@uni.ac.ug'),
('Muhwezi Amon', 'amon.muhwezi@uni.ac.ug'),
('Twinomugisha Nickson', 'nickson.twinomugisha@uni.ac.ug'),
('Nanjuki Daphine', 'daphine.nanjuki@uni.ac.ug'),
('Akankwasa James', 'james.akankwasa@uni.ac.ug'),
('Katushabe Alice', 'alice.katushabe@uni.ac.ug'),
('Mugisha Henry', 'henry.mugisha@uni.ac.ug'),
('Namakula Sarah', 'sarah.namakula@uni.ac.ug');

-- Assign each student to at least two courses
INSERT INTO Enrollments (StudentID, CourseID) VALUES
(1,1),(1,2),
(2,2),(2,3),
(3,1),(3,3),
(4,3),(4,4),
(5,1),(5,5),
(6,2),(6,5),
(7,1),(7,4),
(8,3),(8,5),
(9,4),(9,5),
(10,2),(10,3);

-- ============================================
-- d) SQL QUERIES
-- ============================================

-- (i) List all students enrolled in a given course (e.g., CourseID = 1)
SELECT s.StudentName
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
WHERE e.CourseID = 1;

-- (ii) Find students taking more than two courses
SELECT s.StudentName, COUNT(e.CourseID) AS CourseCount
FROM Students s
JOIN Enrollments e ON s.StudentID = e.StudentID
GROUP BY s.StudentID
HAVING COUNT(e.CourseID) > 2
ORDER BY CourseCount DESC;

-- (iii) Compute enrollment count per course
SELECT c.CourseName, COUNT(e.StudentID) AS TotalEnrolled
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID;

-- ============================================
-- e) Update a student’s email (maintaining referential integrity)
-- ============================================

UPDATE Students
SET Email = 'amanyapeter.updated@uni.ac.ug'
WHERE StudentID = 1;

-- Referential integrity is preserved automatically because no other table depends directly on Email field.

-- ============================================
-- f) Delete all courses with no enrolled students
-- ============================================
-- Since there are no courses with no enroled students , I will first add one
INSERT INTO Courses (CourseName, LecturerID,CourseCode) VALUES
('POlitical Phsycology', 1,'DVS105');

DELETE FROM Courses
WHERE CourseID NOT IN (SELECT DISTINCT CourseID FROM Enrollments);

-- ============================================
-- I HOPE THE SCRIPT IS OKAY SIR
-- ============================================

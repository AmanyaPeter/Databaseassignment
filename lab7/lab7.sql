-- ============================================
-- LAB 7: LIBRARY MANAGEMENT SYSTEM
-- Mbarara University of Science and Technology
-- Database Programming - BCS II
-- ============================================

DROP DATABASE IF EXISTS Lab_7;
CREATE DATABASE Lab_7;
USE Lab_7;

-- ============================================
-- a) SCHEMA DESIGN
-- ============================================

CREATE TABLE Authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50)
);

CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author_id INT,
    available_copies INT NOT NULL CHECK (available_copies >= 0),
    FOREIGN KEY (author_id) REFERENCES Authors(author_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE Members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    membership_date DATE DEFAULT (CURRENT_DATE())
);

CREATE TABLE BorrowingRecords (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT,
    member_id INT,
    borrow_date DATE DEFAULT (CURRENT_DATE()),
    due_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (member_id) REFERENCES Members(member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================
-- b) SAMPLE DATA
-- ============================================

INSERT INTO Authors (name, nationality) VALUES
('Chinua Achebe', 'Nigeria'),
('Ngugi wa Thiong''o', 'Kenya'),
('Terry Pratchett', 'UK');

INSERT INTO Books (isbn, title, author_id, available_copies) VALUES
('9780141185064', 'Things Fall Apart', 1, 5),
('9780435903570', 'Weep Not, Child', 2, 3),
('9780552166591', 'Guards! Guards!', 3, 4);

INSERT INTO Members (name, email) VALUES
('John Doe', 'john@example.com'),
('Sarah K', 'sarah@example.com'),
('Peter A', 'peter@example.com');

INSERT INTO BorrowingRecords (book_id, member_id, borrow_date, due_date) VALUES
(1, 1, '2025-11-01', '2025-11-10'),
(2, 2, '2025-11-03', '2025-11-12'),
(3, 3, '2025-11-05', '2025-11-15');

-- ============================================
-- c) TRIGGERS: Update Book Availability
-- ============================================

DELIMITER $$

-- On borrow: decrease available copies
CREATE TRIGGER trg_decrease_available
AFTER INSERT ON BorrowingRecords
FOR EACH ROW
BEGIN
    UPDATE Books
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id;
END$$

-- On return: increase available copies
CREATE TRIGGER trg_increase_available
AFTER UPDATE ON BorrowingRecords
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Books
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- d) STORED FUNCTION: Calculate Overdue Fine
-- ============================================

DELIMITER $$

CREATE FUNCTION fn_calculate_fine(borrow_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE days_overdue INT;
    DECLARE fine DECIMAL(10,2);

    SELECT DATEDIFF(CURRENT_DATE, due_date) INTO days_overdue
    FROM BorrowingRecords
    WHERE record_id = borrow_id AND return_date IS NULL;

    IF days_overdue > 0 THEN
        SET fine = days_overdue * 1000.00; -- 1000 UGX per day
    ELSE
        SET fine = 0.00;
    END IF;

    RETURN fine;
END$$

DELIMITER ;

-- ============================================
-- e) VIEW: Members with Overdue Books
-- ============================================

CREATE VIEW vw_overdue_books AS
SELECT 
    m.member_id,
    m.name AS member_name,
    b.title AS book_title,
    br.due_date,
    DATEDIFF(CURRENT_DATE, br.due_date) AS days_overdue,
    DATEDIFF(CURRENT_DATE, br.due_date) * 1000 AS fine_amount
FROM BorrowingRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.return_date IS NULL AND br.due_date < CURRENT_DATE;

-- ============================================
-- f) INDEXING
-- ============================================

CREATE INDEX idx_isbn ON Books(isbn);
CREATE INDEX idx_member_id ON BorrowingRecords(member_id);

-- ============================================
-- g) TESTING
-- ============================================

-- Borrow a new book
INSERT INTO BorrowingRecords (book_id, member_id, borrow_date, due_date)
VALUES (1, 2, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY));

-- Return a book
UPDATE BorrowingRecords
SET return_date = CURRENT_DATE
WHERE record_id = 1;

-- Check updated book availability
SELECT * FROM Books;

-- Calculate fine for a member
SELECT fn_calculate_fine(2) AS overdue_fine;

-- View overdue books
SELECT * FROM vw_overdue_books;

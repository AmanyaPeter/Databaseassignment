-- ============================================
-- LAB 11: RESEARCH PUBLICATION REPOSITORY
-- ============================================

DROP DATABASE IF EXISTS ResearchRepo;
CREATE DATABASE ResearchRepo;
USE ResearchRepo;

-- ============================================
-- CORE TABLES
-- ============================================
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    department VARCHAR(100),
    affiliation VARCHAR(100)
);

CREATE TABLE Publications (
    publication_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    year INT,
    journal VARCHAR(255),
    doi VARCHAR(100),
    author_id INT,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id)
);

CREATE TABLE Citations (
    citation_id INT AUTO_INCREMENT PRIMARY KEY,
    citing_pub_id INT,
    cited_pub_id INT,
    FOREIGN KEY (citing_pub_id) REFERENCES Publications(publication_id),
    FOREIGN KEY (cited_pub_id) REFERENCES Publications(publication_id)
);

-- ============================================
-- b) Top Cited Ppaers
-- ============================================
SELECT p.title, COUNT(c.citation_id) AS citation_count
FROM Publications p
LEFT JOIN Citations c ON p.publication_id = c.cited_pub_id
GROUP BY p.publication_id, p.title
ORDER BY citation_count DESC
LIMIT 5;

-- ============================================
-- Authors with the most publications
-- ============================================
SELECT a.name, COUNT(p.publication_id) AS total_publications
FROM Authors a
LEFT JOIN Publications p ON a.author_id = p.author_id
GROUP BY a.author_id, a.name
ORDER BY total_publications DESC
LIMIT 5;


-- ============================================
-- c) H-Index Calculation Function
-- ============================================
DELIMITER $$

CREATE FUNCTION h_index(author_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE h_index INT;

    -- Use a CTE to rank the author's papers by citation count
    WITH ranked_papers AS (
        SELECT 
            p.publication_id,
            COUNT(c.cited_pub_id) AS citation_count,
            RANK() OVER (ORDER BY COUNT(c.cited_pub_id) DESC) AS citation_rank
        FROM Publications p
        LEFT JOIN Citations c ON p.publication_id = c.cited_pub_id
        WHERE p.author_id = author_id
        GROUP BY p.publication_id
    )
    SELECT MAX(citation_rank) INTO h_index
    FROM ranked_papers
    WHERE citation_count >= citation_rank;

    RETURN IFNULL(h_index, 0);
END$$

DELIMITER ;


-- ============================================
--  VIEW GROUPING PUBLICATIONS BY DEPARTMENTS
-- ============================================

CREATE VIEW DEPARTMENTAL AS 
    -> SELECT a.department ,p.title
    -> FROM Authors a 
    -> INNER JOIN Publications p ON a.author_id=p.author_id
    -> ORDER BY a.department;


-- ============================================
-- e)Triggers to log new publication entries
-- ============================================
 CREATE TABLE PublicationAudit (
    ->     audit_id INT AUTO_INCREMENT PRIMARY KEY,
    ->     publication_id INT,
    ->     action VARCHAR(50),
    ->     timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ->     user VARCHAR(100)
    -> );

 DELIMITER //
    -> CREATE TRIGGER trg_new_publication
    -> AFTER INSERT ON Publications
    -> FOR EACH ROW
    -> BEGIN
    ->     INSERT INTO PublicationAudit (publication_id, action, user)
    ->     VALUES (NEW.publication_id, 'NEW_PUBLICATION', USER());
    -> END;
    -> //
DELIMITER ;

-- ============================================
-- ACCESS CONTROL
-- ============================================

-- Create users
CREATE USER 'dept_head'@'localhost' ;
CREATE USER 'researcher'@'localhost';



-- Department heads can modify publication records
GRANT INSERT, UPDATE, DELETE ON Publications TO 'dept_head'@'localhost';

-- Researchers can only view publication data
GRANT SELECT ON Publications TO 'researcher'@'localhost';


-- ============================================
-- LAB 11: RESEARCH PUBLICATION REPOSITORY
-- ============================================

DROP DATABASE IF EXISTS ResearchRepo;
CREATE DATABASE ResearchRepo;
USE ResearchRepo;

-- ============================================
-- CORE TABLES
-- ============================================

-- Authors table
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    affiliation VARCHAR(100)
);

-- Publications table
CREATE TABLE Publications (
    publication_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    year YEAR,
    journal VARCHAR(100),
    doi VARCHAR(100) UNIQUE
);

-- AuthorPublications junction table
CREATE TABLE AuthorPublications (
    author_id INT,
    publication_id INT,
    author_order INT DEFAULT 1,
    PRIMARY KEY (author_id, publication_id),
    FOREIGN KEY (author_id) REFERENCES Authors(author_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (publication_id) REFERENCES Publications(publication_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Citations table
CREATE TABLE Citations (
    citation_id INT AUTO_INCREMENT PRIMARY KEY,
    citing_pub_id INT,
    cited_pub_id INT,
    FOREIGN KEY (citing_pub_id) REFERENCES Publications(publication_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (cited_pub_id) REFERENCES Publications(publication_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Publication audit table
CREATE TABLE PublicationAudit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    publication_id INT,
    action VARCHAR(50),
    action_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    action_user VARCHAR(100)
);

-- ============================================
-- TRIGGER: Audit new publications
-- ============================================

DELIMITER $$

CREATE TRIGGER trg_publication_insert
AFTER INSERT ON Publications
FOR EACH ROW
BEGIN
    INSERT INTO PublicationAudit (publication_id, action, action_user)
    VALUES (NEW.publication_id, 'INSERT_PUBLICATION', USER());
END$$

DELIMITER ;

-- ============================================
-- STORED FUNCTION: H-index calculation
-- ============================================

DELIMITER $$

CREATE FUNCTION fn_calculate_hindex(auth_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE h INT DEFAULT 0;

    -- Count citations per publication for the author and sort descending
    SET h = (
        SELECT MAX(cnt) FROM (
            SELECT COUNT(c.citation_id) AS cnt
            FROM Publications p
            JOIN AuthorPublications ap ON p.publication_id = ap.publication_id
            LEFT JOIN Citations c ON p.publication_id = c.cited_pub_id
            WHERE ap.author_id = auth_id
            GROUP BY p.publication_id
            HAVING COUNT(c.citation_id) >= 0
        ) AS citation_counts
    );

    RETURN IFNULL(h, 0);
END$$

DELIMITER ;

-- ============================================
-- VIEW: Publications grouped by department
-- ============================================

CREATE VIEW vw_publications_by_department AS
SELECT a.department, COUNT(DISTINCT p.publication_id) AS total_publications
FROM Authors a
JOIN AuthorPublications ap ON a.author_id = ap.author_id
JOIN Publications p ON ap.publication_id = p.publication_id
GROUP BY a.department;

-- ============================================
-- TOP 5 CITED PAPERS QUERY
-- ============================================

-- Example query
SELECT p.title, COUNT(c.citation_id) AS citation_count
FROM Publications p
LEFT JOIN Citations c ON p.publication_id = c.cited_pub_id
GROUP BY p.publication_id, p.title
ORDER BY citation_count DESC
LIMIT 5;

-- ============================================
-- ACCESS CONTROL
-- ============================================

-- Create users
CREATE USER 'dept_head'@'localhost' IDENTIFIED BY 'head_pass';
CREATE USER 'researcher'@'localhost' IDENTIFIED BY 'research_pass';

-- Grant privileges
GRANT INSERT, UPDATE, DELETE ON ResearchRepo.Publications TO 'dept_head'@'localhost';
GRANT SELECT ON ResearchRepo.Publications TO 'researcher'@'localhost';
GRANT SELECT ON ResearchRepo.Authors TO 'researcher'@'localhost';
GRANT SELECT ON ResearchRepo.AuthorPublications TO 'researcher'@'localhost';
GRANT SELECT ON ResearchRepo.Citations TO 'researcher'@'localhost';

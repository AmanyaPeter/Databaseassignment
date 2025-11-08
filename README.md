# Database Programming Lab Manual - Complete Guide
## Mbarara University of Science and Technology - BCS II

---

## 📋 Overview & Submission Requirements

### What to Submit:
1. **ERD Files (.mwb)** - MySQL Workbench model files
2. **SQL Scripts (.sql)** - All queries and implementations
3. **Report Document** covering:
   - Normalization analysis
   - Performance optimization strategies
   - Transaction control implementation

### Presentation Date: **Friday, November 7th, 2025 at 2:00 PM**

---

## 🎯 Key Concepts to Master

### 1. Database Normalization

#### **First Normal Form (1NF)**
- Eliminate repeating groups
- Each cell contains atomic values
- Each record is unique

#### **Second Normal Form (2NF)**
- Must be in 1NF
- Remove partial dependencies
- All non-key attributes depend on entire primary key

#### **Third Normal Form (3NF)**
- Must be in 2NF
- Remove transitive dependencies
- Non-key attributes depend only on primary key

**Example:**
```
Unnormalized: Student(ID, Name, Courses)
1NF: Student(ID, Name), Enrollment(StudentID, Course)
2NF: Student(ID, Name), Course(CourseID, Name), Enrollment(StudentID, CourseID)
3NF: Already in 3NF if no transitive dependencies exist
```

---

### 2. Triggers

Triggers automatically execute in response to database events.

**Syntax:**
```sql
DELIMITER $$
CREATE TRIGGER trigger_name
{BEFORE | AFTER} {INSERT | UPDATE | DELETE}
ON table_name
FOR EACH ROW
BEGIN
    -- Trigger logic here
    -- Use OLD.column for previous values
    -- Use NEW.column for new values
END$$
DELIMITER ;
```

**Common Use Cases:**
- Audit logging
- Data validation
- Maintaining derived data
- Enforcing business rules

---

### 3. Stored Procedures

Reusable SQL code blocks that can accept parameters.

**Syntax:**
```sql
DELIMITER $$
CREATE PROCEDURE procedure_name(
    IN param1 datatype,
    OUT param2 datatype,
    INOUT param3 datatype
)
BEGIN
    -- Procedure logic
END$$
DELIMITER ;
```

**Call:** `CALL procedure_name(value1, @output_var, @inout_var);`

---

### 4. Views

Virtual tables based on SELECT queries.

**Syntax:**
```sql
CREATE OR REPLACE VIEW view_name AS
SELECT columns
FROM tables
WHERE conditions;
```

**Benefits:**
- Simplify complex queries
- Security (hide sensitive columns)
- Data abstraction

---

### 5. Indexing

Improve query performance by creating data structures for fast lookups.

**Types:**
- **Primary Key Index** (automatically created)
- **Unique Index** (enforce uniqueness)
- **Regular Index** (speed up searches)
- **Composite Index** (multiple columns)

**Syntax:**
```sql
CREATE INDEX idx_name ON table_name(column_name);
CREATE INDEX idx_composite ON table_name(col1, col2);
```

**When to Use:**
- Columns in WHERE clauses
- JOIN columns
- Foreign keys
- ORDER BY columns

---

### 6. Transactions

Ensure data consistency with ACID properties.

**Syntax:**
```sql
START TRANSACTION;
-- SQL statements
COMMIT;  -- Save changes
-- OR
ROLLBACK;  -- Undo changes
```

**Isolation Levels:**
1. **READ UNCOMMITTED** - Lowest isolation, allows dirty reads
2. **READ COMMITTED** - Prevents dirty reads
3. **REPEATABLE READ** - Prevents non-repeatable reads (MySQL default)
4. **SERIALIZABLE** - Highest isolation, prevents phantom reads

---

## 📊 Lab-Specific Tips

### Lab 1: University Enrollment
- **Key Relationships:** Many-to-Many (Students ↔ Courses)
- **Junction Table:** Enrollments
- **Focus:** Basic CRUD operations, JOIN queries

### Lab 2: Employee Management
- **Key Feature:** Salary audit trail with triggers
- **Challenge:** Computing departmental averages
- **Focus:** Triggers, stored procedures, aggregate functions

### Lab 3: Retail Inventory
- **Key Feature:** Stock management automation
- **Challenge:** CASCADE operations on foreign keys
- **Focus:** Views, triggers for inventory updates

### Lab 4: Hospital Management
- **Key Feature:** Bed availability tracking
- **Challenge:** Date validation and duration calculations
- **Focus:** Complex constraints, computed columns

### Lab 5: Banking Transactions
- **Critical:** ACID compliance for money transfers
- **Challenge:** Concurrent transaction handling
- **Focus:** Transaction management, isolation levels

### Lab 6: E-commerce
- **Key Feature:** Dynamic discount system
- **Challenge:** Stock synchronization
- **Focus:** Business logic in procedures, performance tuning

### Lab 7: Library System
- **Key Feature:** Fine calculation
- **Challenge:** Book availability tracking
- **Focus:** Functions, date arithmetic

### Lab 8: Airline Reservations
- **Key Feature:** Prevent overbooking
- **Challenge:** Concurrent booking conflicts
- **Focus:** Transactions, business rule enforcement

### Lab 9: Health Insurance
- **Key Feature:** Claims processing workflow
- **Challenge:** Multi-entity aggregations
- **Focus:** Complex joins, grouping operations

### Lab 10: Parking System
- **Key Feature:** Dynamic fee calculation
- **Challenge:** Role-based access control
- **Focus:** User privileges, query optimization

### Lab 11: Research Repository
- **Key Feature:** Citation metrics (h-index)
- **Challenge:** Complex aggregation formulas
- **Focus:** Advanced analytics, access control

---

## 🛠️ MySQL Workbench ERD Best Practices

### Creating an ERD:
1. **File → New Model**
2. **Add Diagram** (click + icon)
3. **Use Table Tool** to add entities
4. **Define Columns** with proper data types
5. **Set Primary Keys** (🔑 icon)
6. **Create Relationships** using connection tools
7. **Specify Cardinality** (1:1, 1:N, N:M)

### Forward Engineering:
1. **Database → Forward Engineer**
2. Review generated SQL
3. Execute on target database
4. Save .mwb file

### Common Data Types:
- `INT` - Integer numbers
- `VARCHAR(n)` - Variable-length strings
- `TEXT` - Large text
- `DECIMAL(p,s)` - Fixed-point numbers
- `DATE` - Date values
- `DATETIME` - Date and time
- `ENUM('val1','val2')` - Enumerated list

---

## 🚀 Performance Optimization Strategies

### 1. Query Optimization
```sql
-- Use EXPLAIN to analyze queries
EXPLAIN SELECT * FROM table WHERE condition;

-- Look for:
-- - type: ALL (bad), index, range, ref (good)
-- - rows: Number of rows examined
-- - Extra: Using filesort, Using temporary (avoid)
```

### 2. Indexing Strategy
```sql
-- Index frequently searched columns
CREATE INDEX idx_email ON users(email);

-- Composite indexes for multi-column searches
CREATE INDEX idx_name_date ON orders(customer_id, order_date);

-- Check index usage
SHOW INDEX FROM table_name;
```

### 3. Query Writing Tips
- **Use specific columns** instead of `SELECT *`
- **Limit result sets** with WHERE clauses
- **Use JOINs** instead of subqueries when possible
- **Avoid functions** on indexed columns in WHERE
- **Use LIMIT** to restrict result size

### 4. Database Design
- **Normalize appropriately** (usually 3NF)
- **Use appropriate data types** (smallest sufficient)
- **Avoid NULL** when possible
- **Partition large tables** if needed

---

## 📝 Report Writing Guide

### Structure:

#### 1. Introduction
- System overview
- Objectives
- Scope

#### 2. Database Design
- ERD with explanations
- Entity descriptions
- Relationship cardinalities

#### 3. Normalization Analysis
- Original unnormalized form
- Step-by-step normalization (1NF → 2NF → 3NF)
- Justification for final schema

#### 4. Implementation Details
- Table structures
- Constraints applied
- Sample data insertion

#### 5. Triggers and Procedures
- Purpose of each trigger
- Stored procedure logic
- Function implementations

#### 6. Performance Optimization
- Indexes created
- EXPLAIN analysis results
- Before/after performance metrics

#### 7. Transaction Control
- ACID compliance demonstration
- Isolation level testing
- Concurrency handling

#### 8. Testing Results
- Query outputs
- Trigger verification
- Edge cases tested

#### 9. Challenges and Solutions
- Problems encountered
- Resolution strategies

#### 10. Conclusion
- Achievements
- Lessons learned
- Future improvements

---

## ✅ Pre-Presentation Checklist

- [ ] All .mwb files saved and tested
- [ ] SQL scripts run without errors
- [ ] Sample data inserted successfully
- [ ] All queries produce expected results
- [ ] Triggers fire correctly
- [ ] Stored procedures execute properly
- [ ] Views display accurate data
- [ ] Performance metrics documented
- [ ] Report formatted professionally
- [ ] Code properly commented
- [ ] Team roles assigned for presentation
- [ ] Backup copies of all files

---

## 🎓 Presentation Tips

1. **Start with ERD** - Visual overview of your design
2. **Explain normalization** - Show your reasoning
3. **Demo live queries** - Run important queries
4. **Show trigger actions** - Insert/update to demonstrate
5. **Display performance** - EXPLAIN results
6. **Handle questions** - Know your code deeply
7. **Time management** - Practice beforehand
8. **Team coordination** - Each member presents a section

---

## 🔧 Useful MySQL Commands

```sql
-- Database Management
SHOW DATABASES;
USE database_name;
SHOW TABLES;
DESCRIBE table_name;

-- Viewing Data
SELECT * FROM table_name LIMIT 10;
SHOW CREATE TABLE table_name;

-- Index Information
SHOW INDEX FROM table_name;

-- Trigger Information
SHOW TRIGGERS;
SHOW CREATE TRIGGER trigger_name;

-- Procedure Information
SHOW PROCEDURE STATUS;
SHOW CREATE PROCEDURE proc_name;

-- Performance
SHOW PROCESSLIST;
SHOW STATUS;
ANALYZE TABLE table_name;

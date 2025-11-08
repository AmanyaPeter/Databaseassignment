-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema Lab_1
-- -----------------------------------------------------
-- 
-- 
-- 

-- -----------------------------------------------------
-- Schema Lab_1
--
-- 
-- 
-- 
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `Lab_1` ;
USE `Lab_1` ;

-- -----------------------------------------------------
-- Table `Lab_1`.`Students`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lab_1`.`Students` (
  `student_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(45) NOT NULL,
  `last_name` VARCHAR(45) NULL,
  `email` VARCHAR(45) NULL,
  `date_of_birth` DATE NULL,
  PRIMARY KEY (`student_id`),
  UNIQUE INDEX `email_UNIQUE` (`email` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Lab_1`.`Lecturers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lab_1`.`Lecturers` (
  `lecturer_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(45) NULL,
  `last_name` VARCHAR(45) NULL,
  `email` VARCHAR(45) NOT NULL,
  `department` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`lecturer_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Lab_1`.`Courses`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lab_1`.`Courses` (
  `course_id` INT NOT NULL AUTO_INCREMENT,
  `course_name` VARCHAR(45) NOT NULL,
  `credit_units` INT NOT NULL,
  `lecturer_id` INT NOT NULL,
  PRIMARY KEY (`course_id`),
  INDEX `lecturer_id_idx` (`lecturer_id` ASC) VISIBLE,
  CONSTRAINT `lecturer_id`
    FOREIGN KEY (`lecturer_id`)
    REFERENCES `Lab_1`.`Lecturers` (`lecturer_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Lab_1`.`Enrollments`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Lab_1`.`Enrollments` (
  `enrollment_id` INT NOT NULL AUTO_INCREMENT,
  `student_id` INT NOT NULL,
  `course_id` INT NOT NULL,
  `enrollment_date` DATE NULL,
  PRIMARY KEY (`enrollment_id`),
  INDEX `student_id_idx` (`student_id` ASC) VISIBLE,
  INDEX `course_id_idx` (`course_id` ASC) VISIBLE,
  CONSTRAINT `student_id`
    FOREIGN KEY (`student_id`)
    REFERENCES `Lab_1`.`Students` (`student_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `course_id`
    FOREIGN KEY (`course_id`)
    REFERENCES `Lab_1`.`Courses` (`course_id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;


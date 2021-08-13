SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `test1` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `test1` ;

-- -----------------------------------------------------
-- Table `test1`.`Ingredients`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Ingredients` (
  `Typical_Ingredients_ID` VARCHAR(10) ,
  `Typical_Ingredients` VARCHAR(45) ,
  PRIMARY KEY (`Typical_Ingredients_ID`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Classification`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Classification` (
  `Classification_id` VARCHAR(6) ,
  `Classification_Name` VARCHAR(10) ,
  PRIMARY KEY (`Classification_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Medicine`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Medicine` (
  `Medicine_id` VARCHAR(15) ,
  `Medicine_Name` VARCHAR(45) ,
  `Medicine_Shape` VARCHAR(45) ,
  `Frequency_Per_Use` INT(1) NULL,
  `NIC` DOUBLE ,
  `Actual_Cost` DOUBLE ,
  `Typical_Ingredients_ID` VARCHAR(10) ,
  `Classification_id` VARCHAR(6) ,
  PRIMARY KEY (`Medicine_id`),
  INDEX `fk_Medicine_Ingredients1_idx` (`Typical_Ingredients_ID` ASC),
  INDEX `fk_Medicine_Classification1_idx` (`Classification_id` ASC),
  CONSTRAINT `fk_Medicine_Ingredients1`
    FOREIGN KEY (`Typical_Ingredients_ID`)
    REFERENCES `test1`.`Ingredients` (`Typical_Ingredients_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Medicine_Classification1`
    FOREIGN KEY (`Classification_id`)
    REFERENCES `test1`.`Classification` (`Classification_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Patient`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Patient` (
  `Patient_id` INT ,
  `Full_Name` VARCHAR(45),
  `Birthday` DATE ,
  `Low_Income` TINYINT(1),
  `Full-Time_Education` TINYINT(1),
  `Mean-Testing` TINYINT(1) ,
  `MatEx` TINYINT(1),
  `NHS_TaxCreditExemption` TINYINT(1),
  `Pension_Credits` TINYINT(1) ,
  `MedEx` TINYINT(1) ,
  `User_Name` VARCHAR(8) ,
  `Password` VARCHAR(200),
  `Card_Number` BINARY,
  `Citizenship` VARCHAR(45),
  `Token` VARCHAR(100),
  `Token_limit` VARCHAR(40),
  PRIMARY KEY (`Patient_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Station`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Station` (
  `Station_id` INT ,
  `Name` VARCHAR(45) ,
  `Address` VARCHAR(45) ,
  `PostCode` VARCHAR(45) ,
  `Longitude` DECIMAL(10,8) ,
  `Latitude` DECIMAL(11,8) ,
  PRIMARY KEY (`Station_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Pharmacy`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Pharmacy` (
  `Pharmacy_id` INT ,
  `Pharmacy_Name` VARCHAR(45) ,
  `Contact_Number` INT ,
  `Pharmacy_Address` VARCHAR(45) ,
  `PostCode` INT ,
  `Region` VARCHAR(45) ,
  `Longitude` DECIMAL(10,8) ,
  `Latitude` DECIMAL(11,8) ,
  PRIMARY KEY (`Pharmacy_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Prescription`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Prescription` (
  `Prescription_id` VARCHAR(45) ,
  `Date` VARCHAR(20) ,
  `Collection_Date` VARCHAR(20) ,
  `Total_Frequency` INT ,
  `Patient_id` INT ,
  `Medicine_id` VARCHAR(15) ,
  `Pharmacy_id` INT ,
  INDEX `fk_Prescription_Patient_idx` (`Patient_id` ASC),
  INDEX `fk_Prescription_Medicine1_idx` (`Medicine_id` ASC),
  INDEX `fk_Prescription_Pharmacy1_idx` (`Pharmacy_id` ASC),
  PRIMARY KEY (`Prescription_id`),
  CONSTRAINT `fk_Prescription_Patient`
    FOREIGN KEY (`Patient_id`)
    REFERENCES `test1`.`Patient` (`Patient_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Prescription_Medicine1`
    FOREIGN KEY (`Medicine_id`)
    REFERENCES `test1`.`Medicine` (`Medicine_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Prescription_Pharmacy1`
    FOREIGN KEY (`Pharmacy_id`)
    REFERENCES `test1`.`Pharmacy` (`Pharmacy_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`VendingMachine`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`VendingMachine` (
  `Machine_id` INT ,
  `PIC_Contact` INT ,
  `Station_id` INT ,
  PRIMARY KEY (`Machine_id`),
  INDEX `fk_VendingMachine_Station1_idx` (`Station_id` ASC),
  CONSTRAINT `fk_VendingMachine_Station1`
    FOREIGN KEY (`Station_id`)
    REFERENCES `test1`.`Station` (`Station_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Medicine_has_VendingMachine`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Medicine_has_VendingMachine` (
  `Medine_VendingMachine_id` INT ,
  `Medicine_Quantity` INT ,
  `Medicine_Threshold` INT ,
  `Amt_Dispensed` INT,
  `Medicine_id` VARCHAR(15) ,
  `Machine_id` INT ,
  INDEX `fk_Medicine_has_VendingMachine_VendingMachine1_idx` (`Machine_id` ASC),
  INDEX `fk_Medicine_has_VendingMachine_Medicine1_idx` (`Medicine_id` ASC),
  PRIMARY KEY (`Medine_VendingMachine_id`),
  CONSTRAINT `fk_Medicine_has_VendingMachine_Medicine1`
    FOREIGN KEY (`Medicine_id`)
    REFERENCES `test1`.`Medicine` (`Medicine_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Medicine_has_VendingMachine_VendingMachine1`
    FOREIGN KEY (`Machine_id`)
    REFERENCES `test1`.`VendingMachine` (`Machine_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Pharmacy_has_Station`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Pharmacy_has_Station` (
  `Pharmacy_id` INT ,
  `Station_id` INT ,
  `Distance_to_Station` DECIMAL ,
  INDEX `fk_Pharmacy_has_Station_Station1_idx` (`Station_id` ASC),
  INDEX `fk_Pharmacy_has_Station_Pharmacy1_idx` (`Pharmacy_id` ASC),
  PRIMARY KEY (`Pharmacy_id`),
  CONSTRAINT `fk_Pharmacy_has_Station_Pharmacy1`
    FOREIGN KEY (`Pharmacy_id`)
    REFERENCES `test1`.`Pharmacy` (`Pharmacy_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Pharmacy_has_Station_Station1`
    FOREIGN KEY (`Station_id`)
    REFERENCES `test1`.`Station` (`Station_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `test1`.`Payment_Info`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Payment_Info` (
  `Payment_id` INT ,
  `Cost` DOUBLE ,
  `Payment_Made` TINYINT(1) ,
  `Merchant_payment_id` VARCHAR(20),
  `Payment_Mode` ENUM('Credit Card','PayLah') ,
  `Patient_id` INT ,
  `Machine_id` INT ,
  INDEX `fk_Patient_has_VendingMachine_VendingMachine1_idx` (`Machine_id` ASC),
  INDEX `fk_Patient_has_VendingMachine_Patient1_idx` (`Patient_id` ASC),
  PRIMARY KEY (`Payment_id`),
  CONSTRAINT `fk_Patient_has_VendingMachine_Patient1`
    FOREIGN KEY (`Patient_id`)
    REFERENCES `test1`.`Patient` (`Patient_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Patient_has_VendingMachine_VendingMachine1`
    FOREIGN KEY (`Machine_id`)
    REFERENCES `test1`.`VendingMachine` (`Machine_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `test1`.`Admin`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `test1`.`Admin` (
  `admin_id` INT AUTO_INCREMENT,
  `username` VARCHAR(45),
  `password` VARCHAR(200),
  PRIMARY KEY (`admin_id`)
)
ENGINE = InnoDB;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- test data
INSERT INTO Admin(username,password) VALUES('test', '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08');


INSERT INTO Ingredients(Typical_Ingredients_ID,Typical_Ingredients) VALUES('1', 'Harb');
INSERT INTO Classification(Classification_id, Classification_Name) VALUES('1', 'headache');
INSERT INTO Medicine(Medicine_id,Medicine_Name,Medicine_Shape,Actual_Cost,Typical_Ingredients_ID,Classification_id) VALUES('1','LULU','tablet',20.1,'1','1');

INSERT INTO Pharmacy(Pharmacy_id, Pharmacy_name) VALUES(1, 'Biggest Pharmacy');
INSERT INTO Station(Station_id,Name,Address,PostCode,Longitude,Latitude) VALUES (1, 'Central Station', 'Tokyo', '987-6543', 12.3456,5.453215);
INSERT INTO Pharmacy_has_Station(Pharmacy_id,Station_id,Distance_to_Station) VALUES(1,1,0.5);

INSERT INTO VendingMachine(Machine_id,Station_id) VALUES(1,1);
INSERT INTO Medicine_has_VendingMachine(Medine_VendingMachine_id,Medicine_Quantity,Medicine_id,Machine_id) VALUES(1,12,1,1);


-- INSERT INTO Payment_Info(Payment_id,Cost,Payment_Made,Patient_id, Machine_id) VALUES(1,35,);
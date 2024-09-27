-- Drop existing tables
DROP TABLE IF EXISTS TICKET;
DROP TABLE IF EXISTS VEHICLE;
DROP TABLE IF EXISTS REQUEST;
DROP TABLE IF EXISTS CUSTOMER;
DROP TABLE IF EXISTS PARKING_SLOT;

-- Drop existing sequences
DROP SEQUENCE IF EXISTS TICKET_SEQ;
DROP SEQUENCE IF EXISTS REQUEST_SEQ;
DROP SEQUENCE IF EXISTS CUSTOMER_SEQ;
DROP SEQUENCE IF EXISTS PARKING_SLOT_SEQ;

-- Create sequences
CREATE SEQUENCE PARKING_SLOT_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE CUSTOMER_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE REQUEST_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE TICKET_SEQ START WITH 1 INCREMENT BY 1;
-- Create PARKING_SLOT table
CREATE TABLE PARKING_SLOT (
    PSID INT PRIMARY KEY,
    TotalSlots INT,
    AvailableSlots INT,
    Location VARCHAR(100),
    VehicleType VARCHAR(20), 
    Revenue DECIMAL(10,2)
);
-- Create CUSTOMER table
CREATE TABLE CUSTOMER (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100),
    PhoneNumber VARCHAR(15),
    Email VARCHAR(100),
    Address VARCHAR(255)
);
-- Create REQUEST table
CREATE TABLE REQUEST (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    NeedStartTime TIMESTAMP,
    NeedEndTime TIMESTAMP,
    Location VARCHAR(100),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
);

-- Create VEHICLE table
CREATE TABLE VEHICLE (
    CustomerID int,
    VNumber VARCHAR2(20) PRIMARY KEY,
    VType VARCHAR2(20),
    VName VARCHAR2(100),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
);
-- Create TICKET table
CREATE TABLE TICKET (
    TicketID INT PRIMARY KEY,
    CustomerName VARCHAR2(100),
    VehicleNumber VARCHAR2(20),
    PSID INT,
    Location VARCHAR2(100),
    StartTime TIMESTAMP,
    EndTime TIMESTAMP,
    Fare DECIMAL(10,2)
);

-- Create procedure Addparkingslot
CREATE OR REPLACE PROCEDURE AddParkingSlot(
    TotalSlots INT,
    AvailableSlots INT,
    Location VARCHAR2,
    VehicleType VARCHAR2
)
AS
BEGIN
    INSERT INTO PARKING_SLOT (PSID, TotalSlots, AvailableSlots, Location, VehicleType, Revenue)
    VALUES (PARKING_SLOT_SEQ.NEXTVAL, TotalSlots, AvailableSlots, Location, upper(VehicleType), 0);
END;
/

-- Create procedure AddCustomer
CREATE OR REPLACE PROCEDURE AddCustomer(
    Name VARCHAR2,
    PhoneNumber VARCHAR2,
    Email VARCHAR2,
    Address VARCHAR2
)
AS
BEGIN
    INSERT INTO CUSTOMER (CustomerID, Name, PhoneNumber, Email, Address)
    VALUES (CUSTOMER_SEQ.NEXTVAL, Name, PhoneNumber, Email, Address);
END;
/

-- Create procedure AddVehicle
CREATE OR REPLACE PROCEDURE AddVehicle(
    CustomerID int,
    VNumber VARCHAR2,
    VType VARCHAR2,
    VName VARCHAR2
)
AS
BEGIN
    INSERT INTO VEHICLE (CustomerID,VNumber, VType, VName) VALUES (CustomerID,upper(VNumber), upper(VType), upper(VName));
END;
/

-- Create procedure Addparkingslot with exception handling
CREATE OR REPLACE PROCEDURE AddParkingSlot(
    TotalSlots INT,
    AvailableSlots INT,
    Location VARCHAR2,
    VehicleType VARCHAR2
)
AS
BEGIN
    INSERT INTO PARKING_SLOT (PSID, TotalSlots, AvailableSlots, Location, VehicleType, Revenue)
    VALUES (PARKING_SLOT_SEQ.NEXTVAL, TotalSlots, AvailableSlots, Location, upper(VehicleType), 0);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while adding parking slot: ' || SQLERRM);
END;
/

-- Create procedure AddCustomer with exception handling
CREATE OR REPLACE PROCEDURE AddCustomer(
    Name VARCHAR2,
    PhoneNumber VARCHAR2,
    Email VARCHAR2,
    Address VARCHAR2
)
AS
BEGIN
    INSERT INTO CUSTOMER (CustomerID, Name, PhoneNumber, Email, Address)
    VALUES (CUSTOMER_SEQ.NEXTVAL, Name, PhoneNumber, Email, Address);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while adding customer: ' || SQLERRM);
END;
/

-- Create procedure AddVehicle with exception handling
CREATE OR REPLACE PROCEDURE AddVehicle(
    CustomerID int,
    VNumber VARCHAR2,
    VType VARCHAR2,
    VName VARCHAR2
)
AS
BEGIN
    INSERT INTO VEHICLE (CustomerID,VNumber, VType, VName) VALUES (CustomerID,upper(VNumber), upper(VType), upper(VName));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while adding vehicle: ' || SQLERRM);
END;
/
CREATE OR REPLACE PROCEDURE CreateRequest(
    ReqCustomerID INT,
    VNumber VARCHAR2,
    NeedStartTime TIMESTAMP,
    NeedEndTime TIMESTAMP,
    ReqLocation VARCHAR2
)
AS
    cusname VARCHAR2(100);
    vnum VARCHAR2(20);
    vtype VARCHAR2(20);
    psid INT;
    DurationInHours DECIMAL(10, 2);
    Fare DECIMAL(10,2);
    v_found INT := 0; -- Change the data type to INT and initialize to 0

    -- Declare cursor for customer and vehicle details
    CURSOR customer_cursor IS
        SELECT c.Name, v.VNumber, v.VType
        FROM CUSTOMER c
        JOIN VEHICLE v ON c.CustomerID = v.CustomerID
        WHERE c.CustomerID = ReqCustomerID;

    -- Declare cursor for PSID retrieval
    CURSOR psid_cursor IS
        SELECT PSID
        FROM PARKING_SLOT
        WHERE Location = ReqLocation AND VehicleType = vtype;
BEGIN
    -- Check if the vehicle number exists in the VEHICLE table
    SELECT COUNT(*) INTO v_found
    FROM VEHICLE
    WHERE VNumber = VNumber;


    -- Fetch customer and vehicle details
    OPEN customer_cursor;
    FETCH customer_cursor INTO cusname, vnum, vtype;
    CLOSE customer_cursor;

    -- Check if customer exists, if not, add new customer
    IF cusname IS NULL THEN
        BEGIN
            AddCustomer('shivansh', '9895575', 'shiva@gmail.com', 'shamli');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error adding customer. ' || SQLERRM);
        END;
    END IF;

    -- Fetch PSID using nested cursor
    LOOP
        BEGIN
            FETCH psid_cursor INTO psid;
            EXIT WHEN psid_cursor%NOTFOUND; -- Exit loop if no more rows to fetch

            -- Calculate fare
            Fare := (EXTRACT(HOUR FROM (NeedEndTime - NeedStartTime)) * 50);
        
            -- Update available slots and revenue
            UPDATE PARKING_SLOT
            SET AvailableSlots = AvailableSlots - 1, Revenue = Revenue + Fare
            WHERE PSID = psid AND Location = ReqLocation AND VehicleType = vtype;
        
            -- Insert ticket
            INSERT INTO TICKET (TicketID, CustomerName, VehicleNumber, PSID, Location, StartTime, EndTime, Fare)
            VALUES (TICKET_SEQ.NEXTVAL, cusname, UPPER(VNumber), psid, ReqLocation, NeedStartTime, NeedEndTime, Fare);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error processing request. ' || SQLERRM);
        END;
    END LOOP;
END;
/


CREATE OR REPLACE PROCEDURE TicketPrintProcedure
AS
    -- -- Declare cursor for ticket details
    -- CURSOR ticket_cursor IS
    --     SELECT t.TicketID, t.CustomerName, t.VehicleNumber, t.PSID, t.Location, t.StartTime, t.EndTime, t.Fare
    --     FROM TICKET t
    --     JOIN PARKING_SLOT ps ON t.PSID = ps.PSID
    --     JOIN VEHICLE v ON t.VehicleNumber = v.VNumber
    --     WHERE t.Location = ps.Location AND t.VehicleNumber = v.VNumber;
BEGIN
    -- Open cursor
    FOR ticket_rec IN ticket_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Ticket ID: ' || ticket_rec.TicketID);
        DBMS_OUTPUT.PUT_LINE('Customer Name: ' || ticket_rec.CustomerName);
        DBMS_OUTPUT.PUT_LINE('Vehicle Number: ' || ticket_rec.VehicleNumber);
        DBMS_OUTPUT.PUT_LINE('PSID: ' || ticket_rec.PSID);
        DBMS_OUTPUT.PUT_LINE('Location: ' || ticket_rec.Location);
        DBMS_OUTPUT.PUT_LINE('Start Time: ' || TO_CHAR(ticket_rec.StartTime, 'DD-MON-YYYY HH:MI:SS AM'));
        DBMS_OUTPUT.PUT_LINE('End Time: ' || TO_CHAR(ticket_rec.EndTime, 'DD-MON-YYYY HH:MI:SS AM'));
        DBMS_OUTPUT.PUT_LINE('Fare: ' || ticket_rec.Fare);
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while printing tickets: ' || SQLERRM);
END;
/


-- Create a package to hold the variable
CREATE OR REPLACE PACKAGE TicketCounterPackage AS
    TicketCount INT := 0;
END TicketCounterPackage;
/

-- Create a trigger to count the number of tickets inserted
CREATE OR REPLACE TRIGGER TicketInsertTrigger
AFTER INSERT ON TICKET
FOR EACH ROW
BEGIN
    -- Increment the ticket count
    TicketCounterPackage.TicketCount := TicketCounterPackage.TicketCount + 1;
END;
/
CREATE OR REPLACE TRIGGER PrintVehicleType
AFTER INSERT ON TICKET
FOR EACH ROW
DECLARE
    v_VehicleType VARCHAR2(20);
BEGIN
    -- Retrieve the vehicle type for the newly inserted ticket
    SELECT VType INTO v_VehicleType
    FROM VEHICLE
    WHERE VNumber = :NEW.VehicleNumber;

    -- If vehicle type is found, print it
    IF v_VehicleType IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Vehicle Type: ' || v_VehicleType);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Vehicle type not found for ticket.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Vehicle type not found for ticket.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/


BEGIN
-- Call AddParkingSlot procedure to insert 5 values
AddParkingSlot(50, 50, 'Location1', 'Car');
AddParkingSlot(50, 50, 'Location2', 'Car');
AddParkingSlot(30, 30, 'Location3', 'Bike');
AddParkingSlot(30, 30, 'Location4', 'Bike');
AddParkingSlot(40, 40, 'Location5', 'Van');

END;
/
-- Call AddCustomer procedure to insert 20 values
BEGIN
    AddCustomer('Rahul Kumar', '1234567890', 'rahul@example.com', '12, Gali No. 5, Patel Nagar, Delhi');
    AddCustomer('Pooja Sharma', '9876543210', 'pooja@example.com', 'C-34, Sector 22, Noida');
    AddCustomer('Amit Singh', '5551234567', 'amit@example.com', 'Flat No. 102, Ganesh Apartments, Mumbai');
    AddCustomer('Priya Patel', '5559876543', 'priya@example.com', 'B-21, Green Park, Bangalore');
    AddCustomer('Rajesh Gupta', '4441234567', 'rajesh@example.com', 'H. No. 304, Model Town, Ludhiana');
    AddCustomer('Anjali Dubey', '7778889999', 'anjali@example.com', '27/3, Civil Lines, Jaipur');
    AddCustomer('Rohit Verma', '3332221111', 'rohit@example.com', 'Flat No. 402, Krishna Tower, Pune');
    AddCustomer('Sunita Yadav', '1112223333', 'sunita@example.com', 'B-14, Vivek Vihar, Kanpur');
    AddCustomer('Vikas Rajput', '9998887777', 'vikas@example.com', 'A-56, Shastri Nagar, Lucknow');
    AddCustomer('Sneha Sharma', '8887776666', 'sneha@example.com', 'D-12, Rajendra Nagar, Patna');
    AddCustomer('Nitin Mishra', '7776665555', 'nitin@example.com', 'G-2, Kamla Nagar, Bhopal');
    AddCustomer('Ritu Gupta', '6665554444', 'ritu@example.com', 'Flat No. 503, Sapphire Apartments, Ahmedabad');
    AddCustomer('Vishal Singh', '5554443333', 'vishal@example.com', 'C-23, Rama Krishna Nagar, Chennai');
    AddCustomer('Kavita Verma', '4443332222', 'kavita@example.com', 'H. No. 402, Shyam Vihar, Gurgaon');
    AddCustomer('Rajat Sharma', '3332221111', 'rajat@example.com', '54, Ashoka Enclave, Faridabad');
    AddCustomer('Deepak Yadav', '2221110000', 'deepak@example.com', 'Flat No. 103, DLF Phase-2, Gurugram');
    AddCustomer('Anita Gupta', '1110009999', 'anita@example.com', 'A-12, Kailash Hills, Delhi');
    AddCustomer('Raj Kumar', '0009998888', 'raj@example.com', '23, Shakti Nagar, Jaipur');
    AddCustomer('Meena Devi', '9998887777', 'meena@example.com', '101, Gandhi Nagar, Lucknow');
    AddCustomer('Sanjay Kumar', '8887776666', 'sanjay@example.com', 'G-34, Sector 18, Noida');
END;
/
BEGIN
    AddVehicle(1, 'DL5S1234', 'Car', 'Maruti Suzuki Swift');
    AddVehicle(2, 'DL5S3235', 'Bike', 'Honda Activa');
    AddVehicle(3, 'MH12AB1234', 'Car', 'Hyundai i20');
    AddVehicle(4, 'MH12AB1235', 'Van', 'Tata Ace');
    AddVehicle(5, 'KA02EF1234', 'Car', 'Toyota Innova');
    AddVehicle(6, 'DL5S3234', 'Bike', 'Royal Enfield Classic 350');
    AddVehicle(7, 'DL5S1274', 'Van', 'Mahindra Bolero');
    AddVehicle(8, 'MH12AB1236', 'Car', 'Ford EcoSport');
    AddVehicle(9, 'RJ19MN1234', 'Bike', 'Bajaj Pulsar 150');
    AddVehicle(10, 'RJ20OP5678', 'Car', 'Honda City');
    AddVehicle(11, 'MP21QR1234', 'Van', 'Ashok Leyland Dost');
    AddVehicle(12, 'MP22ST5678', 'Car', 'Volkswagen Polo');
    AddVehicle(13, 'TN23UV1234', 'Bike', 'TVS Apache RTR 160');
    AddVehicle(14, 'TN24WX5678', 'Van', 'Force Traveller');
    AddVehicle(15, 'DL25YZ1234', 'Car', 'Renault Kwid');
    AddVehicle(16, 'DL26AB5678', 'Bike', 'Hero Splendor Plus');
    AddVehicle(17, 'MH27CD1234', 'Van', 'Mahindra Scorpio');
    AddVehicle(18, 'MH28EF5678', 'Car', 'Chevrolet Beat');
    AddVehicle(19, 'KA29GH1234', 'Bike', 'Yamaha FZS V3');
    AddVehicle(20, 'KA30IJ5678', 'Car', 'Skoda Rapid');
END;
/
    SET SERVEROUTPUT ON;
BEGIN
    CreateRequest(1, 'DL5S1234', TO_TIMESTAMP('2024-05-04 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-04 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location1');
    CreateRequest(2, 'DL5S3235', TO_TIMESTAMP('2024-05-05 09:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-05 13:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location2');
    CreateRequest(3, 'MH12AB1234', TO_TIMESTAMP('2024-05-06 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-06 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location3');
    CreateRequest(4, 'MH12AB1235', TO_TIMESTAMP('2024-05-07 08:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-07 12:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location4');
    CreateRequest(5, 'KA02EF1234', TO_TIMESTAMP('2024-05-08 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-08 14:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location5');
    CreateRequest(6, 'DL5S3234', TO_TIMESTAMP('2024-05-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-09 13:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location1');
    CreateRequest(7, 'DL5S1274', TO_TIMESTAMP('2024-05-10 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-10 14:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location2');
    CreateRequest(8, 'MH12AB1236', TO_TIMESTAMP('2024-05-11 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-11 12:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location3');
    CreateRequest(9, 'MH12AB1237', TO_TIMESTAMP('2024-05-12 11:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-12 15:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location4');
    CreateRequest(10, 'KA02EF1234', TO_TIMESTAMP('2024-05-13 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-13 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location5');
    CreateRequest(11, 'DL5S5234', TO_TIMESTAMP('2024-05-14 08:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-14 12:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location1');
    CreateRequest(12, 'DL5S8934', TO_TIMESTAMP('2024-05-15 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-15 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location2');
    CreateRequest(13, 'MH12AB1239', TO_TIMESTAMP('2024-05-16 09:15:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-16 13:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location3');
    CreateRequest(14, 'MH12AB1238', TO_TIMESTAMP('2024-05-17 10:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-17 14:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location4');
    CreateRequest(15, 'KA02EF1234', TO_TIMESTAMP('2024-05-18 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-18 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location5');
    CreateRequest(16, 'DL5S1232', TO_TIMESTAMP('2024-05-19 09:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-19 13:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location1');
    CreateRequest(17, 'DL5S1838', TO_TIMESTAMP('2024-05-20 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-20 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location2');
    CreateRequest(18, 'MH12AB3236', TO_TIMESTAMP('2024-05-21 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-21 14:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location3');
    CreateRequest(19, 'MH12AB2237', TO_TIMESTAMP('2024-05-22 08:30:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-22 12:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location4');
    CreateRequest(20, 'KA02EF1234', TO_TIMESTAMP('2024-05-23 11:45:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2024-05-23 15:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Location5');
END;
/


    
select * from PARKING_SLOT;
select * from CUSTOMER;
select * from VEHICLE;
select * from REQUEST;
select * from TICKET;
BEGIN
    TicketPrintProcedure;
END;
/
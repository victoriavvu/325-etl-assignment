--MIS 325 HW 8
--Victoria Vu
--vtv244

--Question 1
--The customer and customer_acquisition don't completely have the same fields,
--however, they have fields that share common types of data such as customer_id,
--first_name, last_name, email, phone, and zip. This can be fixed in the  
--customer_dw table to merge the data together under consistency.

--Question 2
CREATE TABLE customer_dw(
    data_source             char(4),
    customer_id             number,
    first_name              varchar(100),
    last_name               varchar(100),
    email                   varchar(100),
    phone                   char(12),
    zip                     char(5),
    credits_earned          number,
    credits_used            number,     
    CONSTRAINT id_source_pk primary key (data_source, customer_id)
);

DROP TABLE customer_dw;
SELECT * FROM customer_dw;

--Question 3
CREATE OR REPLACE VIEW customer_acquisition_view AS
    SELECT 'AQUI' as data_source, acquired_customer_id, 
    CA_first_name, CA_last_name, CA_email,
    SUBSTR(CA_phone,2,3) || '-' || SUBSTR(CA_phone,6,8) as phone, CA_zip_code, 
    0 as credits_used, CA_credits_remaining/2 as credits_earned
    FROM customer_acquisition;

CREATE OR REPLACE VIEW customer_view AS
    SELECT 'CUST' as data_source, customer_id, first_name, last_name, email, phone, zip,
    stay_credits_earned as credits_earned, stay_credits_used as credits_used
    FROM customer;

DROP VIEW customer_acquisition_view;
DROP VIEW customer_view;

SELECT * FROM customer_acquisition_view;
SELECT * FROM customer_view;

--Question 6
CREATE OR REPLACE PROCEDURE customer_etl_proc
AS
BEGIN
--Question 4 insert statements
    INSERT INTO customer_dw (data_source, customer_id, first_name, last_name, email,
    phone, zip, credits_earned, credits_used)
        select 'AQUI' as data_source, cav.acquired_customer_id, cav.CA_first_name,
        cav.CA_last_name, cav.CA_email, cav.phone, cav.CA_zip_code,
        cav.credits_earned, cav.credits_used
        FROM customer_acquisition_view cav LEFT JOIN customer_dw dw
        ON cav.acquired_customer_id = dw.customer_id
        AND cav.data_source = dw.data_source
        WHERE dw.customer_id IS NULL;
    
    INSERT INTO customer_dw (data_source, customer_id, first_name, last_name, email,
    phone, zip, credits_earned, credits_used)
        SELECT 'CUST' as data_source, cv.customer_id, cv.first_name, cv.last_name,
        cv.email, cv.phone, cv.zip, cv.credits_earned, cv.credits_used
        FROM customer_view cv LEFT JOIN customer_dw dw
        ON cv.customer_id = dw.customer_id
        AND cv.data_source = dw.data_source
        WHERE dw.customer_id IS NULL;
--Question 5 merge statements
    MERGE INTO customer_dw dw
    USING customer_acquisition_view cav
    ON (dw.customer_id = cav.acquired_customer_id AND dw.data_source = 'AQUI')
    WHEN MATCHED THEN
      UPDATE SET    dw.first_name = cav.CA_first_name,
                    dw.last_name = cav.CA_last_name,
                    dw.email = cav.CA_email,
                    dw.phone = cav.phone,
                    dw.zip = cav.CA_zip_code,
                    dw.credits_earned = cav.credits_earned,
                    dw.credits_used = cav.credits_used;
                    
    MERGE INTO customer_dw dw
        USING customer_view cv
        ON (dw.customer_id = cv.customer_id AND dw.data_source = 'CUST')
    WHEN MATCHED THEN
      UPDATE SET    dw.first_name = cv.first_name,
                    dw.last_name = cv.last_name,
                    dw.email = cv.email,
                    dw.phone = cv.phone,
                    dw.zip = cv.zip,
                    dw.credits_earned = cv.credits_earned,
                    dw.credits_used = cv.credits_used;

END;
/

DROP PROCEDURE customer_etl_proc;
CALL customer_etl_proc();


--tests
drop table customer_dw;
drop view customer_view;
drop view customer_acquisition_view;
drop procedure customer_etl_proc;

insert into customer(first_name, last_name, email, phone, address_line_1, city, state, zip)
values ('victoria','vu','victoria@gmail.com',777-777-7777,'123 street','austin','tx','22441');

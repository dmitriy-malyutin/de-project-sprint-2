--1.1 Создание справочника стоимости доставки в страны
DROP TABLE IF EXISTS shipping_country_rates CASCADE;

CREATE TABLE shipping_country_rates
(
id               			serial       PRIMARY KEY,
shipping_country      		TEXT,
shipping_country_base_rate  numeric(14,2)
);

--2.1 Создание справочника тарифов доставки вендора по договору
DROP TABLE IF EXISTS shipping_agreement CASCADE;


CREATE TABLE shipping_agreement 
(
agreement_id 		BIGINT 			PRIMARY KEY,
agreement_number 	TEXT,
agreement_rate 		NUMERIC,
agreement_comission NUMERIC
);

--3.1 Создание справочника о типах доставки shipping_transfer
DROP TABLE IF EXISTS shipping_transfer;

CREATE TABLE shipping_transfer
(
id 						serial 			PRIMARY KEY,
transfer_type 			TEXT,
transfer_model 			TEXT,
shipping_transfer_rate 	NUMERIC(4, 3) 
);

--4.1 Создание справочника комиссий по странам с уникальными доставками
DROP TABLE IF EXISTS shipping_info CASCADE;

CREATE TABLE shipping_info
(
shipping_id 			BIGINT 		PRIMARY KEY,
country_id 				BIGINT,
agreement_id 			BIGINT,
transfer_id 			BIGINT,
shipping_plan_datetime 	TIMESTAMP,
payment_amount 			NUMERIC(14,2),
vendor_id 				BIGINT,
FOREIGN KEY (country_id) REFERENCES shipping_country_rates(id) ON UPDATE CASCADE,
FOREIGN KEY (agreement_id) REFERENCES shipping_agreement(agreement_id) ON UPDATE CASCADE,
FOREIGN KEY (transfer_id) REFERENCES shipping_transfer(id) ON UPDATE CASCADE
);

--5.1 Создание таблицы статусов о доставке shipping_status
DROP TABLE IF EXISTS shipping_status;

CREATE TABLE shipping_status
(
shipping_id 					BIGINT PRIMARY KEY,
status 							TEXT,
state 							TEXT,
shipping_start_fact_datetime 	TIMESTAMP,
shipping_end_fact_datetime 		TIMESTAMP NULL
);

--Дополним БД связями
ALTER TABLE  shipping_info ADD CONSTRAINT shipping_id_fk FOREIGN KEY (shipping_id) REFERENCES shipping_status(shipping_id) ON UPDATE CASCADE;
--1.2 Наполнение справочника
CREATE SEQUENCE shipping_country_rates_sequence START 1;

INSERT INTO shipping_country_rates 
(id, shipping_country, shipping_country_base_rate)
SELECT nextval('shipping_country_rates_sequence') AS scr_seq, 
  shipping_country, shipping_country_base_rate 
  FROM shipping
  GROUP BY shipping_country, shipping_country_base_rate;
  
DROP SEQUENCE shipping_country_rates_sequence;

--1.3 Проверим корректность наполнения
--SELECT *
--FROM shipping_country_rates;

/*
1  usa    0.02
2  norway  0.04
3  germany  0.01
4  russia  0.03
*/

--2.2 Наполнение таблицы данными
INSERT INTO shipping_agreement
(agreement_id, agreement_number, agreement_rate, agreement_comission)
SELECT DISTINCT CAST(agreement[1] AS BIGINT),
	agreement[2],
	CAST(agreement[3] AS NUMERIC),
	CAST(agreement[4] AS NUMERIC)
FROM (SELECT regexp_split_to_array(sh.vendor_agreement_description, ':+') AS agreement
	FROM public.shipping sh) AS agr;

--Проверим наполнение таблицы
--SELECT *
--FROM shipping_agreement;


--3.2 Наполнение таблицы данными
CREATE SEQUENCE shipping_transfer_sequence;

WITH cte AS (	
	SELECT std.stdes[1] AS transfer_type,
		std.stdes[2] AS transfer_model,sh.id, shipping_transfer_description
	FROM (SELECT regexp_split_to_array(shipping_transfer_description , ':+') AS stdes, 
		id 
		FROM shipping) AS std JOIN shipping sh 
			ON sh.id = std.id)
INSERT INTO shipping_transfer
(id, transfer_type, transfer_model, shipping_transfer_rate)
SELECT nextval('shipping_transfer_sequence') AS id,
	transfer_type, 
	transfer_model,
	sh.shipping_transfer_rate
FROM cte JOIN shipping sh ON cte.id=sh.id
GROUP BY transfer_type, transfer_model, sh.shipping_transfer_rate;

DROP SEQUENCE shipping_transfer_sequence;

--3.3 Проверим наполнение таблицы
--SELECT * 
--FROM shipping_transfer;
	
/*
1	3p	multiplie	0.045
2	3p	train		0.020
3	1p	ship		0.030
4	1p	airplane	0.040
5	1p	train		0.025
6	1p	multiplie	0.050
7	3p	ship		0.025
8	3p	airplane	0.035 
*/

--4.2 Наполнение таблицы данными
WITH sa_cte AS (
SELECT DISTINCT sh.shippingid, sh.shipping_plan_datetime, sh.payment_amount, 
		sh.vendorid AS vendor_id, sa.agreement_id
FROM shipping sh LEFT JOIN shipping_agreement sa ON 
	sh.vendor_agreement_description=CONCAT(sa.agreement_id, ':', sa.agreement_number,
											':', sa.agreement_rate, ':', 
											sa.agreement_comission)
), scr_cte AS (
SELECT DISTINCT scr.id AS country_id, sh.shippingid
FROM shipping_country_rates scr JOIN shipping sh 
	ON scr.shipping_country = sh.shipping_country
), st_cte AS (
SELECT DISTINCT sh.shippingid, st.id AS transfer_id
FROM shipping_transfer st JOIN shipping sh 
	ON concat(st.transfer_type, ':', st.transfer_model) = sh.shipping_transfer_description
)
INSERT INTO shipping_info
(shipping_id, country_id, agreement_id, transfer_id, shipping_plan_datetime,
payment_amount, vendor_id)
SELECT sa_cte.shippingid AS shipping_id, scr_cte.country_id, sa_cte.agreement_id,
		st_cte.transfer_id, sa_cte.shipping_plan_datetime, sa_cte.payment_amount,
		sa_cte.vendor_id
FROM sa_cte JOIN scr_cte ON sa_cte.shippingid = scr_cte.shippingid
	JOIN st_cte ON sa_cte.shippingid = st_cte.shippingid
ORDER BY shipping_id desc;

--4.3 Проверим наполнение таблицы
--SELECT *
--FROM shipping_info
--ORDER BY shipping_id
--LIMIT 5;

/*
1	4	0	5	2021-09-15 16:43:42.434	6.06	1
2	1	1	5	2021-12-12 10:49:50.468	21.93	1
3	2	2	4	2021-10-27 10:33:16.659	3.10	1
4	3	3	5	2021-09-21 10:14:30.148	8.57	3
5	2	3	5	2022-01-02 21:21:08.844	1.50	3
*/

--5.2 Наполнение таблицы данными

WITH start_time_cte AS (
	SELECT shippingid, state_datetime
	FROM shipping
	WHERE 
	state = 'booked'
), end_time_cte AS (
	SELECT shippingid, state_datetime
	FROM shipping
	WHERE 
	state = 'recieved'
), max_time_cte AS (
	SELECT shippingid, MAX(state_datetime) AS max_time
	FROM shipping
	GROUP BY shippingid
)
INSERT INTO shipping_status 
(shipping_id, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
SELECT mtc.shippingid AS shipping_id, sh.status, sh.state,
	stc.state_datetime AS shipping_start_fact_datetime,
	etc.state_datetime AS shipping_end_fact_datetime
FROM shipping sh LEFT JOIN start_time_cte stc 
	ON sh.shippingid = stc.shippingid LEFT JOIN end_time_cte etc
	ON sh.shippingid = etc.shippingid LEFT JOIN max_time_cte mtc
	ON sh.shippingid = mtc.shippingid
WHERE max_time = sh.state_datetime;

--Проверим данные
SELECT *
FROM shipping_status
LIMIT 10;
--Выглядит корректно.
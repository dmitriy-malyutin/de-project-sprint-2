--1.2 Наполнение справочника shipping_country_rates
INSERT INTO shipping_country_rates 
(shipping_country, shipping_country_base_rate)
SELECT shipping_country, shipping_country_base_rate 
  FROM shipping
  GROUP BY shipping_country, shipping_country_base_rate;

--2.2 Наполнение таблицы данными shipping_agreement
INSERT INTO shipping_agreement
(agreement_id, agreement_number, agreement_rate, agreement_comission)
SELECT DISTINCT CAST(agreement[1] AS BIGINT),
	agreement[2],
	CAST(agreement[3] AS NUMERIC),
	CAST(agreement[4] AS NUMERIC)
FROM (SELECT regexp_split_to_array(sh.vendor_agreement_description, ':+') AS agreement
	FROM public.shipping sh) AS agr;

--3.2 Наполнение таблицы данными shipping_transfer
WITH cte AS (	
	SELECT std.stdes[1] AS transfer_type,
		std.stdes[2] AS transfer_model,sh.id, shipping_transfer_description
	FROM (SELECT regexp_split_to_array(shipping_transfer_description , ':+') AS stdes, 
		id 
		FROM shipping) AS std JOIN shipping sh 
			ON sh.id = std.id)
INSERT INTO shipping_transfer
(transfer_type, transfer_model, shipping_transfer_rate)
SELECT transfer_type, 
	transfer_model,
	sh.shipping_transfer_rate
FROM cte JOIN shipping sh ON cte.id=sh.id
GROUP BY transfer_type, transfer_model, sh.shipping_transfer_rate;

--4.2 Наполнение таблицы данными shipping_info
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

--5.2 Наполнение таблицы данными shipping_status
WITH times_cte  AS (
    SELECT shippingid,
           MAX(CASE 
	           	WHEN state = 'booked' THEN state_datetime ELSE NULL
	           END) AS shipping_start_fact_datetime,
           MAX(CASE 
	           	WHEN state = 'recieved' THEN state_datetime ELSE NULL 
	           END) AS shipping_end_fact_datetime,
           MAX(state_datetime) AS max_state_datetime
    FROM shipping
    GROUP BY shippingid
)
INSERT INTO shipping_status 
(shipping_id, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
SELECT tc.shippingid AS shipping_id, sh.status, sh.state,
	tc.shipping_start_fact_datetime,
	tc.shipping_end_fact_datetime
FROM times_cte AS tc
LEFT JOIN shipping AS sh ON tc.shippingid = sh.shippingid
                        AND tc.max_state_datetime = sh.state_datetime;

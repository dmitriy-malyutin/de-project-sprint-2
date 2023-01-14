--6.1 Создайте представление  shipping_datamart на основании готовых таблиц 
DROP VIEW IF EXISTS shipping_datamart;

CREATE VIEW shipping_datamart AS
SELECT ss.shipping_id, si.vendor_id, st.transfer_type, 
	EXTRACT(DAY FROM(ss.shipping_end_fact_datetime - ss.shipping_start_fact_datetime)) AS full_day_at_shipping,
	CASE 
		WHEN ss.shipping_end_fact_datetime  > si.shipping_plan_datetime THEN 1 ELSE 0 
	END AS is_delay, CASE
		WHEN ss.status = 'finished' THEN 1 ELSE 0
	END	AS is_shipping_finish, CASE 
		WHEN ss.shipping_end_fact_datetime  > si.shipping_plan_datetime 
		THEN EXTRACT(DAY FROM(ss.shipping_end_fact_datetime - si.shipping_plan_datetime))
	END AS delay_day_at_shipping, si.payment_amount, 
	(si.payment_amount * (scr.shipping_country_base_rate + sa.agreement_rate + st.shipping_transfer_rate)) AS vat,
	(si.payment_amount * sa.agreement_comission) AS profit
FROM shipping_info si LEFT JOIN shipping_country_rates scr ON si.country_id = scr.id
	LEFT JOIN shipping_agreement sa ON sa.agreement_id = si.agreement_id
	LEFT JOIN shipping_transfer st ON st.id = si.transfer_id
	LEFT JOIN shipping_status ss ON ss.shipping_id = si.shipping_id;
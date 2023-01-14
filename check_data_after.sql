--1.3 Проверим корректность наполнения shipping_country_rates
SELECT *
FROM shipping_country_rates;

/*
1  usa    0.02
2  norway  0.04
3  germany  0.01
4  russia  0.03
*/

--2.3 Проверим наполнение таблицы shipping_agreement
SELECT *
FROM shipping_agreement;

/*
42	vspn-8402	0.05	0.02
4	vspn-1909	0.03	0.03
21	vspn-2673	0.14	0.01
6	vspn-4215	0.04	0.01
23	vspn-903	0.07	0.02
25	vspn-1315	0.09	0.02
50	vspn-9311	0.02	0.01
31	vspn-1242	0.01	0.01
15	vspn-7331	0.12	0.02
55	vspn-9747	0.05	0.01
*/

--3.3 Проверим наполнение таблицы shipping_transfer
SELECT * 
FROM shipping_transfer;
	
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

--4.3 Проверим наполнение таблицы
SELECT *
FROM shipping_info
ORDER BY shipping_id
LIMIT 5;

/*
1	4	0	5	2021-09-15 16:43:42.434	6.06	1
2	1	1	5	2021-12-12 10:49:50.468	21.93	1
3	2	2	4	2021-10-27 10:33:16.659	3.10	1
4	3	3	5	2021-09-21 10:14:30.148	8.57	3
5	2	3	5	2022-01-02 21:21:08.844	1.50	3
*/

--Проверим данные
SELECT *
FROM shipping_status
LIMIT 10;
--Выглядит корректно.

/*
1	finished	recieved	2021-09-05 06:42:34.249	2021-09-15 04:26:57.690
2	finished	recieved	2021-12-06 22:27:48.306	2021-12-11 21:00:44.409
3	finished	recieved	2021-10-26 10:33:16.659	2021-10-27 04:03:32.884
4	finished	recieved	2021-09-13 16:21:32.421	2021-09-19 13:00:30.088
5	finished	recieved	2021-12-29 14:47:46.141	2022-01-09 20:21:08.963
6	finished	recieved	2021-10-31 07:05:50.404	2021-11-01 02:21:46.579
7	finished	recieved	2021-10-06 23:27:52.573	2021-10-07 17:11:07.012
8	finished	returned	2021-09-02 02:42:48.067	2021-09-03 11:27:42.602
9	finished	recieved	2021-09-08 04:47:59.753	2021-09-09 14:50:14.936
10	finished	recieved	2021-12-18 09:41:19.969	2021-12-28 00:55:32.210
*/

--6.2 Проверим данные shipping_datamart
SELECT *
FROM shipping_datamart
ORDER BY shipping_id;

SELECT shipping_id, full_day_at_shipping, is_delay, is_shipping_finish, delay_day_at_shipping, vat, profit
FROM shipping_datamart sd
WHERE --full_day_at_shipping IS NULL 
--is_delay  IS NULL 
--is_shipping_finish  IS NULL 
--delay_day_at_shipping  IS NULL 
--vat  IS NULL ;
profit IS NULL;
--Выглядит ОК, представлены данные по всем уникальным shipping_id, неожиданных NULL нет.
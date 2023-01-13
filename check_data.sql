--Проверим исходные значения
SELECT COUNT(DISTINCT(shippingid))
FROM shipping;

--54174 уникальных доставки. В дальнейшем буду по умолчанию сравнивать результаты с этим числом.

SELECT MAX(payment_amount), avg(payment_amount), min(payment_amount) 
FROM shipping;
/*
max		avg					min
6074.55	11.3525164270098839	1.50

Очень большой разброс между средним и максимальным, проверю
*/

SELECT *
FROM shipping
WHERE payment_amount = 6074.55;

SELECT MAX(payment_amount), avg(payment_amount), min(payment_amount), vendorid
FROM shipping
GROUP BY vendorid
ORDER BY MAX(payment_amount) desc;
/* 
ОК, у вендоров 21 и 22 суммы значительно выше

max		avg						min		vendorid
6074.55	2825.3816483516483516	761.85	21
5728.38	2801.4874251497005988	767.06	22
743.77	672.4669230769230769	558.11	18
741.66	639.7566037735849057	516.54	19
323.26	289.3500000000000000	259.45	16
320.89	270.3890909090909091	245.82	15
318.89	267.7000000000000000	232.42	14
148.83	132.7000000000000000	124.09	10
124.07	124.0700000000000000	124.07	9
112.99	110.6875000000000000	108.08	11
104.80	52.1865714285714286		23.50	5
103.04	55.8480000000000000		23.78	6
98.54	49.7868273092369478		21.67	7
40.47	7.7627909801979273		1.50	1
38.63	7.7724762415412491		1.50	3
32.12	7.8130333434962166		1.50	2
*/

/*
Проверим корректность данных на соответствие MIN(state_datetime)='booked' и 
MAX(state_datetime)='recieved'
*/
WITH steps AS (
	SELECT (row_number() over(partition by shippingid
	order by state_datetime)) AS step, shippingid, state, state_datetime
	FROM shipping)
SELECT step, shippingid, state, state_datetime
FROM steps 
WHERE step = 1
AND steps.state <> 'booked';
/*
Нет заказов, где MIN(state_datetime) не соответствует state='booked'
Нет разницы, как выбирать данные: по MIN(state_datetime) или state='booked'
*/
WITH steps AS (
	SELECT (row_number() over(partition by shippingid
		order by state_datetime)) AS step, shippingid, state, state_datetime
	FROM shipping)
SELECT COUNT(step), state, step
FROM steps 
WHERE step > 6 --step = 6 соответствует state = 'recieved'
GROUP BY state, step;
/* 
count	state		step
810		returned	7

810 shippingid в статусе 'returdned', брать данные по соответствию 
MAX(state_datetime)='recieved' некорректно
*/

--Проверим на соответствие статусов
SELECT *
FROM shipping
WHERE state NOT IN ('recieved', 'returned');
--Множество незавершенных доставок - это ОК, они в процессе выполнения. 
--Есть доставки, для которых state='pending' был проставлен позже 'recieved'
--Проверим, что это за доставки, возьмем несколько shipping_id
WITH steps AS (
	SELECT (row_number() over(partition by shippingid
	order by state_datetime)) AS step, *
	FROM shipping)
SELECT COUNT(shippingid), description, status, state, vendorid
FROM steps
WHERE state <> 'recieved' 
AND state <> 'returned'
AND step IN (6, 7)
GROUP BY description, status, state, vendorid;

/*
count	description							status			state		vendorid
4		food&healh vendor_1 from germany	in_progress		pending		1
1		food&healh vendor_1 from norway		in_progress		pending		1
5		food&healh vendor_1 from russia		in_progress		pending		1
2		food&healh vendor_1 from usa		in_progress		pending		1
5		food&healh vendor_2 from germany	in_progress		pending		2
4		food&healh vendor_2 from norway		in_progress		pending		2
1		food&healh vendor_2 from russia		in_progress		pending		2
4		food&healh vendor_2 from usa		in_progress		pending		2
41		food&healh vendor_3 from germany	in_progress		pending		3
39		food&healh vendor_3 from norway		in_progress		pending		3
35		food&healh vendor_3 from russia		in_progress		pending		3
25		food&healh vendor_3 from usa		in_progress		pending		3

Из данной выборки видно, что большая часть доставок с несоответствием статусов принадлежит вендору 3. 
Проверим, есть ли у него доставки с корректными данными
*/
WITH steps AS (
	SELECT (row_number() over(partition by shippingid
	order by state_datetime)) AS step, *
	FROM shipping)
SELECT COUNT(shippingid), description, status, state, vendorid
FROM steps
WHERE step IN (6)
AND state = 'recieved'
GROUP BY description, status, state, vendorid;
/*
Выглядит корректно, у всех вендоров категории "food&healh" примерно одинаковое количество корректных заказов.
Вижу следующие варианты решения:
	1. Самостоятельно поменять данные проблемные статусы местами, исходя из предположения, 
что это ошибки, но слишком уж большая разница в количестве ошибок у вендоров.
	2. Оставить их без внимания: процент погрешности составляет 166/53090 завершенных заказов = 0,3% - не большая погрешность.
Кроме того, по условию, вендор 3 неблагонадёжен в плане исполнения сроков доставки, что отменяет первый вариант.
	3. Удалить эти данные из выборки. 0,3% от общего числа не должны оказать значительное влияние на результаты.

До уточнения информации об этих заказах оставлю их без изменений, в целом это удовлетворяет особенностям данных из условия задачи.
 */
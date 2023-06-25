drop table if exists results;

create table if not exists results (id INT, response text);

-- 1.	Вывести максимальное количество человек в одном бронировании
insert into results
select 1, count(t.passenger_id||t.passenger_name) co from bookings.tickets t group by t.book_ref order by co desc limit 1;

-- 2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
insert into results
with cnt as (
select t.book_ref br, count(t.passenger_id) co from bookings.tickets t group by t.book_ref
)
select 2, count(cnt.br) c from cnt
where cnt.co > (select avg(cnt.co) from cnt);

-- 3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?
insert into results
with book_co as (
	select book_ref, count(t.passenger_id||t.passenger_name) co from bookings.tickets t group by t.book_ref order by co desc
)
select 3, count(*) from (
	select dat, count(*)  from (
	select t.book_ref, string_agg(t.passenger_id || '|' || t.passenger_name, '|') dat
		from book_co, bookings.tickets t
		where book_co.book_ref = t.book_ref and co = (select max(co) from book_co)
		group by t.book_ref
	) q group by q.dat having count(*) >= 2
) q2;

-- 4.	Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3
insert into results
with b_info as (
select t.book_ref br, count(*) cnt
	from bookings.tickets t group by br having count(*) = 3
)
select 4, s2.book_ref || '|' || string_agg(dat, '|') from (
	select book_ref, passenger_id || '|' || passenger_name || '|' || contact_data dat
		from tickets where book_ref in (select br from b_info)
) s2
group by s2.book_ref;

-- 5.	Вывести максимальное количество перелётов на бронь
insert into results
select 5, count(tf.flight_id) co from bookings.ticket_flights tf, bookings.tickets t, bookings.bookings b
where b.book_ref = t.book_ref and t.ticket_no = tf.ticket_no group by b.book_ref order by co desc limit 1;

-- 6.	Вывести максимальное количество перелётов на пассажира в одной брони
insert into results
select 6, count(t.passenger_id||t.passenger_name) co from bookings.boarding_passes bp, bookings.tickets t, bookings bb
where bb.book_ref = t.book_ref and t.ticket_no = bp.ticket_no group by bb.book_ref, t.passenger_id||t.passenger_name order by co desc limit 1;

-- 7.	Вывести максимальное количество перелётов на пассажира
insert into results
select 7, count(t.passenger_id||t.passenger_name) co from bookings.boarding_passes bp, bookings.tickets t
where t.ticket_no = bp.ticket_no group by t.passenger_id||t.passenger_name order by co desc limit 1;

-- 8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
insert into results
with pas_d as (
select t.passenger_id||'|'||t.passenger_name||'|'||t.contact_data pas, sum(tf.amount) su
	from bookings.ticket_flights tf, bookings.tickets t
	where t.ticket_no = tf.ticket_no
	group by pas
)
select 8, pas||'|'||su from pas_d where su = (select min(su) from pas_d) order by pas;

-- 9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах, для пассажира, который провёл максимальное время в полётах
insert into results
with pas_d as (
select t.passenger_id||'|'||t.passenger_name||'|'||t.contact_data pas, sum(fv.actual_duration) su
	from bookings.ticket_flights tf, bookings.tickets t, bookings.flights_v fv
	where t.ticket_no = tf.ticket_no and tf.flight_id = fv.flight_id
	group by pas
)
select 9, pas||'|'||su from pas_d where su = (select max(su) from pas_d) order by pas;

-- 10.	Вывести город(а) с количеством аэропортов больше одного
insert into results
SELECT 10, aa.city FROM airports aa GROUP BY aa.city HAVING COUNT(*) > 1 order by aa.city;

-- 11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
insert into results
with min_c as (
SELECT departure_city, count(arrival_city) co from routes group by departure_city
)
select 11, departure_city from min_c where co = ( select min(co) from min_c)
order by departure_city;

-- 12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
insert into results
select 12, city1||'|'||city2 from (
select a1.city as city1, a2.city as city2
	from bookings.airports a1, bookings.airports a2
	where a1.city < a2.city
except
select distinct departure_city, arrival_city from
(
select departure_city, arrival_city from routes
 union all
select arrival_city, departure_city from routes) q2
order by city1, city2
) q1;

-- 13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?
insert into results
select distinct 13, br.departure_city _city from bookings.routes br
where br.departure_city != 'Москва' and br.departure_city not in (select distinct arrival_city from bookings.routes where departure_city = 'Москва')
order by br.departure_city;

-- 14.	Вывести модель самолета, который выполнил больше всего рейсов
insert into results
select 14, a.model from flights_v fv, aircrafts a where a.aircraft_code = fv.aircraft_code group by a.model order by count(*) desc limit 1;

-- 15.	Вывести модель самолета, который перевез больше всего пассажиров
insert into results
select 15, a.model from flights_v fv, aircrafts a, bookings.boarding_passes bp
where fv.status = 'Arrived' and a.aircraft_code = fv.aircraft_code and bp.flight_id =fv.flight_id
group by a.model order by count(*) desc limit 1;

-- 16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
insert into results
SELECT 16, EXTRACT(EPOCH FROM (sum(scheduled_duration) - sum(actual_duration))) /60
from bookings.flights_v where actual_duration is not null;

-- 17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2017-08-11
insert into results
select distinct 17, fv.arrival_city ac
	from flights_v fv
	where fv.DEPARTURE_city = 'Санкт-Петербург' and (status = 'Arrived' or status = 'Departed') and date_trunc('day',fv.actual_departure_local) = '20170811'
	order by ac;

-- 18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
insert into results
with f_cost as (
SELECT tf.flight_id, sum(tf.amount) su FROM bookings.ticket_flights tf
group by tf.flight_id
)
select 18, flight_id FROM f_cost where f_cost.su = (select max(su) from f_cost);

-- 19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
insert into results
with min_c as (
	select date_trunc('day',fv.actual_departure_local) dat, count(*) co from bookings.flights_v fv group by dat
)
select 19, dat from min_c where co = (select min(co) from min_c);

--20.	Вывести среднее количество вылетов в день из Москвы за 08 месяц 2017 года
insert into results
select 20, count(*) / (select count (distinct date_trunc('day',actual_departure_local)) )
from bookings.flights_v fv where fv.departure_city = 'Москва' and actual_departure_local between '20170801' and '20170901';

-- 21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
insert into results
select '21', DEPARTURE_city from flights_v group by DEPARTURE_city having avg(actual_duration) > '03:00:00' order by avg(actual_duration) desc limit 5;
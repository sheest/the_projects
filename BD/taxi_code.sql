BEGIN;

Drop table IF EXISTS  public.car Cascade;
Drop table IF EXISTS  public.driver Cascade;
Drop table IF EXISTS  public.driver_auto Cascade;
Drop table IF EXISTS  public.order Cascade;
Drop table IF EXISTS  public.tariff Cascade;
Drop table IF EXISTS  public.payment_info Cascade;
Drop table IF EXISTS  public.car_class Cascade;
Drop table IF EXISTS public.car_brand Cascade;
Drop table IF EXISTS public.car_type Cascade;

CREATE TABLE IF NOT EXISTS public.car
(
    state_number character varying(9) NOT NULL CHECK (state_number ~* '^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$'),
    color character varying(20) NOT NULL,
    date_of_prediction date NOT NULL,
    brand_class integer NOT NULL,
    id serial,
    PRIMARY KEY (id),
    UNIQUE (state_number)
);

CREATE TABLE IF NOT EXISTS public.driver
(
    inn character varying(15) NOT NULL CHECK (inn ~* '^\d{12}$'),
    name character varying(255) NOT NULL,
    surname character varying(255) NOT NULL,
    patronymic character varying(255),
    date_of_birth date NOT NULL,
    series character varying(10),
    passport_number character varying(10),
    id serial,
    PRIMARY KEY (id),
    UNIQUE (series, passport_number),
    UNIQUE (inn),
	CHECK (date_of_birth <= CURRENT_DATE - interval '18 year' AND date_of_birth >= CURRENT_DATE - interval '70 year')

);

CREATE TABLE IF NOT EXISTS public.driver_auto
(
    id serial,
    auto_id integer NOT NULL,
    driver_id integer NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (auto_id, driver_id)
);

CREATE TABLE IF NOT EXISTS public.order
(
    id serial,
    driver_car_id integer NOT NULL,
    Date_order date NOT NULL DEFAULT NOW(),
    address_Innings character varying(255) NOT NULL,
    address_Delivery character varying(255) NOT NULL,
    count_Passenger integer NOT NULL CHECK(count_Passenger>0),
    tariff_id integer,
    estimated_route_length numeric(5, 2) NOT NULL CHECK(estimated_route_length>0),
   	time_order time(3) without time zone,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.tariff
(
    name_tariff character varying(255),
    price numeric(9, 2) NOT NULL CHECK(price>0),
    time_of_day character varying(255) CHECK(time_of_day in ('День','Ночь')),
    id serial,
    area character varying(255) CHECK(area in ('МКАД','за МКАД','Подмосковье')),
    PRIMARY KEY (id),
    UNIQUE (time_of_day, area,name_tariff)
);

CREATE TABLE IF NOT EXISTS public.payment_info
(
    id serial,
    order_id integer NOT NULL,
    actual_route_length numeric(5, 1) NOT NULL CHECK(actual_route_length>0),
    cost numeric(9, 2) NOT NULL CHECK(cost >0),
    PRIMARY KEY (id),
    UNIQUE (order_id)
);

CREATE TABLE IF NOT EXISTS public.car_class
(
    class_type character varying(255),
    id serial,
    PRIMARY KEY (id),
    UNIQUE (class_type)
);

CREATE TABLE IF NOT EXISTS public.car_brand
(
    brand_name character varying(255),
    id serial,
    PRIMARY KEY (id),
    UNIQUE (brand_name)
);

CREATE TABLE IF NOT EXISTS public.car_type
(
    id serial,
    brand_id integer,
    class_id integer,
    PRIMARY KEY (id),
    UNIQUE (brand_id, class_id)
);

ALTER TABLE IF EXISTS public.car
    ADD FOREIGN KEY (brand_class)
    REFERENCES public.car_type (id) MATCH SIMPLE ON DELETE CASCADE
    ON UPDATE NO ACTION
    -- ON DELETE NO ACTION
    NOT VALID;

ALTER TABLE IF EXISTS public.Driver_Auto
    ADD FOREIGN KEY (driver_id)
    REFERENCES public.driver (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order
    ADD FOREIGN KEY (driver_car_id)
    REFERENCES public.driver_auto (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order
    ADD FOREIGN KEY (tariff_id)
    REFERENCES public.tariff (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.payment_info
    ADD FOREIGN KEY (order_id)
    REFERENCES public.order (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.car_type
    ADD FOREIGN KEY (class_id)
    REFERENCES public.car_class (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.car_type
    ADD FOREIGN KEY (brand_id)
    REFERENCES public.car_brand (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;

END;
-- триггер для вычисления стоимости поездки 
CREATE OR REPLACE FUNCTION calculate_cost()
RETURNS TRIGGER AS $$
DECLARE
    v_price NUMERIC(9,2);
BEGIN
    -- Получаем цену из таблицы tariff на основе tariff_id из таблицы order
    SELECT price INTO v_price
    FROM tariff
    WHERE id = (SELECT tariff_id FROM "order" WHERE id = NEW.order_id);

    IF v_price IS NULL THEN
        RAISE EXCEPTION 'Не найден тариф для order_id = %', NEW.order_id;
    END IF;

    NEW.cost := NEW.actual_route_length * v_price;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payment_info_before_insert
BEFORE INSERT ON payment_info
FOR EACH ROW
EXECUTE FUNCTION calculate_cost();
-----

--вставка в таблицу public.car_brand
INSERT INTO public.car_brand (brand_name) VALUES ('Toyota');
INSERT INTO public.car_brand (brand_name) VALUES ('BMW');
INSERT INTO public.car_brand (brand_name) VALUES ('Mercedes-Benz');
INSERT INTO public.car_brand (brand_name) VALUES ('Ford');
INSERT INTO public.car_brand (brand_name) VALUES ('Hyundai');

SELECT * from public.car_brand

--вставка в таблицу public.car_class
INSERT INTO public.car_class (class_type) VALUES ('Economy');
INSERT INTO public.car_class (class_type) VALUES ('Comfort');
INSERT INTO public.car_class (class_type) VALUES ('Business');
INSERT INTO public.car_class (class_type) VALUES ('Premium');
SELECT * from public.car_class

--вставка в таблицу public.car_type
INSERT INTO public.car_type (brand_id, class_id) VALUES (1, 1); 
INSERT INTO public.car_type (brand_id, class_id) VALUES (2, 3);
INSERT INTO public.car_type (brand_id, class_id) VALUES (3, 4);
INSERT INTO public.car_type (brand_id, class_id) VALUES (4, 1); 
INSERT INTO public.car_type (brand_id, class_id) VALUES (5, 2); 
INSERT INTO public.car_type (brand_id, class_id) VALUES (1, 2);
INSERT INTO public.car_type (brand_id, class_id) VALUES (2, 4);
INSERT INTO public.car_type (brand_id, class_id) VALUES (3, 1); 
INSERT INTO public.car_type (brand_id, class_id) VALUES (4, 3); 
INSERT INTO public.car_type (brand_id, class_id) VALUES (5, 1); 
SELECT * from public.car_type

--вставка в таблицу public.car
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('А123ВЕ777', 'Red', '2024-01-15', 1);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('В456КМ799', 'Blue', '2024-02-20', 2);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('Е789МН150', 'Black', '2024-03-25', 3);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('К012ОР98', 'White', '2024-04-30', 4);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('М345СТ197', 'Silver', '2024-05-05', 5);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('Н678УХ77', 'Green', '2024-06-10', 6);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('О901АВ199', 'Yellow', '2024-07-15', 7);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('Р234ЕК750', 'Purple', '2024-08-20', 8);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('С567КМ178', 'Brown', '2024-09-25', 9);
INSERT INTO public.car (state_number, color, date_of_prediction, brand_class) VALUES ('Т890МН99', 'Bronze', '2024-10-30', 10);

--вставка в таблицу public.driver
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('123456789012', 'Иван', 'Иванов', 'Иванович', '1990-05-10', '1234', '567890');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('234567890123', 'Петр', 'Петров', 'Петрович', '1985-12-01', '5678', '901234');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('345678901234', 'Анна', 'Сидорова', 'Сергеевна', '1992-08-15', '9012', '345678');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('456789012345', 'Елена', 'Смирнова', 'Алексеевна', '1988-03-20', '3456', '789012');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('567890123456', 'Дмитрий', 'Кузнецов', 'Викторович', '1995-06-25', '7890', '123456');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('678901234567', 'Ольга', 'Соколова', 'Михайловна', '1975-11-05', '2345', '678901');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('789012345678', 'Алексей', 'Волков', 'Андреевич', '1982-07-12', '6789', '012345');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('890123456789', 'Татьяна', 'Морозова', 'Ивановна', '1998-02-28', '0123', '456789');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('901234567890', 'Сергей', 'Лебедев', 'Петрович', '1970-09-18', '4567', '890123');
INSERT INTO public.driver (inn, name, surname, patronymic, date_of_birth, series, passport_number) VALUES ('012345678912', 'Наталья', 'Федорова', 'Дмитриевна', '1987-04-03', '8901', '234567');

--вставка в таблицу public.driver_auto
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (1, 1); 
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (2, 1);
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (3, 1); 
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (4, 7); 
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (5, 9); 
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (6, 2);
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (7, 4);
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (8, 3);
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (9, 5);
INSERT INTO public.driver_auto (auto_id, driver_id) VALUES (10, 10);

--вставка в таболицу public.tariff
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Mkad Day', 150.00, 'День', 'МКАД');
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Mkad Night', 250.00, 'Ночь', 'МКАД');
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Moscow region Day', 350.00, 'День', 'Подмосковье');
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Moscow region Night', 500.00, 'Ночь', 'Подмосковье');
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Za MKAD Day', 180.00, 'День', 'за МКАД');
INSERT INTO public.tariff (name_tariff, price, time_of_day, area) VALUES ('Za MKAD Night', 280.00, 'Ночь', 'за МКАД');

Select * from public.tariff

--вставка в таболицу public.order
INSERT INTO public.order (driver_car_id, Date_order, address_Innings, address_Delivery, count_Passenger, tariff_id, estimated_route_length, time_order) VALUES
(1, date '2024-07-01', 'ул. Ленина, 1', 'ул. Мира, 10', 2, 1, 10.5, '10:00:00'),
(2, date '2024-07-02', 'пр. Вернадского, 5', 'ул. Строителей, 15', 1, 2, 15.2, '22:00:00'),
(4, date '2024-07-03', 'ул. Арбат, 20', 'ул. Тверская, 25', 3, 3, 25.8, '14:00:00'),
(4, date '2024-07-04', 'ул. Садовая, 30', 'ул. Пушкина, 5', 2, 4, 8.7, '08:30:00'),
(5, date '2024-07-05', 'пл. Революции, 1', 'Красная пл., 1', 1, 5, 5.1, '18:45:00'),
(6, date '2024-07-06', 'наб. Фонтанки, 10', 'Невский пр., 20', 4, 1, 12.3, '12:15:00'),
(10, date '2024-07-07', 'Московский пр., 100', 'Витебский вокзал', 3, 2, 18.9, '20:00:00'),
(8, date '2024-07-08', 'ул. Рубинштейна, 15', 'Литейный пр., 25', 2, 3, 7.5, '09:00:00'),
(9, date '2024-07-09', 'Крестовский остров', 'Петропавловская крепость', 1, 6, 9.2, '15:30:00'),
(10, date '2024-07-10', 'Петергоф', 'Царское Село', 2, 5, 30.0, '23:59:59');

--вставка в таболицу public.payment_info
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (1, 11.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (2, 16.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (3, 26.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (4, 9.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (5, 6.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (6, 13.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (7, 19.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (8, 8.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (9, 10.0);
INSERT INTO public.payment_info (order_id, actual_route_length) VALUES (10, 31.0);

SELECT * from public.payment_info
SELECT * from tariff

-- Список видов марок и классов авто представленных в таксопарке
SELECT car_type.id ,car_brand.brand_name,car_class.class_type from public.car_type car_type JOIN public.car_brand car_brand ON car_type.brand_id=car_brand.id
JOIN public.car_class car_class ON car_type.class_id=car_class.id

--Выберете таксиста (таксистов), который заработал больше всех.
with id_max_cost as (
SELECT driver_car_id from public.payment_info p JOIN public.order o ON o.id=p.order_id
where cost = (SELECT max(cost) from public.payment_info)
)
select name,surname, patronymic from driver 
where id =(select driver_id from public.driver_auto where id = (select driver_car_id from id_max_cost))


-- Выберете информацию о заказах за последний месяц (дата, адрес подачи
-- такси, фамилия, имя, отчество водителя, суммарная по всем
-- задействованным тарифам стоимость).
-- sum считалось как сколько всего водитель заработал за последний месяц 
with info_order as (
select Date_order,address_innings,cost,driver_id,order_id from (select Date_order,address_innings,cost,driver_car_id,order_id from public.order o JOIN public.payment_info p ON o.id=p.order_id
where extract(month from Date_order) = (select max(extract(month from Date_order)) from public.order)) T1  
left join public.driver_auto d ON T1.driver_car_id=d.id
),
T1 as (
SELECT Date_order,address_innings,cost,name,surname,patronymic,driver_id from info_order i left join public.driver d ON i.driver_id=d.id
)

select Date_order,address_innings,cost,name , surname, patronymic, sum  from 
(select sum(cost),driver_id from T1 group by driver_id) T2 Right JOIN T1 ON T1.driver_id=T2.driver_id

-- Получите одним запросом количество заказов эконом классом и
-- количество заказов бизнес классом за 2023 год.

with car_class as(
select c.id,class_type from public.car c JOIN (select ct.id,class_type from public.car_class cc JOIN public.car_type ct ON ct.class_id=cc.id
where class_type in ('Economy','Business')) T1 ON c.brand_class=T1.id
),-- находим машины эконома и бизнеса
car_in_order_2023 as (
select * from public.driver_auto where id in 
(SELECT driver_car_id from public.order where extract(year from Date_order)=2023)
)-- находим id водитель - авто заказов сделанных в 2024 

SELECT count(cc.class_type),cc.class_type from car_class cc JOIN car_in_order_2023 
ON cc.id=car_in_order_2023.auto_id
group by cc.class_type -- считаем и объединяем 


-- Удалите все автомобили, которые не использовались в заказах ни разу.
-- Если на автомобили есть ссылки в других таблицах, то предварительно
-- добавьте в них каскадное удаление.

-- автомобили которые использовались в заказах 
with car_used as(
SELECT auto_id from public.driver_auto d JOIN public.order o ON d.id=o.driver_car_id
),
T1 as(
select distinct brand_class from public.car c JOIN car_used cu ON c.id=cu.auto_id
)

Delete from public.car_type where not id in(SELECT brand_class from T1)-- удалили машину которая не была задествована в заказах 
Returning id

-- Добавьте в базу данных информацию о предполагаемой цене поездки.

alter table public.order 
add column prediction_cost numeric(9,2)

SELECT * from public.order 

-- Добавьте в базу данных ограничение целостности, не позволяющее
-- добавлять заказ, с расчетной длиной поездки менее 2 км.
alter table public.order
add CONSTRAINT ok_lenght check(estimated_route_length>2) 

-- Одним запросом найдите тариф, который приносит самую большую
-- прибыль, и увеличьте его на 10%
with max_tariff as(
select t.id,sum(price) from public.order o JOIN public.tariff t ON o.tariff_id=t.id
group by t.id
order by sum desc
limit 1
)

update public.tariff
set price=price*1.10
where id = (select id from max_tariff)

SELECT * from public.tariff












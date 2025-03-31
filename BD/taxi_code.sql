BEGIN;

-- удаление всех таблиц БД
Drop table IF EXISTS  public.car Cascade;
Drop table IF EXISTS  public.driver Cascade;
Drop table IF EXISTS  public.driver_auto Cascade;
Drop table IF EXISTS  public.order Cascade;
Drop table IF EXISTS  public.tariff Cascade;
Drop table IF EXISTS  public.payment_info Cascade;
Drop table IF EXISTS  public.car_class Cascade;
Drop table IF EXISTS public.car_brand Cascade;
Drop table IF EXISTS public.car_type Cascade;

-- удаление тригера подчитывающий стоимость поездки
DROP TRIGGER payment_info_before_insert ON payment_info;

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
    REFERENCES public.car_type (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
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

--вставка в таблицу public.car_brand(марки машин)
INSERT INTO public.car_brand (brand_name) VALUES ('Toyota');
INSERT INTO public.car_brand (brand_name) VALUES ('BMW');
INSERT INTO public.car_brand (brand_name) VALUES ('Mercedes-Benz');
INSERT INTO public.car_brand (brand_name) VALUES ('Ford');
INSERT INTO public.car_brand (brand_name) VALUES ('Hyundai');


--вставка в таблицу public.car_class(классы машин)
INSERT INTO public.car_class (class_type) VALUES ('Economy');
INSERT INTO public.car_class (class_type) VALUES ('Comfort');
INSERT INTO public.car_class (class_type) VALUES ('Business');
INSERT INTO public.car_class (class_type) VALUES ('Premium');

--вставка в таблицу public.car_type(все типы машин ,которые есть в таксопарке)
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

--вставка в таблицу public.car
INSERT INTO public.car VALUES ('А123ВЕ777', 'Red', '2024-01-15', 1);
INSERT INTO public.car VALUES ('В456КМ799', 'Blue', '2024-02-20', 2);
INSERT INTO public.car VALUES ('Е789МН150', 'Black', '2024-03-25', 3);
INSERT INTO public.car VALUES ('К012ОР98', 'White', '2024-04-30', 4);
INSERT INTO public.car VALUES ('М345СТ197', 'Silver', '2024-05-05', 5);
INSERT INTO public.car VALUES ('Н678УХ77', 'Green', '2024-06-10', 6);
INSERT INTO public.car VALUES ('О901АВ199', 'Yellow', '2024-07-15', 7);
INSERT INTO public.car VALUES ('Р234ЕК750', 'Purple', '2024-08-20', 8);
INSERT INTO public.car VALUES ('С567КМ178', 'Brown', '2024-09-25', 8);
INSERT INTO public.car VALUES ('Т890МН99', 'Bronze', '2024-10-30', 10);

--вставка в таблицу public.driver
INSERT INTO public.driver VALUES ('123456789012', 'Иван', 'Иванов', 'Иванович', '1990-05-10', '1234', '567890');
INSERT INTO public.driver VALUES ('234567890123', 'Петр', 'Петров', 'Петрович', '1985-12-01', '5678', '901234');
INSERT INTO public.driver VALUES ('345678901234', 'Анна', 'Сидорова', 'Сергеевна', '1992-08-15', '9012', '345678');
INSERT INTO public.driver VALUES ('456789012345', 'Елена', 'Смирнова', 'Алексеевна', '1988-03-20', '3456', '789012');
INSERT INTO public.driver VALUES ('567890123456', 'Дмитрий', 'Кузнецов', 'Викторович', '1995-06-25', '7890', '123456');
INSERT INTO public.driver VALUES ('678901234567', 'Ольга', 'Соколова', 'Михайловна', '1975-11-05', '2345', '678901');
INSERT INTO public.driver VALUES ('789012345678', 'Алексей', 'Волков', 'Андреевич', '1982-07-12', '6789', '012345');
INSERT INTO public.driver VALUES ('890123456789', 'Татьяна', 'Морозова', 'Ивановна', '1998-02-28', '0123', '456789');
INSERT INTO public.driver VALUES ('901234567890', 'Сергей', 'Лебедев', 'Петрович', '1970-09-18', '4567', '890123');
INSERT INTO public.driver VALUES ('012345678912', 'Наталья', 'Федорова', 'Дмитриевна', '1987-04-03', '8901', '234567');

--вставка в таблицу public.driver_auto
INSERT INTO public.driver_auto VALUES (1, 1); 
INSERT INTO public.driver_auto VALUES (2, 2);
INSERT INTO public.driver_auto VALUES (3, 3); 
INSERT INTO public.driver_auto VALUES (4, 4); 
INSERT INTO public.driver_auto VALUES (5, 5); 
INSERT INTO public.driver_auto VALUES (6, 6);
INSERT INTO public.driver_auto VALUES (7, 7);
INSERT INTO public.driver_auto VALUES (8, 8);
INSERT INTO public.driver_auto VALUES (9, 9);
INSERT INTO public.driver_auto VALUES (10, 10);

--вставка в таболицу public.tariff
INSERT INTO public.tariff VALUES ('Mkad Day', 150.00, 'День', 'МКАД');
INSERT INTO public.tariff VALUES ('Mkad Night', 250.00, 'Ночь', 'МКАД');
INSERT INTO public.tariff VALUES ('Moscow region Day', 350.00, 'День', 'Подмосковье');
INSERT INTO public.tariff VALUES ('Moscow region Night', 500.00, 'Ночь', 'Подмосковье');
INSERT INTO public.tariff VALUES ('Za MKAD Day', 180.00, 'День', 'за МКАД');
INSERT INTO public.tariff VALUES ('Za MKAD Night', 280.00, 'Ночь', 'за МКАД');

--вставка в таболицу public.order
INSERT INTO public.order (driver_car_id, Date_order, address_Innings, address_Delivery, count_Passenger, tariff_id, estimated_route_length, time_order) 
VALUES
(1, '2024-07-01', 'ул. Ленина, 1', 'ул. Мира, 10', 2, 1, 10.5, '10:00:00'),
(2, '2024-07-02', 'пр. Вернадского, 5', 'ул. Строителей, 15', 1, 2, 15.2, '22:00:00'),
(3, '2024-07-03', 'ул. Арбат, 20', 'ул. Тверская, 25', 3, 3, 25.8, '14:00:00'),
(4, '2024-07-04', 'ул. Садовая, 30', 'ул. Пушкина, 5', 2, 4, 8.7, '08:30:00'),
(5, '2024-07-05', 'пл. Революции, 1', 'Красная пл., 1', 1, 5, 5.1, '18:45:00'),
(6, '2024-07-06', 'наб. Фонтанки, 10', 'Невский пр., 20', 4, 1, 12.3, '12:15:00'),
(7, '2024-07-07', 'Московский пр., 100', 'Витебский вокзал', 3, 2, 18.9, '20:00:00'),
(8, '2024-07-08', 'ул. Рубинштейна, 15', 'Литейный пр., 25', 2, 3, 7.5, '09:00:00'),
(9, '2024-07-09', 'Крестовский остров', 'Петропавловская крепость', 1, 6, 9.2, '15:30:00'),
(10, '2024-07-10', 'Петергоф', 'Царское Село', 2, 5, 30.0, '23:59:59');

--вставка в таболицу public.payment_info
INSERT INTO public.payment_info VALUES (1, 11.0);
INSERT INTO public.payment_info VALUES (2, 16.0);
INSERT INTO public.payment_info VALUES (3, 26.0);
INSERT INTO public.payment_info VALUES (4, 9.0);
INSERT INTO public.payment_info VALUES (5, 6.0);
INSERT INTO public.payment_info VALUES (6, 13.0);
INSERT INTO public.payment_info VALUES (7, 19.0);
INSERT INTO public.payment_info VALUES (8, 8.0);
INSERT INTO public.payment_info VALUES (9, 10.0);
INSERT INTO public.payment_info VALUES (10, 31.0);

SELECT * from public.payment_info
SELECT * from tariff

-- Список видов(марка+класс) авто представленных в таксопарке
SELECT car_type.id ,car_brand.brand_name,car_class.class_type from public.car_type car_type JOIN public.car_brand car_brand ON car_type.brand_id=car_brand.id
JOIN public.car_class car_class ON car_type.class_id=car_class.id

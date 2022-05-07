use sakila; --Wybór bazy danych

--Definicja tabeli (struktura)
CREATE TABLE raport( 
    Date date NOT NULL,
    new_rentals int,
    active_rentals int,
    rented_titles int,
    no_cust_with_rentals int,
    rentals_10_days int,
    PRIMARY KEY(date) -- Data przyjmuje wartości unikatowe, może posłużyć jako klucz główny tabeli.
    --Dodatkowo można dołożyć nową kolumnę z ID sklepu i dodać ograniczenie klucza obcego, celem połączenia nowej tabeli z resztą bazy
    --FOREIGN KEY (store_id) REFERENCES store(store_id)
)

--Tworzenie widoku raportującego według wzoru z zadania
CREATE VIEW raport_vw AS
SELECT x.Date, x.NewRentals, z.active ActiveRentals, SUM(x.NewRentals) OVER (ORDER BY Date) RentedTitles, x.num_cust NumberOfCustomers, x.rentals_10_days Rentals10Days --Wyświetlane kolumny
FROM (
    SELECT CAST(rental_date AS date) AS Date, COUNT(rental_id) AS NewRentals, COUNT(DISTINCT(customer_id)) num_cust, -- Castowanie datetime do date, obliczenie nowych wypożyczeń, ilości klientów
    COUNT(CASE WHEN date_add(rental_date, interval 10 day) <= return_date THEN rental_id ELSE NULL END) rentals_10_days --Obliczennie wypożyczeń 10 dniowych
    FROM rental JOIN inventory ON rental.inventory_id = inventory.inventory_id JOIN store ON inventory.store_id = store.store_id -- Połączenie tabel celem wybrania tylko tych zamówień ze store_id 1
    WHERE inventory.store_id=1
    GROUP BY 1
) x JOIN ( --Część odpowiedzialna za policzenie aktywnych wypożyczeń
    SELECT CAST(data AS date) Date, COUNT(DISTINCT(CASE WHEN data <= return_data THEN return_data ELSE NULL END))+1 active
FROM(
    SELECT t1.rid1, t1.rdx data, t2.rid2, t2.rdy, t2.rtdy return_data
    FROM ( 
        SELECT r1.rental_id rid1, r1.rental_date rdx, r1.return_date rtdx 
        FROM rental r1 JOIN inventory ON r1.inventory_id = inventory.inventory_id JOIN store ON inventory.store_id = store.store_id
        WHERE inventory.store_id=1
    ) t1 JOIN ( --Self join dwóch takich samych tabel, celem porównania dat i policzenia ilości aktywnych wypożyczeń
        SELECT r2.rental_id rid2, r2.rental_date rdy, r2.return_date rtdy
        FROM rental r2 JOIN inventory ON r2.inventory_id = inventory.inventory_id JOIN store ON inventory.store_id = store.store_id
        WHERE inventory.store_id=1
    ) t2 ON t1.rid1 > t2.rid2 --Narzucenie wiekszego ID rekordów pierwszej tabeli (mniejszy rozmiar łączonej tabeli) 
)y
GROUP BY 1 --Grupowanie wg daty
)z  ON x.date = z.date; --Łączenie tabel po dacie(tu: wartości unikatowe)

--Ładowanie danych z widoku do tabeli
INSERT INTO raport
SELECT * FROM raport_vw 
WHERE raport_vw.Date not in (--Sprawdzenie czy nie ma duplikatów
    SELECT Date FROM raport
);


SELECT * FROM raport; -- Sprawdzenie
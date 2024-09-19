CREATE OR REPLACE FUNCTION adjust_building_prices() 
RETURNS VOID AS $$
DECLARE
    real_estateid INTEGER;
    listing_date TIMESTAMP;
    avg_rating NUMERIC;
    current_price NUMERIC;
BEGIN
    FOR real_estateid, listing_date, avg_rating, current_price IN
        SELECT re.real_estate_id, re.listing_date, AVG(ev.score), re.price
        FROM real_estate re
        JOIN evaluation ev ON re.real_estate_id = ev.real_estate_id
		GROUP BY re.real_estate_id, re.listing_date, re.price
    LOOP
        IF age(listing_date::DATE) > INTERVAL '6 months' AND avg_rating < 6 THEN
            UPDATE real_estate
            SET price = current_price * 0.95
            WHERE real_estate_id = real_estateid;
        END IF;
        
        IF age(listing_date::DATE) > INTERVAL '9 months' AND avg_rating < 5 THEN
            UPDATE real_estate
            SET price = current_price * 0.90
            WHERE real_estate_id = real_estateid;
        END IF;

        IF age(listing_date::DATE) > INTERVAL '12 months' AND avg_rating < 4 THEN
            UPDATE real_estate
            SET price = current_price * 0.80
            WHERE real_estate_id = real_estateid;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT adjust_building_prices();
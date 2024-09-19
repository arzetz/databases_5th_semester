CREATE OR REPLACE FUNCTION square_check()
RETURNS void AS $$
DECLARE 
	invalid_address TEXT;
	area_difference REAL;
BEGIN
	FOR invalid_address, area_difference IN
		SELECT re.address, re.area - (
			SELECT SUM(ps.area)
			FROM property_structure ps
			WHERE ps.real_estate_id = re.real_estate_id
		) AS area_difference
		FROM real_estate re
		WHERE re.area <> (
			SELECT SUM(ps.area)
			FROM property_structure ps
			WHERE ps.real_estate_id = re.real_estate_id
		)
	LOOP 
		RAISE NOTICE 'Некорректная площадь для здания по адресу %', invalid_address;
		RAISE NOTICE 'Размер расхождения: %', area_difference;
	END LOOP;
	if not found then
		raise notice 'Некорректных площедей продажи зданий нет';
	end if;
end;

$$ LANGUAGE plpgsql;

SELECT square_check()
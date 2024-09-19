CREATE OR REPLACE FUNCTION select_price_dynamic()
RETURNS TABLE(
    change_date TIMESTAMP,
    new_price REAL,
    price_change REAL,
    change_percent REAL,
    warning text
) AS $$
BEGIN
    RETURN QUERY 
    SELECT pd.change_date, pd.new_price, 
           pd.new_price - re.price::real AS price_change,
           (((pd.new_price - re.price) / re.price) * 100)::real AS change_percent,
CASE
               WHEN ((pd.new_price - re.price) / re.price) * 100 > 10 THEN 'Цена изменилась более чем на 10%'
               ELSE ''
           END AS warning
    FROM price_dynamic pd
    JOIN real_estate re ON pd.real_estate_id = re.real_estate_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM select_price_dynamic();




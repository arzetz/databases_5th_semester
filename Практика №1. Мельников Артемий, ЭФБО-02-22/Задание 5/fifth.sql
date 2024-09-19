create or replace function realtor_commission()
RETURNS VOID AS $$
declare
	sales_price double precision;
begin
	for sales_price in 
	select s.sale_price
	from sale s
	loop
			update sale
			set realtor_commission = 2
			where sale_price < 1000000;

			update sale
			set realtor_commission = 1.9
			where sale_price > 1000000 and sale_price < 3000000;

			update sale
			set realtor_commission = 1.7
			where sale_price > 3000000;

	end loop;
end;
$$ LANGUAGE plpgsql;

select * from realtor_commission()
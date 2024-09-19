create or replace function check_date()
returns void as $$
declare 
	invalid_address text;
begin
	for invalid_address in
		select re.address 
		from real_estate re
		join sale s on re.real_estate_id = s.real_estate_id
		where s.sale_date < re.listing_date
	loop 
		raise notice 'Некорректная дата продажи для здания по адресу %', invalid_address;
	end loop;

	if not found then
		raise notice 'Некорректных дат продажи зданий нет';
	end if;
end;

$$ LANGUAGE plpgsql;

select check_date();
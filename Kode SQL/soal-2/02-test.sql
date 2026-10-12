insert into inventory_items values('ITM001','Raket demo',1,2500000)
on conflict(item_id) do update set stock_qty=excluded.stock_qty,unit_cost=excluded.unit_cost;
insert into inventory_transactions(item_id,trx_type,qty) values('ITM001','PURCHASE',2);
select * from inventory_items where item_id='ITM001'; -- stok 3
insert into inventory_transactions(item_id,trx_type,qty) values('ITM001','SALE',1);
select * from inventory_items where item_id='ITM001'; -- stok 2
select * from inventory_movement_audit order by audit_id;
-- Uji terpisah: harus gagal dan transaksi batal
-- insert into inventory_transactions(item_id,trx_type,qty) values('ITM001','SALE',99);

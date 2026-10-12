create table if not exists inventory_items(
 item_id varchar(10) primary key, item_name varchar(100),
 stock_qty int not null default 0 check(stock_qty>=0),
 unit_cost numeric(15,2) not null check(unit_cost>=0)
);
create table if not exists inventory_transactions(
 trx_id serial primary key,
 item_id varchar(10) not null references inventory_items(item_id) on delete restrict,
 trx_type varchar(10) not null check(trx_type in ('PURCHASE','SALE','ADJUSTMENT')),
 qty int not null check(qty<>0), trx_date timestamp not null default current_timestamp
);
create table if not exists inventory_movement_audit(
 audit_id bigserial primary key, trx_id int not null references inventory_transactions(trx_id) on delete restrict,
 item_id varchar(10) not null, trx_type varchar(10) not null, qty_delta int not null,
 stock_after int not null, movement_value numeric(15,2) not null, created_at timestamptz default now()
);
create or replace function trg_update_stock_and_journal()
returns trigger language plpgsql as $$
declare old_stock int; delta int; cost numeric(15,2); new_stock int;
begin
 select stock_qty,unit_cost into old_stock,cost from inventory_items
 where item_id=new.item_id for update;
 if not found then raise exception 'Item % tidak ditemukan',new.item_id; end if;
 if new.trx_type in ('PURCHASE','SALE') and new.qty<=0 then
  raise exception 'Qty PURCHASE/SALE harus positif';
 end if;
 if new.trx_type='PURCHASE' then delta:=new.qty;
 elsif new.trx_type='SALE' then delta:=-new.qty;
 else delta:=new.qty; -- ADJUSTMENT positif menambah, negatif mengurangi
 end if;
 new_stock:=old_stock+delta;
 if new_stock<0 then raise exception 'Stok tidak cukup: stok %, perubahan %',old_stock,delta; end if;
 update inventory_items set stock_qty=new_stock where item_id=new.item_id;
 insert into inventory_movement_audit(trx_id,item_id,trx_type,qty_delta,stock_after,movement_value)
 values(new.trx_id,new.item_id,new.trx_type,delta,new_stock,abs(delta)*cost);
 -- Untuk jurnal GL resmi, perlu tabel akun/header/line dan mapping akun Persediaan/HPP.
 return new;
end $$;
drop trigger if exists after_inventory_trx_insert on inventory_transactions;
create trigger after_inventory_trx_insert after insert on inventory_transactions
for each row execute function trg_update_stock_and_journal();

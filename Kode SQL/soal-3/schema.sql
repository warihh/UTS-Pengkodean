create extension if not exists pgcrypto;
create table if not exists cash_accounts(
 account_code text primary key, account_name text not null,
 account_type text not null check(account_type in ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE')),
 is_active boolean not null default true
);
create table if not exists cash_vouchers(
 id uuid primary key default gen_random_uuid(), voucher_no text not null unique,
 voucher_date date not null, description text not null,
 status text not null default 'DRAFT' check(status in ('DRAFT','POSTED','REVERSED')),
 total_debit numeric(15,2) not null default 0, total_credit numeric(15,2) not null default 0,
 created_by uuid default auth.uid(), created_at timestamptz not null default now(),
 hash_checksum text, reversed_from uuid references cash_vouchers(id) on delete restrict
);
create table if not exists cash_voucher_lines(
 id bigint generated always as identity primary key,
 voucher_id uuid not null references cash_vouchers(id) on delete restrict,
 line_no int not null, account_code text not null references cash_accounts(account_code) on delete restrict,
 line_description text, debit numeric(15,2) not null default 0 check(debit>=0),
 credit numeric(15,2) not null default 0 check(credit>=0),
 check((debit>0 and credit=0) or (credit>0 and debit=0)), unique(voucher_id,line_no)
);
create table if not exists cash_voucher_audit(
 audit_id bigint generated always as identity primary key, voucher_id uuid not null,
 action text not null, actor uuid default auth.uid(), action_at timestamptz not null default now(),
 details jsonb not null default '{}'::jsonb
);
create or replace function protect_posted_voucher() returns trigger language plpgsql as $$
begin
 if old.status='POSTED' then raise exception 'Voucher POSTED immutable; gunakan reversing entry'; end if;
 return coalesce(new,old);
end $$;
drop trigger if exists protect_voucher on cash_vouchers;
create trigger protect_voucher before update or delete on cash_vouchers
for each row execute function protect_posted_voucher();
create or replace function protect_posted_voucher_lines() returns trigger language plpgsql as $$
declare vid uuid; st text;
begin
 vid:=coalesce(new.voucher_id,old.voucher_id);
 select status into st from cash_vouchers where id=vid;
 if st='POSTED' then raise exception 'Baris voucher POSTED tidak dapat diubah/dihapus'; end if;
 return coalesce(new,old);
end $$;
drop trigger if exists protect_lines on cash_voucher_lines;
create trigger protect_lines before update or delete on cash_voucher_lines
for each row execute function protect_posted_voucher_lines();

create or replace function post_cash_voucher(p_voucher_no text,p_voucher_date date,p_description text,p_lines jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare vid uuid; d numeric(15,2); c numeric(15,2); n int; payload text; checksum text;
begin
 if jsonb_typeof(p_lines)<>'array' then raise exception 'Baris harus berupa array JSON'; end if;
 select count(*),coalesce(sum((x->>'debit')::numeric),0),coalesce(sum((x->>'credit')::numeric),0)
 into n,d,c from jsonb_array_elements(p_lines) x;
 if n<2 or d<=0 or d<>c then raise exception 'Jurnal tidak seimbang/minimal dua baris: debit %, kredit %',d,c; end if;
 if exists(select 1 from jsonb_array_elements(p_lines) x where coalesce(x->>'account_code','')=''
  or not (((coalesce((x->>'debit')::numeric,0)>0) and coalesce((x->>'credit')::numeric,0)=0)
  or ((coalesce((x->>'credit')::numeric,0)>0) and coalesce((x->>'debit')::numeric,0)=0)))
 then raise exception 'Setiap baris harus memiliki akun dan tepat satu sisi nominal positif'; end if;
 insert into cash_vouchers(voucher_no,voucher_date,description,status,total_debit,total_credit)
 values(p_voucher_no,p_voucher_date,p_description,'DRAFT',d,c) returning id into vid;
 insert into cash_voucher_lines(voucher_id,line_no,account_code,line_description,debit,credit)
 select vid,row_number() over()::int,x->>'account_code',x->>'line_description',
 (x->>'debit')::numeric,(x->>'credit')::numeric from jsonb_array_elements(p_lines) x;
 payload:=p_voucher_no||'|'||p_voucher_date::text||'|'||p_description||'|'||d::text||'|'||c::text||'|'||p_lines::text;
 checksum:=encode(digest(payload,'sha256'),'hex');
 update cash_vouchers set status='POSTED',hash_checksum=checksum where id=vid;
 insert into cash_voucher_audit(voucher_id,action,details)
 values(vid,'POSTED',jsonb_build_object('hash_checksum',checksum,'total_debit',d,'total_credit',c));
 return vid;
end $$;
alter table cash_accounts enable row level security;
alter table cash_vouchers enable row level security;
alter table cash_voucher_lines enable row level security;
alter table cash_voucher_audit enable row level security;
create policy "demo read accounts" on cash_accounts for select to anon,authenticated using(true);
create policy "demo read vouchers" on cash_vouchers for select to anon,authenticated using(true);
create policy "demo read lines" on cash_voucher_lines for select to anon,authenticated using(true);
create policy "demo read audit" on cash_voucher_audit for select to anon,authenticated using(true);
grant execute on function post_cash_voucher(text,date,text,jsonb) to anon,authenticated;
insert into cash_accounts values
('1010','Kas/Bank','ASSET',true),('5010','Beban Operasional','EXPENSE',true),
('2010','Utang Usaha','LIABILITY',true),('6010','Beban Perlengkapan','EXPENSE',true)
on conflict(account_code) do nothing;

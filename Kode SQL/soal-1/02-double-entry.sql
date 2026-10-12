-- CHECK tidak dapat menjumlahkan beberapa baris. Deferred constraint trigger memeriksa saat COMMIT.
create or replace function assert_posted_journal_balanced()
returns trigger language plpgsql as $$
declare h_id bigint; st text; n int; d numeric(15,2); c numeric(15,2);
begin
 if tg_table_name='journal_headers' then h_id:=coalesce(new.id,old.id);
 else h_id:=coalesce(new.header_id,old.header_id); end if;
 select posting_status into st from journal_headers where id=h_id;
 if not found then return null; end if;
 if st='POSTED' then
  select count(*),coalesce(sum(debit),0),coalesce(sum(credit),0)
  into n,d,c from journal_lines where header_id=h_id;
  if n<2 then raise exception 'Jurnal % minimal dua baris',h_id; end if;
  if d<>c then raise exception 'Jurnal % tidak seimbang: debit %, kredit %',h_id,d,c; end if;
 end if;
 return null;
end $$;
drop trigger if exists ct_journal_header_balance on journal_headers;
create constraint trigger ct_journal_header_balance after insert or update on journal_headers
deferrable initially deferred for each row execute function assert_posted_journal_balanced();
drop trigger if exists ct_journal_line_balance on journal_lines;
create constraint trigger ct_journal_line_balance after insert or update or delete on journal_lines
deferrable initially deferred for each row execute function assert_posted_journal_balanced();

insert into chart_of_accounts values
('1010','Kas','DEBIT','ASSET'),('4010','Pendapatan','CREDIT','REVENUE')
on conflict(account_code) do nothing;

-- Uji seimbang: seharusnya COMMIT berhasil.
begin;
insert into journal_headers(reference_no,description) values('UJI-OK-001','Uji seimbang') returning id \gset
insert into journal_lines(header_id,account_code,debit,credit) values
(:id,'1010',100000,0),(:id,'4010',0,100000);
update journal_headers set posting_status='POSTED' where id=:id;
commit;

-- Jalankan blok tidak seimbang secara terpisah; COMMIT harus gagal.
-- begin;
-- insert into journal_headers(reference_no,description) values('UJI-FAIL-001','Uji tidak seimbang') returning id \gset
-- insert into journal_lines(header_id,account_code,debit,credit) values
-- (:id,'1010',100000,0),(:id,'4010',0,90000);
-- update journal_headers set posting_status='POSTED' where id=:id;
-- commit;

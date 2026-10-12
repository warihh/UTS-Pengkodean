create table if not exists chart_of_accounts (
 account_code varchar(20) primary key,
 account_name varchar(120) not null unique,
 normal_balance varchar(6) not null check(normal_balance in ('DEBIT','CREDIT')),
 report_class varchar(30) not null check(report_class in ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE'))
);
create table if not exists journal_headers (
 id bigserial primary key,
 transaction_date date not null default current_date,
 reference_no varchar(50) not null unique,
 description text not null,
 posting_status varchar(10) not null default 'DRAFT' check(posting_status in ('DRAFT','POSTED','REVERSED')),
 created_at timestamptz not null default now(),
 created_by text not null default current_user
);
create table if not exists journal_lines (
 id bigserial primary key,
 header_id bigint not null references journal_headers(id) on delete restrict,
 account_code varchar(20) not null references chart_of_accounts(account_code) on delete restrict,
 debit numeric(15,2) not null default 0 check(debit >= 0),
 credit numeric(15,2) not null default 0 check(credit >= 0),
 check(debit > 0 or credit > 0),
 check(debit = 0 or credit = 0)
);

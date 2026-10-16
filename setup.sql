-- Paste this whole file in Supabase > SQL Editor > Run
create table profiles(id uuid primary key references auth.users on delete cascade,name text,college text,course text,phone text,email text,role text default 'student');
create table cvs(id uuid primary key default gen_random_uuid(),user_id uuid references profiles(id) on delete cascade,name text,path text,ats_score int,ats_feedback text,created_at timestamptz default now());
create table opportunities(id uuid primary key default gen_random_uuid(),title text,company text,location text,duration text,pay_type text,logo_url text,apply_link text,created_at timestamptz default now());
create table batches(id uuid primary key default gen_random_uuid(),course_name text,mentor_name text,mentor_about text,mentor_cv_url text,duration text,price text,start_date date,form_link text,created_at timestamptz default now());
create table updates(id uuid primary key default gen_random_uuid(),text text,created_at timestamptz default now());
create table applications(id uuid primary key default gen_random_uuid(),user_id uuid references profiles(id) on delete cascade,opportunity_id uuid references opportunities(id) on delete cascade,cv_id uuid references cvs(id) on delete set null,created_at timestamptz default now());

create function is_admin() returns boolean language sql security definer as $$select exists(select 1 from profiles where id=auth.uid() and role='admin')$$;
create function handle_new_user() returns trigger language plpgsql security definer as $$
begin insert into profiles(id,name,college,course,phone,email) values(new.id,new.raw_user_meta_data->>'name',new.raw_user_meta_data->>'college',new.raw_user_meta_data->>'course',new.raw_user_meta_data->>'phone',new.email); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function handle_new_user();

alter table profiles enable row level security;alter table cvs enable row level security;alter table opportunities enable row level security;alter table batches enable row level security;alter table updates enable row level security;alter table applications enable row level security;
create policy p1 on profiles for select using(id=auth.uid() or is_admin());
create policy p2 on profiles for update using(id=auth.uid()) with check(id=auth.uid() and role='student');
create policy c1 on cvs for select using(user_id=auth.uid() or is_admin());
create policy c2 on cvs for insert with check(user_id=auth.uid());
create policy c3 on cvs for update using(user_id=auth.uid());
create policy c4 on cvs for delete using(user_id=auth.uid());
create policy a1 on applications for select using(user_id=auth.uid() or is_admin());
create policy a2 on applications for insert with check(user_id=auth.uid());
create policy o1 on opportunities for select to authenticated using(true);
create policy o2 on opportunities for all using(is_admin()) with check(is_admin());
create policy b1 on batches for select to authenticated using(true);
create policy b2 on batches for all using(is_admin()) with check(is_admin());
create policy u1 on updates for select to authenticated using(true);
create policy u2 on updates for all using(is_admin()) with check(is_admin());

insert into storage.buckets(id,name,public) values('cvs','cvs',false),('public','public',true);
create policy s1 on storage.objects for insert to authenticated with check(bucket_id='cvs' and (storage.foldername(name))[1]=auth.uid()::text);
create policy s2 on storage.objects for select to authenticated using(bucket_id='cvs' and ((storage.foldername(name))[1]=auth.uid()::text or is_admin()));
create policy s3 on storage.objects for insert to authenticated with check(bucket_id='public' and is_admin());
create policy s4 on storage.objects for select using(bucket_id='public');

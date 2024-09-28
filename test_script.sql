drop table if exists tasks;
drop table if exists pipeline;
drop sequence if exists seq_id;

ALTER SYSTEM SET autovacuum_analyze_scale_factor = 0.01;
ALTER SYSTEM SET autovacuum_analyze_threshold = 100;
SELECT pg_reload_conf();

create table pipeline (id bigint primary key, status text, creation_time timestamptz);
create index on pipeline (status, creation_time);

create table tasks (id bigint primary key, pipeline_id bigint, status text, creation_time timestamptz);
alter table public.tasks add constraint tasks_fk foreign key (pipeline_id) references public.pipeline(id);
create index on tasks (pipeline_id);
create index on tasks (status, creation_time);

create sequence seq_id;

do $$
declare
 ids_list bigint[];
begin
  WITH ins AS (
  insert into pipeline(id, status, creation_time)
    select nextval('seq_id'), 'COMPLETED', now() from generate_series(1,1000000,1)
  returning id)
  select array_agg(id) INTO ids_list from ins;
  commit;

  FOR i IN 1 .. array_upper(ids_list, 1) loop
    insert into tasks(id, pipeline_id, status, creation_time)
      select nextval('seq_id') id, ids_list[i], 'COMPLETED' status, now() creation_time
        from generate_series(1, 5, 1);
  end loop;
  commit;
end $$;


create or replace procedure make_worse()
language plpgsql
as $$
declare
  id_pipeline bigint;
  id_task bigint;
  cnt_pipeline int;
begin
  for i in 1..2000 loop
    insert into pipeline
      values (nextval('seq_id'), 'STARTED', now())
      returning id into id_pipeline;
    insert into tasks(id, pipeline_id, status, creation_time)
      select nextval('seq_id') id, id_pipeline pipeline_id, 'NEW' status, now() creation_time
        from generate_series(1, 5, 1);
    commit;
  end loop;
end; $$

EXPLAIN ANALYZE SELECT t.id, p.id FROM tasks t,pipeline p WHERE t.status = 'NEW' AND t.pipeline_id = p.id AND p.status = 'STARTED';
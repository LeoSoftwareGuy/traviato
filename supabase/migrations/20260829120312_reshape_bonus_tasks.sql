-- Reshape bonus_task_templates / bonus_task_assignments for the daily-tray
-- mechanic (docs/data-model.md v4, docs/functionality.md §12). Amends the
-- tables created in #27 (create_bonus_tasks) — that migration is merged and
-- immutable, so this is a follow-up alter. Part of #31.
--
-- Both tables are empty in prod (the bonus tasks feature hasn't shipped
-- client-side yet), so dropping/adding not-null columns directly is safe —
-- no backfill or truncate needed.
--
-- Down/revert notes: re-add `duration_hours int not null check (> 0)`,
-- `trigger text not null check (in ('trip_start','random'))`, rename
-- `detail` back to `description not null`, drop `code`/`phase`/`kind` from
-- bonus_task_templates; on bonus_task_assignments, drop `day_date` and the
-- unique constraint, re-add `status`/`expires_at`.

alter table public.bonus_task_templates
  drop column duration_hours,
  drop column trigger;

-- rename must be its own statement — Postgres doesn't allow RENAME COLUMN
-- combined with other actions in one ALTER TABLE.
alter table public.bonus_task_templates
  rename column description to detail;

alter table public.bonus_task_templates
  alter column detail drop not null;

alter table public.bonus_task_templates
  add column code text,
  add column phase text,
  add column kind text;

-- Backfilled by the reseed migration that follows; the unique/not-null/check
-- constraints are added here so the seed migration is forced to satisfy them.
update public.bonus_task_templates set code = 'legacy_' || id::text
where code is null;

alter table public.bonus_task_templates
  alter column code set not null,
  add constraint bonus_task_templates_code_key unique (code),
  add constraint bonus_task_templates_phase_check
    check (phase in ('arrival', 'middle', 'departure', 'anytime')),
  add constraint bonus_task_templates_kind_check
    check (kind in ('regular', 'starter', 'stretch', 'milestone', 'streak_saver'));

-- RLS is unchanged in spirit: bonus_task_templates stays select-only for
-- authenticated (policy "bonus_task_templates_select_all" from #27 still
-- applies — altering columns doesn't touch policies or grants).

alter table public.bonus_task_assignments
  drop column status,
  drop column expires_at,
  add column day_date date;

-- Same empty-table reasoning as above; nothing to backfill in prod.
alter table public.bonus_task_assignments
  alter column day_date set not null,
  add constraint bonus_task_assignments_trip_template_day_key
    unique (trip_id, template_id, day_date);

-- RLS is unchanged in spirit: bonus_task_assignments stays owner-only via
-- the parent trip (policies "bonus_task_assignments_{select,insert,update,
-- delete}_own" from #27 still apply unchanged).

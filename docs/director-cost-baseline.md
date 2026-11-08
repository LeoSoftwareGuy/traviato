# Director cost baseline (Wrap-Up Film v2)

What the director (#328) really costs per memory, measured on the hosted project so
the same memories can be compared after upgrading to **Supabase Pro**.

The one thing that changes on Pro: the photo-analysis call gets **~512px Storage renders**
instead of the **full-size files** (#333 picks this automatically). The plan call
doesn't see images, so its cost shouldn't change.

## Setup at the time of measuring

| | |
|---|---|
| Date | 2026-11-08 |
| Supabase plan | Free: no image transforms, so photos go to Anthropic **full size** |
| Model (both calls) | `claude-sonnet-5`, $2 / $10 per MTok in / out (`PRICE_PER_MTOK`, `director.ts`) |
| Analysis | Batches of 20 photos, at most 120 photos per memory (`MAX_ANALYSED_PHOTOS`), cached per photo |
| Code | `main` after #337 |

## Baseline: first run per memory (analysis + plan)

The first run pays for analysing every photo. Later runs only pay for the plan.

| Memory | Days | Photos (total / analysed) | Analysis in / out tokens | **Input tokens per photo** | Analysis cost | Plan attempts | Plan in / out tokens | Plan cost | **Total** |
|---|---|---|---|---|---|---|---|---|---|
| Оман | 10 | 194 / 119 (+1 failed, 120 sent) | 579,286 / 13,535 | **~4,830** | $1.294 | 1 | 24,151 / 3,475 | $0.083 | **$1.377** |
| Мое день рождение, 29 | 2 | 21 / 21 | 89,932 / 2,412 | **~4,280** | $0.204 | 2 | 12,492 / 2,880 | $0.054 | **$0.258** |
| ADE-Amsterdam 2026 | 3 | 30 / 28 | ~132,600 / ~3,550 ¹ | **~4,740** ¹ | ~$0.30 ¹ | 2 | ~15,900 / ~4,170 ¹ | ~$0.074 ¹ | **$0.374** |

¹ Amsterdam's first run was only logged as one total (148,531 in / 7,718 out, $0.3742).
The split assumes its two plan calls were the same size as its later two-attempt rerun (15,895 / 4,171).

**Bottom line:** full-size photos cost **~4,300–4,800 input tokens per photo**, about
**$0.01 per photo**. That's ~$1.30 for a memory at the 120-photo cap.

## Baseline: plan-only reruns (analysis cached)

| Memory | Plan attempts | In / out tokens | Cost |
|---|---|---|---|
| ADE-Amsterdam 2026 | 2 | 15,895 / 4,171 | $0.074 |
| Мое день рождение, 29 | 1 | 6,192 / 1,460 | $0.027 |
| Оман | 1 | 24,151 / 3,475 | $0.083 |

## How to compare after upgrading to Pro

1. **Confirm 512px renders are used.** After the upgrade, a director run should cost far
   less per photo. If it doesn't, check that image transformations are enabled for the project in the
   Supabase dashboard.
2. **Make the director analyse photos again.** Analyses are cached per photo, so rerunning
   these memories on Pro would only pay for the plan and show nothing new. Either:
   - run the director on a memory that has **never been analysed** (simplest), or
   - delete one memory's cached rows, which is a write to the live database (dashboard
     SQL editor, owner's decision):
     `delete from photo_analysis where trip_id = '<trip id>';`
     then **Re-run director** in the Plan inspector.
3. **Read the result** with the query below and fill in a "Pro" row next to the baseline.
   Compare **input tokens per photo** (analysis input ÷ photos sent). That number
   isolates the image-size effect.

```sql
-- Latest director run per memory: photos, per-call tokens, cost.
select t.name,
       t.start_date, t.end_date,
       (select count(*) from photos p where p.trip_id = t.id)  as photos_total,
       w.director->>'ran_at'                                   as ran_at,
       w.director->>'status'                                   as status,
       w.director->'attempts'                                  as attempts,
       w.director->'photos'                                    as photos,
       w.director->'usage'->'calls'                            as calls,
       w.director->'usage'->'estimated_usd'                    as usd
from wrap_ups w
join trips t on t.id = w.trip_id
where w.director is not null
order by w.director->>'ran_at' desc;
```

`director.usage.calls` lists each Anthropic call (`analysis` / `plan`) with its tokens.
Only the latest run per memory is stored. Older runs are only in the `generate_wrap_up`
logs (`director_usage` lines).

## Pro results

_To fill in after the upgrade._

| Memory | Photos sent | Analysis in / out tokens | Input tokens per photo | Analysis cost | Total |
|---|---|---|---|---|---|
| | | | | | |

# dbt Tests

## Overview

dbt has three testing concepts:
- **Data Tests** — test data integrity and quality on the actual data
- **Unit Tests** — test transformations with small mock data you provide (no warehouse needed)
- **Contracts** — enforce the schema of a model (column names, types, constraints)

---

## Commands

```
dbt test                                    -> Run all tests (generic + singular + unit)
dbt test -x                                 -> Fail-fast: stop after the first failure
dbt test -s dim_listings_cleansed           -> Run tests for a specific model
dbt test -s dim_listings_minimum_nights     -> Run a specific singular test
dbt test --select source:airbnb.listings    -> Run tests for a specific source
dbt --debug test --select dim_listings_w_hosts -> Run with verbose debug output
```

---

## 1. Data Tests

### 1a. Generic Tests

Built-in tests applied to columns in a YAML file. There are **4 built-in types**:

| Test | Description |
|------|-------------|
| `unique` | All values in the column must be unique |
| `not_null` | No null values allowed |
| `accepted_values` | Column values must be within a defined list |
| `relationships` | Column value must exist in another model (like a foreign key) |

**Example — `models/schema.yml`:**
```yaml
models:
  - name: dim_listings_cleansed
    columns:
      - name: listing_id
        data_tests:
          - unique
          - not_null
      - name: host_id
        data_tests:
          - not_null
          - relationships:
              arguments:
                to: ref('dim_hosts_cleansed')
                field: host_id
      - name: room_type
        data_tests:
          - accepted_values:
              arguments:
                values: ['Entire home/apt', 'Private room', 'Shared room', 'Hotel room']
```

> **Note:** `data_tests` was historically called `tests`. Both work, but `data_tests` is the current standard. Older projects may use `tests` — same behavior, possible deprecation warning.

---

### 1b. Singular Tests

Custom SQL queries stored as `.sql` files in the `tests/` folder.

**Rule:** If the query returns **any row → test fails**. If it returns nothing → test passes.

Add `LIMIT 10` to avoid storing millions of failure records if the test fails at scale.

**Example — `tests/dim_listings_minimum_nights.sql`:**
```sql
SELECT *
FROM {{ ref('dim_listings_cleansed') }}
WHERE minimum_nights < 1
LIMIT 10
```

**Example — `tests/consistent_created_at.sql`:**
```sql
SELECT *
FROM {{ ref('dim_listings_cleansed') }} l
INNER JOIN {{ ref('fct_reviews') }} r USING (listing_id)
WHERE l.created_at > r.review_date
```

---

## 2. Storing Test Failures

By default, dbt only reports failures in the log. You can also **persist failing records** to the warehouse for inspection.

### Enable in `dbt_project.yml`:
```yaml
data_tests:
  +store_failures: true
  +schema: _test_failures   # optional: custom schema name
```

- Each test gets its own table with the failing records
- Default schema: `<target_schema>__dbt_test__audit`
- With `+schema: _test_failures` → schema becomes `<target_schema>___test_failures`
- Useful for production pipelines where you need an audit trail

---

## 3. Unit Tests

Unit tests verify the **transformation logic** of a model using hardcoded mock data — no real warehouse data involved. Works like unit tests in software engineering.

- Place in any `.yml` file (e.g., `models/mart/unit_tests.yml`)
- Provide mock `input` rows and `expected` output rows
- dbt applies the model logic to the mock input and compares with expected output

**Example — `models/mart/unit_tests.yml`:**
```yaml
unit_tests:
  - name: unittest_fullmoon_matcher
    model: mart_fullmoon_reviews
    given:
      - input: ref('fct_reviews')
        rows:
          - {review_date: '2025-01-13'}
          - {review_date: '2025-01-14'}
          - {review_date: '2025-01-15'}
      - input: ref('seed_full_moon_dates')
        rows:
          - {full_moon_date: '2025-01-14'}
    expect:
      rows:
        - {review_date: '2025-01-13', is_full_moon: "not full moon"}
        - {review_date: '2025-01-14', is_full_moon: "not full moon"}
        - {review_date: '2025-01-15', is_full_moon: "full moon"}
```

Run unit tests for a specific model:
```
dbt test -s mart_fullmoon_reviews
```

> Focus unit tests on critical joins and transformations. They catch logic errors early without touching real data.

---

## 4. Contracts

Contracts enforce that a model's output matches an expected schema (column names + data types). If the model doesn't match, the run fails.

**Example — `models/schema.yml`:**
```yaml
  - name: dim_hosts_cleansed
    config:
      contract:
        enforced: true
    columns:
      - name: host_id
        data_type: integer
      - name: host_name
        data_type: string
      - name: is_superhost
        data_type: string
      - name: created_at
        data_type: timestamp
      - name: updated_at
        data_type: timestamp
```

---

## 5. Debugging a Failing Test

1. Run `dbt test` — the failing test shows a long auto-generated name.
2. Go to `target/compiled/<project>/models/` and open the compiled SQL for that test.
3. Copy the SQL and run it directly in Snowflake (or your warehouse).
4. The rows returned = the **failing records**. Inspect them to find the issue.

```
dbt test -x   # stops at first failure, speeds up debugging
```

> Prefer inspecting the compiled SQL over using `--debug` — it's cleaner and more practical.

---

## Where to Define Tests

- YAML files inside `models/` (or any subfolder) — dbt picks them all up automatically.
- Convention: `schema.yml`, but the filename can be anything.
- Unit tests can live in their own `.yml` file alongside the model.
- Keep all tests for a given model in a single YAML file.

---

## Why Test in dbt and Not Just in the Warehouse?

Some data warehouses (Databricks, Athena, Redshift) don't enforce `UNIQUE` or `NOT NULL` constraints at the storage level. dbt tests make data quality checks explicit and portable across platforms.

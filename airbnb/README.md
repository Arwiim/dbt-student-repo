Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices


dbt seed -> Populate only seed folder to snowflake (make a parse automatically in DBT to gues the schema)
dbt compile -> compile full proyect DBT and review every model to work properly
dbt source freshness -> check data freschness in models.
      warn_after: {count: 1, period: hour}   # ⚠️ WARNING si no hay datos nuevos en 1 hora
      #error_after: {count: 24, period: hour} # ❌ ERROR si no hay datos nuevos en 24h (desactivado)
dbt snapshot -> Create new columns for snapshot.
dbt build -> create snapshot, test, tests.
dbt test -> check the schema.yml for testing
dbt test -x -> Fail-fast flag. Stops running tests immediately after the first failure instead of running all tests to completion. Useful for debugging one issue at a time.
dbt test -s dim_listings_minimum_nights.sql -> singles test

snapshots (3 strategies)

**1. timestamp**
Detecta cambios comparando una columna `updated_at`. Si el timestamp es más reciente que el último snapshot, dbt registra una nueva fila con `dbt_valid_from` y cierra la anterior con `dbt_valid_to`. Es la estrategia más eficiente y recomendada cuando la fuente tiene una columna de actualización confiable.
```yaml
strategy: timestamp
updated_at: updated_at
```

**2. check**
No requiere columna de fecha. dbt compara el valor actual de una lista de columnas con el último snapshot. Si cualquier columna cambió, registra una nueva versión del registro. Más costoso computacionalmente porque requiere comparar columna a columna.
```yaml
strategy: check
check_cols: [col1, col2]   # o check_cols: all
```

**3. custom (macro)**
Permite definir una estrategia personalizada a través de un macro en Jinja. Se crea un macro con el nombre `snapshot_<strategy_name>_strategy` que devuelve la lógica SQL para detectar cambios. Útil cuando las dos estrategias nativas no cubren el caso de uso (ej: lógica de negocio especial, múltiples columnas de timestamp, etc.).
```sql
-- macros/my_custom_snapshot_strategy.sql
{% macro snapshot_custom_strategy(node, snapshotted_rel, current_rel, config, target_exists) %}
    ...lógica SQL personalizada...
{% endmacro %}
```
```yaml
strategy: custom



--SCD (Slowly Changing Dimensions) in dbt refers to techniques for tracking and managing historical changes in dimension data, primarily implemented through dbt snapshots. Currently on this course we are using Type 2


dbt Snapshots implement SCD Type 2.

Instead of overwriting records (Type 1) or adding columns for previous values (Type 3), SCD Type 2 inserts a new row for each change while keeping the old row intact, using two metadata columns to track validity:

column	description
dbt_valid_from	timestamp when this version became active
dbt_valid_to	timestamp when it was superseded (NULL = current record)
This gives you a full audit trail of every historical state of a record.
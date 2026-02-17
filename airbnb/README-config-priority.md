# Orden de Prioridad de Configuraciones en dbt

## Jerarquía (de más fuerte a más débil):

### 1. **Config en el archivo SQL** (más fuerte) ⭐
```sql
-- models/dim/dim_hosts_cleansed.sql
{{
  config(
    materialized='incremental'
  )
}}

SELECT * FROM {{ ref('src_hosts') }}
```
**Prioridad:** MÁXIMA - Sobrescribe todo

---

### 2. **Config de carpeta específica en dbt_project.yml**
```yaml
# dbt_project.yml
models:
  airbnb:
    +materialized: view    # Regla general
    
    dim:
      +materialized: table  # Regla específica para carpeta dim/
```
**Prioridad:** ALTA - Sobrescribe config general pero no config en archivo SQL

---

### 3. **Config de nivel superior en dbt_project.yml**
```yaml
# dbt_project.yml
models:
  airbnb:
    +materialized: view  # Se aplica a todo el proyecto
```
**Prioridad:** MEDIA - Es el default del proyecto

---

### 4. **Default de dbt** (más débil)
Si no hay ninguna configuración, dbt usa `view` como default.

**Prioridad:** MÍNIMA

---

## Ejemplo Completo

```yaml
# dbt_project.yml
models:
  airbnb:
    +materialized: view          # Nivel 3: Todo es view por defecto
    
    src:
      +materialized: ephemeral   # Nivel 2: src/ usa ephemeral
    
    dim:
      +materialized: table       # Nivel 2: dim/ usa table
      
    fct:
      +materialized: incremental # Nivel 2: fct/ usa incremental
```

```sql
-- models/dim/dim_hosts_special.sql
{{
  config(
    materialized='view'  -- Nivel 1: Este archivo específico usa view
  )
}}

-- Este modelo será VIEW a pesar de que dim/ está configurado como table
```

---

## Resultado Final

| Modelo | Config archivo | Config carpeta | Config general | Resultado |
|--------|---------------|----------------|----------------|-----------|
| `dim_hosts_cleansed.sql` | ❌ | table | view | **table** |
| `dim_hosts_special.sql` | view | table | view | **view** |
| `src_hosts.sql` | ❌ | ephemeral | view | **ephemeral** |
| `fct_bookings.sql` | incremental | incremental | view | **incremental** |

---

## Regla de Oro

**La configuración MÁS ESPECÍFICA siempre gana.**

Archivo individual > Carpeta específica > Configuración general > Default



dbt run --full-refresh # recrea todas las tablas incrementales

GREATEST retorna el valor más grande (la fecha más reciente) entre las dos columnas.
ej: GREATEST(l.updated_at, h.updated_at) as updated_at



Tipo	Time Travel	Fail-safe	Costo Storage	Uso
PERMANENT (default)	1-90 días	✅ 7 días	💰💰 Alto	Datos críticos
TRANSIENT	0-1 día	❌ No	💰 Medio	Datos temporales/staging
TEMPORARY	0-1 día	❌ No	💰 Medio	Solo sesión actual
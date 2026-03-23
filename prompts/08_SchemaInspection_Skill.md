# 08 — Schema Inspection Skill

## Propósito

Esta guía documenta la `SchemaInspectionSkill`, que permite consultar de forma determinista los
índices de cualquier tabla SQL Server desde un escenario BDD. Es útil para:

- Validar que la base de datos tiene los índices esperados antes o después de una migración.
- Documentar el estado actual de los índices como parte de un suite de regresión.
- Auditar cambios de esquema en pipelines de CI/CD.

---

## Archivos generados

| Archivo | Rol |
|---------|-----|
| `Skills/SchemaInspectionSkill.cs` | Skill con dos funciones de Kernel: `GetTableIndexes` y `GetTableIndexColumns` |
| `StepDefinitions/SchemaInspectionStepDefinitions.cs` | Pasos BDD que invocan la skill y evalúan el resultado |
| `Hooks/TestLifecycleHooks.cs` (modificado) | Registra la skill si hay conexión de base de datos disponible |

---

## Prerequisitos

La skill requiere una conexión SQL Server activa. Se inicializa en el `BeforeScenario` de
`TestLifecycleHooks` únicamente cuando `ResolveDatabaseConnectionStringAsync()` devuelve un valor
no vacío (idéntico al comportamiento de `DatabaseSkill`).

> Sin conexión a base de datos, el DI container no registra la skill y los pasos fallarán
> con un error de resolución de dependencias. Asegúrate de tener configurado el secreto
> AWS o la cadena de conexión directa antes de ejecutar escenarios de inspección de esquema.

---

## Métodos de la Skill

### `GetTableIndexesAsync(tableName, schema?)`

- **KernelFunction:** `GetTableIndexes`
- **Retorno:** JSON array, **uno por índice**, con la siguiente forma:

```json
[
  {
    "schemaName": "dbo",
    "indexName": "XPKTransactions",
    "indexType": "CLUSTERED",
    "isUnique": true,
    "isPrimaryKey": true,
    "keyColumns": ["Transaction_Type_Id", "Transactions_Id"],
    "includedColumns": []
  },
  {
    "schemaName": "dbo",
    "indexName": "IDX9000TransactionsOrdersId",
    "indexType": "NONCLUSTERED",
    "isUnique": false,
    "isPrimaryKey": false,
    "keyColumns": ["Transaction_Type_Id", "Orders_Id", "Contract_Id", "Issue_Id"],
    "includedColumns": ["Order_Type_Id", "Trade_Type_Id", "Trade_Id", "Transactions_Liquidation_Date", "Transactions_Process_Date", "Transactions_Gross", "Transactions_Employee_Id"]
  }
]
```

> El agrupado `keyColumns` / `includedColumns` se realiza en memoria en C# para mantener
> compatibilidad con SQL Server 2008 R2+ (no depende de `STRING_AGG`).

### `GetTableIndexColumnsAsync(tableName, schema?)`

- **KernelFunction:** `GetTableIndexColumns`
- **Retorno:** JSON array crudo, **una fila por columna por índice**, equivalente a lo que
  devuelve directamente el `SELECT` de catálogo. Útil para análisis más detallados o para
  construir aserciones columna a columna.

---

## Consulta SQL interna

```sql
SELECT
    s.name                AS SchemaName,
    i.name                AS IndexName,
    i.type_desc           AS IndexType,
    i.is_unique           AS IsUnique,
    i.is_primary_key      AS IsPrimaryKey,
    ic.key_ordinal        AS KeyOrdinal,
    ic.is_included_column AS IsIncludedColumn,
    ic.index_column_id    AS IndexColumnId,
    c.name                AS ColumnName
FROM sys.tables t
INNER JOIN sys.schemas s
       ON s.schema_id = t.schema_id
INNER JOIN sys.indexes i
       ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic
       ON ic.object_id = t.object_id
      AND ic.index_id   = i.index_id
INNER JOIN sys.columns c
       ON c.object_id  = t.object_id
      AND c.column_id  = ic.column_id
WHERE  t.name           = @TableName
  AND  (@Schema IS NULL OR s.name = @Schema)
  AND  i.index_id       > 0
  AND  i.is_hypothetical = 0
ORDER BY s.name, i.index_id,
         ic.is_included_column, ic.key_ordinal, ic.index_column_id
```

**Parámetros:**

| Parámetro | Tipo SQL | Descripción |
|-----------|----------|-------------|
| `@TableName` | `nvarchar` | Nombre exacto de la tabla (sensible a mayúsculas según collation). |
| `@Schema` | `nvarchar` \| `NULL` | Esquema. Cuando se pasa `NULL`, retorna índices de todos los esquemas. |

---

## Pasos BDD disponibles

### `When` — Activación

```gherkin
# Todos los esquemas
When I inspect the indexes of table "Transactions"

# Esquema específico
When I inspect the indexes of table "Transactions" in schema "dbo"
```

### `Then` — Aserciones

```gherkin
# Contar índices
Then the table should have at least 9 indexes

# Existencia por nombre
Then the index "XPKTransactions" should exist

# Tipo
Then the index "XPKTransactions" should be CLUSTERED
Then the index "IDX9000TransactionsOrdersId" should be NONCLUSTERED

# Propiedades lógicas
Then the index "XPKTransactions" should be unique
Then the index "XPKTransactions" should be the primary key

# Composición de columnas
Then the index "XPKTransactions" should include the key column "Transactions_Id"
Then the index "IDX9000TransactionsOrdersId" should have included column "Transactions_Gross"
```

---

## Escenarios de ejemplo

### Validar índices conocidos de la tabla Transactions (dbo)

```gherkin
Feature: Index regression — dbo.Transactions

  @schema @readonly
  Scenario: dbo.Transactions should have its primary key intact
    When I inspect the indexes of table "Transactions" in schema "dbo"
    Then the table should have at least 9 indexes
    And the index "XPKTransactions" should exist
    And the index "XPKTransactions" should be CLUSTERED
    And the index "XPKTransactions" should be the primary key
    And the index "XPKTransactions" should be unique
    And the index "XPKTransactions" should include the key column "Transactions_Id"

  @schema @readonly
  Scenario: IDX9000TransactionsOrdersId should cover key query columns
    When I inspect the indexes of table "Transactions" in schema "dbo"
    Then the index "IDX9000TransactionsOrdersId" should exist
    And the index "IDX9000TransactionsOrdersId" should be NONCLUSTERED
    And the index "IDX9000TransactionsOrdersId" should include the key column "Orders_Id"
    And the index "IDX9000TransactionsOrdersId" should have included column "Transactions_Gross"
```

### Validar índices del esquema NotaEstructurada

```gherkin
  @schema @readonly
  Scenario: NotaEstructurada.Transactions should have its PK and composite indexes
    When I inspect the indexes of table "Transactions" in schema "NotaEstructurada"
    Then the table should have at least 5 indexes
    And the index "PK__Transact__3214EC07C0A5ADF5" should be the primary key
    And the index "IDX_001_Issue_Type" should exist
    And the index "IX_Transactions_Contract_ProcessDate" should exist
```

---

## Integración con el orquestador IA

La función `GetTableIndexes` está registrada como `KernelFunction` con el plugin name
`SchemaInspection`. El orquestador puede invocarla automáticamente cuando recibe instrucciones
como:

```gherkin
When I instruct the AI to "inspect the indexes of the Transactions table in schema dbo"
Then the AI action should succeed
```

## Lectura estandar de resultados de BD

Para mantener consistencia entre consultas SQL directas y consultas de catalogo, cualquier JSON
de respuesta de base de datos debe parsearse usando `DatabaseQueryResultDto`.

Esto permite:

- Manejo uniforme de payloads `array` y `object`.
- Lectura tipada por campo con `GetValue<T>(...)`.
- Normalizacion de strings con padding usando `GetString(...)`.

---

## Resumen de índices actuales — `db1sob`

> Capturado el **2026-03-20** sobre el ambiente `DEV` (`172.20.2.116,1433`).

### `dbo.Transactions` — 9 índices

| Nombre | Tipo | Único | PK | Columnas clave |
|--------|------|-------|----|----------------|
| `XPKTransactions` | CLUSTERED | ✅ | ✅ | Transaction_Type_Id, Transactions_Id |
| `IDX9000TransactionsOrdersId` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Orders_Id, Contract_Id, Issue_Id |
| `NewIdX90007Transactions` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Contract_Id, Order_Type_Id, Transactions_Process_Date |
| `IDX9000Transactionsliquidation` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Transactions_Liquidation_Date, Contract_Id, Issue_Id |
| `idx9000TransactionAlarmaCruce` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Trade_Id, Issue_Id, Transactions_Process_Date, Trade_Type_Id |
| `X2Transactions` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Contract_Id, Issue_Id, Transactions_Process_Date, Transactions_Liquidation_Date, Orders_Id |
| `X6Transactions_shigkm` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Issue_Id, Transactions_Liquidation_Date |
| `X9Transactions_shigkm` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Contract_Id, Transactions_Process_Date, Order_Type_Id |
| `X3Transactions` | NONCLUSTERED | ❌ | ❌ | Transaction_Type_Id, Transactions_Process_Date, Contract_Id, Issue_Id, Orders_Id |

### `NotaEstructurada.Transactions` — 5 índices

| Nombre | Tipo | Único | PK | Columnas clave |
|--------|------|-------|----|----------------|
| `PK__Transact__3214EC07C0A5ADF5` | CLUSTERED | ✅ | ✅ | Id |
| `IDX_001_Issue_Type` | NONCLUSTERED | ❌ | ❌ | Issue_Id, Transac_Type_Id |
| `IDX_001_Mat_Date_Type` | NONCLUSTERED | ❌ | ❌ | Maturity_Date, Transac_Type_Id |
| `IDX_001_Setlmt_Date_Type` | NONCLUSTERED | ❌ | ❌ | Settlement_Date, Transac_Type_Id |
| `IX_Transactions_Contract_ProcessDate` | NONCLUSTERED | ❌ | ❌ | Contract_Id, Process_Date |

---

## Referencia cruzada

| Documento | Relación |
|-----------|----------|
| [07e_Database_Implementation.md](07e_Database_Implementation.md) | Implementación base de `DatabaseSkill` |
| [07b_Database_Steps_Reference.md](07b_Database_Steps_Reference.md) | Catálogo de pasos de base de datos existentes |
| [07c_Database_Scenario_Patterns.md](07c_Database_Scenario_Patterns.md) | Patrones de escenarios de base de datos |
| [05_AWS_SSO_Setup.md](05_AWS_SSO_Setup.md) | Configuración de credenciales para conexión SQL |

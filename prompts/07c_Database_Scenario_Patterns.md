# 07c — Database Scenario Patterns

**Tipo:** Referencia  
**Depende de:** `07_Database_Skill.md`, `07b_Database_Steps_Reference.md`

Este archivo documenta patrones recomendados para escribir escenarios con base de datos, incluyendo setup, validacion, teardown, tagging y casos excepcionales de routing AI.

## Alcance

1. Estandariza patrones repetibles de escenarios con DB.
2. Separa usos recomendados de usos excepcionales del orquestador AI.
3. Propone tags y filtros operativos para ordenar la suite.

## Limites

1. No redefine el catalogo de pasos; ese contrato vive en `07b_Database_Steps_Reference.md`.
2. No redefine la implementacion de `DatabaseSkill`; eso vive en `07e_Database_Implementation.md`.
3. No reemplaza criterios de arquitectura general ni configuracion base.

---

## Decision: ¿pasos directos o AI?

| Criterio | Pasos directos (`DatabaseStepDefinitions`) | Orquestador AI (`When I instruct the AI to`) |
|---|---|---|
| **El SQL lo escribe...** | Tú, en el `.feature` | El LLM, infiriéndolo |
| **Determinismo** | ✅ Siempre el mismo SQL | ⚠️ Puede variar entre ejecuciones |
| **Velocidad** | ✅ Sin llamada al LLM | Más lento (consume tokens) |
| **¿Para que sirve?** | Validar datos reales en BD | Validar que el LLM elige la operacion correcta |
| **Recomendación** | **Usar siempre que sea posible** | Solo para tests de comportamiento del agente |

> ⚠️ No uses el orquestador AI para consultas de validacion de datos. Si el LLM
> genera SQL incorrecto (tabla inexistente, columna mal escrita), el test falla por
> razones ajenas a lo que quieres probar.

---

## Pattern 1 — Setup → Validar → Teardown (más común)

Para cualquier test que inserta datos de prueba y luego los limpia.

```gherkin
Scenario: New user is persisted correctly
  # Setup — insertar dato de prueba directamente
  When I execute the SQL command "INSERT INTO Users (Name, Email, IsActive) VALUES (@name, @email, 1)" with parameters
    | Parameter | Value          |
    | name      | TestUser       |
    | email     | test@test.com  |
  Then the SQL command should affect 1 row

  # Validar — consultar el registro que acabas de insertar
  When I execute the SQL query "SELECT Name, Email FROM Users WHERE Email = @email" with parameters
    | Parameter | Value          |
    | email     | test@test.com  |
  Then the database query should return at least 1 row
  And the database result should contain "TestUser"

  # Teardown — limpiar exactamente lo que insertaste
  When I execute the SQL command "DELETE FROM Users WHERE Email = @email" with parameters
    | Parameter | Value          |
    | email     | test@test.com  |
  Then the SQL command should affect 1 row
```

---

## Pattern 2 — Solo lectura (verificacion de estado)

Para validar que un proceso externo persiste datos correctamente.

```gherkin
Scenario: Order processing service marks order as Shipped
  # El sistema bajo prueba ya ejecutó el procesamiento

  # Verificar el estado resultante en BD
  When I execute the SQL query "SELECT Status FROM Orders WHERE OrderId = @id" with parameters
    | Parameter | Value |
    | id        | 1001  |
  Then the database result should contain "Shipped"
```

---

## Pattern 3 — Stored Procedure con validación

```gherkin
Scenario: Get orders by customer returns only that customer records
  When I execute the stored procedure "dbo.usp_GetOrdersByCustomer" with parameters
    | Parameter  | Value |
    | customerId | 5     |
  Then the database query should return at least 1 row
  And the database result should contain "\"CustomerId\":5"
```

---

## Pattern 4 — Seed masivo con Background

Útil cuando varios scenarios del mismo feature necesitan los mismos datos de base.

```gherkin
Feature: Order reporting

  Background:
    # Se ejecuta antes de cada Scenario del feature
    When I execute the SQL script file "Scripts/seed_test_orders.sql"
    Then the database result should contain "totalAffectedRows"

  Scenario: Report includes all seeded orders
    When I execute the SQL query "SELECT COUNT(*) AS Total FROM Orders WHERE IsTest = 1"
    Then the database result should contain "Total"

  Scenario: Filter by status works correctly
    When I execute the SQL query "SELECT * FROM Orders WHERE IsTest = 1 AND Status = @status" with parameters
      | Parameter | Value   |
      | status    | Pending |
    Then the database query should return at least 1 row
```

El script `Scripts/seed_test_orders.sql` debe estar marcado como `CopyToOutputDirectory` en el `.csproj`:

```xml
<ItemGroup>
  <None Update="Scripts\*.sql">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
  </None>
</ItemGroup>
```

---

## Pattern 5 — Paginación desde C# (BuildSelectAndExecuteAsync)

Cuando necesitas OFFSET/FETCH, crea un paso propio en una clase `[Binding]`
y llama a `BuildSelectAndExecuteAsync` desde C#.

```csharp
// En tu clase de steps personalizada
[When(@"I query orders page (\d+) with (\d+) per page")]
public async Task QueryOrdersPageAsync(int page, int pageSize)
{
    _ctx.LastSkillResult = await _db.BuildSelectAndExecuteAsync(
        columns:             "Id, CustomerId, Status, CreatedAt",
        tableName:           "dbo.Orders",
        whereClause:         "IsActive = @active",
        whereParametersJson: "{\"active\": 1}",
        orderBy:             "CreatedAt DESC",
        skip:                (page - 1) * pageSize,
        take:                pageSize
    );
}
```

```gherkin
Scenario: Orders endpoint returns second page correctly
  When I query orders page 2 with 20 per page
  Then the database query should return at least 1 row
```

---

## Pattern 6 — Test de comportamiento del agente AI (excepcional)

Solo cuando el objetivo del test **es** verificar que el LLM enruta correctamente.

```gherkin
@ai-routing
Scenario: AI selects QueryAsync for a read operation
  # El objetivo es probar el routing del LLM, no los datos
  When I instruct the AI to "run a select query: SELECT * FROM Orders WHERE CustomerId = 1"
  Then the AI action should succeed
```

---

## Tags de organización recomendados

```gherkin
@database            # Todos los tests con BD (permite filtrar con --filter)
@database @smoke     # Subset rápido de conectividad (corre primero en CI)
@database @seed      # Scripts de inserción masiva
@database @cleanup   # Scripts de limpieza de estado
@database @sp        # Stored procedures
@database @readonly  # Solo SELECT — sin efectos secundarios, seguros de correr en paralelo
@database @ai-routing  # Tests del comportamiento del LLM con BD
```

## Relacion con otros documentos

- Para el catalogo exacto de steps, ver `07b_Database_Steps_Reference.md`.
- Para detalles de implementacion, ver `07e_Database_Implementation.md`.

Ejecutar solo los tests `@smoke`:
```bash
dotnet test --configuration Release --filter "Category=smoke"
```

> Nota: este filtro asume que los tags de Reqnroll se mapean a categorias del runner en tu configuracion actual.




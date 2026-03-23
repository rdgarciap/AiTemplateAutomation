# 07b — Database Steps Reference

**Tipo:** Referencia  
**Depende de:** `07_Database_Skill.md`

Catalogo funcional de pasos Gherkin para acceso directo a base de datos. Este archivo describe comportamiento esperado; la implementacion concreta vive en `07e_Database_Implementation.md`.

## Contrato general

1. Todos los pasos ejecutan SQL directamente, sin pasar por el LLM.
2. El resultado de cada operacion debe escribirse en `AiContext.LastSkillResult`.
3. Los payloads estructurados deben serializarse a JSON.
4. Todo resultado de query de base de datos debe parsearse con `DatabaseQueryResultDto` para lectura uniforme.

## Catalogo de pasos

| Paso | Proposito | Forma de salida esperada |
|---|---|---|
| `When I execute the SQL query "..."` | SELECT sin parametros | JSON array u objeto, segun el query |
| `When I execute the SQL query "..." with parameters` | SELECT parametrizado | JSON array u objeto |
| `When I execute the SQL command "..."` | INSERT / UPDATE / DELETE | `{ "affectedRows": N }` |
| `When I execute the SQL command "..." with parameters` | Escritura parametrizada | `{ "affectedRows": N }` |
| `When I execute the stored procedure "..."` | Stored procedure con result set | JSON array |
| `When I execute the stored procedure "..." with parameters` | Stored procedure con result set parametrizado | JSON array |
| `When I execute the non-query stored procedure "..."` | Stored procedure sin result set | `{ "affectedRows": N }` |
| `When I execute the non-query stored procedure "..." with parameters` | Stored procedure sin result set parametrizado | `{ "affectedRows": N }` |
| `When I execute the SQL script file "..."` | Script `.sql` desde disco | `{ "totalAffectedRows": N }` |
| `Then the database query should return at least N row(s)` | Asercion de minimo de filas | No aplica |
| `Then the database result should contain "..."` | Asercion textual sobre el JSON | No aplica |
| `Then the SQL command should affect N row(s)` | Asercion exacta de filas afectadas | No aplica |

## Reglas de parametros

Para tablas Gherkin parametrizadas, la recomendacion es usar estas columnas:

| Columna | Obligatoria | Uso |
|---|---|---|
| `Parameter` | Si | Nombre del parametro sin `@` |
| `Value` | Si | Valor crudo |
| `Type` | Recomendado | Tipo esperado: `int`, `bool`, `datetime`, `decimal`, `string`, `null` |

Si `Type` no existe, la implementacion puede intentar inferencia segura, pero no debe asumir que todo es string si eso rompe el escenario.

## Reglas de salida

1. Queries de multiples filas: JSON array.
2. Queries de una sola fila: JSON object o `null`.
3. Stored procedures con result set: JSON array para mantener consistencia de asercion.
4. Operaciones de escritura: objeto con conteo de filas.

## DTO recomendado para lectura

Para mantener una lectura consistente en pruebas y pasos BDD, usar:

- `Models/DatabaseQueryResultDto.cs`

Comportamiento esperado:

1. Si el payload JSON es un arreglo (`[...]`), cada elemento objeto se convierte a una fila.
2. Si el payload JSON es un objeto (`{...}`), se trata como una sola fila.
3. Si el payload no es JSON valido, el DTO devuelve 0 filas sin lanzar excepcion.
4. Los strings pueden leerse con trim via `GetString(...)` para normalizar columnas CHAR/VARCHAR con padding.

## Nota de implementacion

Los ejemplos de codigo y helpers de conversion de parametros se encuentran en `07e_Database_Implementation.md`.




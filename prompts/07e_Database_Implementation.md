# 07e — Database Implementation

**Tipo:** Implementacion  
**Depende de:** [prompts/07_Database_Skill.md](prompts/07_Database_Skill.md), [prompts/07b_Database_Steps_Reference.md](prompts/07b_Database_Steps_Reference.md)

## `DatabaseSkill.cs`

Implementacion sugerida de la skill de base de datos. El objetivo es encapsular acceso a `IDbClient`, conservar el ultimo resultado en `AiContext` y devolver respuestas serializadas para pasos y aserciones.

```csharp
using System.ComponentModel;
using Dapper;
using {{PROJECT_NAME}}.Drivers;
using Gbm.Automation.Core.DB.Abstractions;
using Gbm.Automation.Core.Utils.Common;
using Microsoft.SemanticKernel;

namespace {{PROJECT_NAME}}.Skills;

public class DatabaseSkill
{
    private readonly AiContext _aiContext;
    private readonly IDbClient _dbClient;

    public DatabaseSkill(AiContext aiContext, IDbClient dbClient)
    {
        _aiContext = aiContext;
        _dbClient = dbClient;
    }

    [KernelFunction("ExecuteQuery")]
    [Description("Executes a read-only SQL SELECT query and returns the results as JSON.")]
    public async Task<string> ExecuteQueryAsync(string query, DynamicParameters? parameters = null)
    {
        var rows = await _dbClient.QueryAsync<dynamic>(query, parameters);
        var result = JsonUtil.SerializeObject(rows);
        _aiContext.LastSkillResult = result;
        return result;
    }

    public async Task<string> ExecuteCommandAsync(string sql, DynamicParameters? parameters = null)
    {
        var affected = await _dbClient.ExecuteAsync(sql, parameters);
        var result = $"{{\"affectedRows\": {affected}}}";
        _aiContext.LastSkillResult = result;
        return result;
    }

    public async Task<string> ExecuteStoredProcedureAsync(string spName, DynamicParameters? parameters = null)
    {
        var rows = await _dbClient.QueryAsync<dynamic>(spName, parameters);
        var result = JsonUtil.SerializeObject(rows);
        _aiContext.LastSkillResult = result;
        return result;
    }

    public async Task<string> ExecuteNonQueryStoredProcedureAsync(string spName, DynamicParameters? parameters = null)
    {
        var affected = await _dbClient.ExecuteNonQueryAsync(spName, parameters ?? new DynamicParameters());
        var result = $"{{\"affectedRows\": {affected}}}";
        _aiContext.LastSkillResult = result;
        return result;
    }

    public async Task<string> ExecuteScriptFileAsync(string relativePath)
    {
        var fullPath = Path.IsPathRooted(relativePath)
            ? relativePath
            : Path.Combine(AppContext.BaseDirectory, relativePath);
        var totalAffected = await _dbClient.ExecuteScriptFileAsync(fullPath);
        var result = $"{{\"totalAffectedRows\": {totalAffected}}}";
        _aiContext.LastSkillResult = result;
        return result;
    }
}
```

## `DatabaseStepDefinitions.cs`

Implementacion sugerida de los pasos directos de base de datos. Estos pasos no pasan por el LLM y estan pensados para verificaciones deterministas o consultas con parametros desde tablas Gherkin.

```csharp
using Dapper;
using {{PROJECT_NAME}}.Drivers;
using {{PROJECT_NAME}}.Models;
using {{PROJECT_NAME}}.Skills;
using NUnit.Framework;
using Reqnroll;

namespace {{PROJECT_NAME}}.StepDefinitions;

[Binding]
public class DatabaseStepDefinitions
{
    private const string LastDatabaseResultDtoKey = "LastDatabaseResultDto";

    private readonly DatabaseSkill _dbSkill;
    private readonly AiContext _aiContext;

    public DatabaseStepDefinitions(DatabaseSkill dbSkill, AiContext aiContext)
    {
        _dbSkill = dbSkill;
        _aiContext = aiContext;
    }

    [When(@"I execute the SQL query ""(.*)""")]
    public async Task WhenIExecuteTheSqlQueryAsync(string query)
    {
        var result = await _dbSkill.ExecuteQueryAsync(query);
        _aiContext.LastSkillResult = result;
        _aiContext.SharedData[LastDatabaseResultDtoKey] = DatabaseQueryResultDto.FromJson(result);
    }

    [When(@"I execute the SQL query ""(.*)"" with parameters")]
    public async Task WhenIExecuteTheSqlQueryWithParametersAsync(string query, Reqnroll.DataTable parameters)
    {
        var result = await _dbSkill.ExecuteQueryAsync(query, BuildDynamicParameters(parameters));
        _aiContext.LastSkillResult = result;
        _aiContext.SharedData[LastDatabaseResultDtoKey] = DatabaseQueryResultDto.FromJson(result);
    }

    [Then(@"the database query should return at least (\d+) rows?")]
    public void ThenTheDatabaseQueryShouldReturnAtLeastRows(int minRows)
    {
        if (_aiContext.SharedData.TryGetValue(LastDatabaseResultDtoKey, out var stored)
            && stored is DatabaseQueryResultDto dtoFromContext)
        {
            Assert.That(dtoFromContext.Count, Is.GreaterThanOrEqualTo(minRows));
            return;
        }

        var fallbackJson = _aiContext.LastSkillResult?.ToString() ?? "[]";
        var fallbackDto = DatabaseQueryResultDto.FromJson(fallbackJson);
        _aiContext.SharedData[LastDatabaseResultDtoKey] = fallbackDto;

        Assert.That(fallbackDto.Count, Is.GreaterThanOrEqualTo(minRows));
    }

    private static DynamicParameters BuildDynamicParameters(Reqnroll.DataTable table)
    {
        var parameters = new DynamicParameters();
        foreach (var row in table.Rows)
        {
            var name = row["Parameter"].ToString()!;
            var rawValue = row["Value"]?.ToString();
            var type = table.Header.Contains("Type") ? row["Type"]?.ToString() : null;
            parameters.Add(name, ConvertValue(rawValue, type));
        }
        return parameters;
    }

    private static object? ConvertValue(string? rawValue, string? type)
    {
        return type?.ToLowerInvariant() switch
        {
            "int" => int.Parse(rawValue!),
            "bool" => bool.Parse(rawValue!),
            "decimal" => decimal.Parse(rawValue!, System.Globalization.CultureInfo.InvariantCulture),
            "datetime" => DateTime.Parse(rawValue!, System.Globalization.CultureInfo.InvariantCulture),
            "null" => null,
            _ => rawValue
        };
    }
}
```

## Helper DTO generico para resultados de BD

Cuando la respuesta de query tenga forma de arreglo JSON como:

```json
[
    {
        "Transactions_Id": 818537275,
        "Transaction_Type_Id": 3,
        "Contract_Id": "217074  "
    }
]
```

usar `DatabaseQueryResultDto.FromJson(...)` para normalizar lectura y no depender de cast dinamico.

Reglas de uso:

1. Parsear siempre `AiContext.LastSkillResult` con `DatabaseQueryResultDto` tras ejecutar una query.
2. Guardar el DTO en `AiContext.SharedData` para reuso por pasos `Then`.
3. Para columnas de texto con padding, leer con `GetString("Contract_Id")` para aplicar trim.




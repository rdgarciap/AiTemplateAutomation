  07d — Database CI/CD & Troubleshooting

**Tipo:** Referencia  
**Depende de:** `07_Database_Skill.md`, `07a_Database_Setup.md`

Este archivo concentra consideraciones operativas para CI/CD y una guia de diagnostico de errores frecuentes en escenarios con base de datos.

   Alcance

1. Documenta integracion de secretos y variables para pipelines.
2. Centraliza errores operativos frecuentes y sus remedios.
3. Complementa el setup local con lineamientos de ejecucion remota.

   Limites

1. No redefine el contrato base de configuracion ni el shape de `appsettings.json`.
2. No redefine el catalogo de pasos de BD.
3. No reemplaza los documentos normativos del stack o arquitectura.

---

   Integracion con AWS CodeBuild

    build/buildspec-build.yml — fragmento completo para tests con BD

```yaml
env:
  parameter-store:
      Token para el feed privado de GitHub Packages
    VSTS_GITHUB_ACCESS_KEY: devops.github.token.read
  secrets-manager:
      Cadena de conexiÓn almacenada como secreto cifrado
    DB_CONN_STR: "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:test/db-connection-SUFFIX"

phases:
  install:
    runtime-versions:
      dotnet: 8.0

  pre_build:
    commands:
        ConfigurationDriver carga DatabaseSettings__ConnectionString automÁticamente
        gracias a AddEnvironmentVariables() — no se necesita editar appsettings.json
      - export DatabaseSettings__ConnectionString="$DB_CONN_STR"
      - ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime

  build:
    commands:
      - cd "src/$PROJECT_NAME/"
      - dotnet restore
      - dotnet test --configuration Release -- NUnit.TestOutputXml=TestResult
    on-failure: ABORT
```

    CÓmo funciona la inyecciÓn de la connection string

1. CodeBuild recupera `DB_CONN_STR` desde Secrets Manager y la expone como variable de entorno.
2. El `pre_build` la mapea a `DatabaseSettings__ConnectionString`.
3. `ConfigurationDriver` la lee en el constructor con `AddEnvironmentVariables()`.
4. El separador `__` es la convenciÓn de ASP.NET Core para jerarquÍas de configuraciÓn.

    Ejecutar solo los tests de BD en CI

```yaml
build:
  commands:
    - dotnet test --configuration Release --filter "Category=database"
```

> Nota: este filtro asume que los tags se publican como categorias del runner en la configuracion actual del proyecto.

---

   Troubleshooting`n`n    Problemas de AWS SSO y Secrets Manager`n`n> **?? Referencia completa:** Ver [prompts/05_AWS_SSO_Setup.md](prompts/05_AWS_SSO_Setup.md) secciÓn �8 para troubleshooting detallado de AWS.`n`n     Token de AWS expirado`n`n**SÍntoma:** `Amazon.SecretsManager.AmazonSecretsManagerException` con mensaje "ExpiredToken".`n`n**Causa:** Los tokens de AWS SSO expiran cada 8 horas.`n`n**SoluciÓn:**`n```powershell`naws sso login --profile TU-PERFIL`naws sts get-caller-identity --profile TU-PERFIL    Verificar`n````n`n     Visual Studio no encuentra credenciales AWS`n`n**SÍntoma:** "Warning: AWS credentials not found in environment."`n`n**Causa:** Visual Studio no hereda variables de entorno de la terminal.`n`n**SoluciÓn:** Configura `Properties/launchSettings.json`:`n```json`n{`n  "profiles": {`n    "<ProjectName>": {`n      "environmentVariables": {`n        "AWS_PROFILE": "TU-PERFIL",`n        "AWS_REGION": "us-east-1"`n      }`n    }`n  }`n}`n````n`nO configura variable de usuario y reinicia VS:`n```powershell`n[System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "TU-PERFIL", "User")`n````n`n---`n`n   Troubleshooting General

    `401 Unauthorized` al hacer `dotnet restore`

El token no estÁ disponible en la sesiÓn de la terminal.

```powershell
  Verificar si estÁ inyectado en la sesiÓn actual
echo $env:VSTS_GITHUB_ACCESS_KEY

  Inyectarlo desde el Ámbito de Usuario
$env:VSTS_GITHUB_ACCESS_KEY = [System.Environment]::GetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "User")
```

Si sigue vacÍo, el token no estÁ configurado en el sistema:
```powershell
[System.Environment]::SetEnvironmentVariable("VSTS_GITHUB_ACCESS_KEY", "ghp_TU_TOKEN_AQUI", "User")
```

Scopes requeridos del token: `read:packages` (y `repo` si el repositorio es privado).

---

    `could not find package Gbm.Automation.Core with version X.X.X`

La versiÓn en el `.csproj` no existe en el feed. Consulta la versiÓn real:
```
https://github.com/gbmcode/wall-e/packages
```
Actualiza `<ProjectName>.csproj` con la versiÓn encontrada.

---

    `DatabaseSettings:ConnectionString no estÁ configurado`

El valor dummy `REPLACE_ME` no fue reemplazado. Opciones para solucionarlo:

1. **Local:** edita `appsettings.json` con la cadena real (no commitees).
2. **Terminal:** `$env:DatabaseSettings__ConnectionString = "Server=...;..."`
3. **CI/CD:** mapea el secreto en `buildspec-build.yml` (ver secciÓn anterior).

---

    `A connection was successfully established with the server, but then an error occurred`

Error de SQL Server despuÉs de conectar. Causas frecuentes:

- Falta `TrustServerCertificate=True` si el servidor usa certificado autofirmado.
- El usuario no tiene permisos `SELECT` / `EXECUTE` en las tablas o SPs usadas en los tests.
- El firewall bloquea la conexiÓn desde el host donde corren los tests.

---

    El resultado de un paso directo siempre es `null`

`AiContext.LastSkillResult` no fue asignado. Los pasos de `DatabaseStepDefinitions` lo
asignan automÁticamente. Si llamas a `BuildSelectAndExecuteAsync` desde C  directamente,
debes asignarlo t�:

```csharp
_ctx.LastSkillResult = await _db.BuildSelectAndExecuteAsync(...);
```

---

    `DynamicParameters: The member X of type JObject has no supported mapping in Dapper`

Los valores del JSON de par�metros se estÁn deserializando como `JObject` en lugar de tipos
primitivos. Pasa solo valores simples — no objetos anidados:

```json
// ? Correcto — valores primitivos
{"userId": 42, "isActive": true, "name": "Alice"}

// ? Incorrecto — objeto anidado no soportado directamente por Dapper
{"filter": {"userId": 42}}
```

---

    `OffsetFetch requires an ORDER BY clause`

SQL Server requiere `ORDER BY` cuando se usa `OFFSET`/`FETCH`. Siempre proporciona
`orderBy` cuando uses `skip`/`take` en `BuildSelectAndExecuteAsync`.

```csharp
// ? Correcto
await _db.BuildSelectAndExecuteAsync(
    columns:   "Id, Name",
    tableName: "dbo.Users",
    orderBy:   "Name ASC",   // ? requerido
    skip:      40,
    take:      20
);
```

---

    El AI no invoca `Database` sino `Api` o `Browser`

El LLM estÁ eligiendo el skill incorrecto. Pasos para diagnosticar:

1. Verifica que `src/<ProjectName>/Prompts/orchestrator.skprompt.txt` contiene los few-shot examples de `Database`.
2. La instrucciÓn en el `.feature` debe incluir palabras clave claras:
   `"query"`, `"database"`, `"execute SQL"`, `"stored procedure"`, `"insert"`, `"delete"`.
3. Reduce la temperatura a `0.0` en `appsettings.json` para respuestas mÁs deterministas:
   ```json
   "AiSettings": { "Temperature": 0.0 }
   ```
4. Considera usar los **pasos directos** en lugar del orquestador AI para BD.
  Referencia: [07c_Database_Scenario_Patterns.md](./07c_Database_Scenario_Patterns.md).

---

   Relacion con otros documentos

1. Setup local y secretos: `07a_Database_Setup.md`.
2. Catalogo de steps y contratos de salida: `07b_Database_Steps_Reference.md`.
3. Patrones de escenarios: `07c_Database_Scenario_Patterns.md`.
4. Implementacion sugerida: `07e_Database_Implementation.md`.





# 04 — Prompt Engineering

**Tipo:** Normativo  
**Rol:** Contrato del orquestador AI

Este archivo define como debe comunicarse el LLM con el framework y que validaciones deben ocurrir antes de ejecutar una skill.

## Contrato de Salida del LLM

El LLM debe responder con un unico JSON de esta forma:

```json
{
  "skill": "NombreExactoDelPlugin",
  "function": "NombreExactoDeLaFuncion",
  "args": {
    "nombreParam": "valorParam"
  }
}
```

## Reglas obligatorias

1. No se permite markdown, explicaciones ni texto adicional.
2. `skill` debe coincidir con un plugin registrado.
3. `function` debe coincidir con una funcion expuesta por ese plugin.
4. `args` siempre debe existir, aunque venga vacio.
5. `AiContext.LastRawResponse` debe guardar la respuesta cruda del modelo.

## Validación Antes de Invocar

Antes de llamar `Kernel.InvokeAsync`, el flujo debe validar:

1. que la respuesta sea JSON valido
2. que el DTO pueda deserializarse
3. que el plugin exista
4. que la funcion exista
5. que los parametros requeridos esten presentes

## Política de Errores

1. Si el JSON es invalido, fallar con un error controlado y mensaje diagnostico.
2. Si el plugin o la funcion no existen, no intentar una invocacion parcial.
3. Los errores de parsing deben incluir el payload original en `LastRawResponse`.
4. La automatizacion no debe usar temperatura creativa para compensar errores de formato.

## Temperatura y Determinismo

La temperatura por defecto es `0.0`.

| Rango | Uso |
|---|---|
| `0.0` | Automatizacion y CI |
| `0.1 - 0.2` | Diagnostico controlado si el equipo lo decide |
| `0.7+` | No permitido en pruebas automatizadas |

## Prompt Template

El template debe vivir en `src/<ProjectName>/Prompts/orchestrator.skprompt.txt` y leerse desde disco en runtime.

Ejemplo con nombre por defecto: [src/DemoFinancialServicesQA/Prompts/orchestrator.skprompt.txt](src/DemoFinancialServicesQA/Prompts/orchestrator.skprompt.txt).

Variables minimas:

- `{{$instruction}}`
- `{{$available_skills}}`

## Política de Few-Shot

1. Cada skill debe tener al menos 2 ejemplos en el template.
2. Los ejemplos deben usar el nombre canonico de plugin y funcion (ver tabla en `03_Skills_Extensibility.md`).
3. Los ejemplos no deben introducir funciones no registradas.
4. Los ejemplos de base de datos deben dejar claro que su uso via AI es excepcional.
5. El template actual incluye ejemplos para: `Browser` (NavigateTo, ClickElement, FillField, GetElementText), `Api` (GetRequest, PostRequest, ValidateJsonSchema), `Database` (ExecuteQuery).

## Implementación Asociada

Para DTOs, step definitions y template base, usar [prompts/04a_Orchestrator_Implementation.md](prompts/04a_Orchestrator_Implementation.md).



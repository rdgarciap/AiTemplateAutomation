# 03 — Skills y Extensibilidad

**Tipo:** Normativo  
**Rol:** Estandar de diseno para skills

Este archivo define como debe verse una skill dentro del framework. La implementacion concreta vive en documentos de implementacion asociados.

## Qué es una Skill

Una skill es una clase C# registrada como plugin en Semantic Kernel cuyas funciones quedan expuestas para ejecucion directa o para ser seleccionadas por el orquestador AI.

## Reglas obligatorias

1. Cada funcion expuesta debe tener `[KernelFunction("...")]`.
2. Cada funcion expuesta debe tener `[Description("...")]` con texto preciso y accionable.
3. La skill recibe sus dependencias por constructor.
4. El nombre canonico invocable es el de `KernelFunction`, no el nombre del metodo C#.
5. Toda skill debe escribir su ultimo resultado funcional en `AiContext.LastSkillResult`.

## Contrato de Nombres

| Elemento | Regla |
|---|---|
| Plugin name | Sustantivo claro, por ejemplo `Browser`, `Api`, `Database`. |
| Kernel function | Verbo + intencion concreta, por ejemplo `NavigateTo`, `GetRequest`, `ExecuteQuery`. |
| Metodo C# | Puede usar sufijo `Async`, pero no cambia el contrato del plugin. |

### Funciones registradas en el kernel por defecto

| Plugin | Kernel function | Descripcion breve |
|---|---|---|
| `Browser` | `NavigateTo` | Navega a una URL. |
| `Browser` | `ClickElement` | Hace clic en un elemento. |
| `Browser` | `FillField` | Escribe un valor en un campo. |
| `Browser` | `GetElementText` | Lee el texto de un elemento. |
| `Api` | `GetRequest` | Ejecuta HTTP GET. |
| `Api` | `PostRequest` | Ejecuta HTTP POST con body JSON. |
| `Api` | `ValidateJsonSchema` | Valida campos requeridos sobre `LastSkillResult` (no hace HTTP call). |
| `Database` | `ExecuteQuery` | Ejecuta SELECT y retorna JSON (solo si DB está configurada). |

## Contrato de Salida

1. Las funciones deben devolver `string` o `Task<string>` cuando el resultado sea serializable o asertable.
2. Si el resultado es estructurado, debe serializarse a JSON consistente.
3. No mezclar mensajes de diagnostico con payload funcional.
4. Los errores funcionales deben ser claros; los errores tecnicos deben manejarse sin romper el contrato del orquestador.

## Asincronía

Usar `Task<string>` cuando la operacion implique IO:

- HTTP
- base de datos
- browser automation real
- lectura de archivos externos

Usar `string` solo para operaciones puramente locales y sin espera.

## Registro en el Kernel

Toda skill habilitada debe registrarse de estas dos formas:

1. `kernel.ImportPluginFromObject(...)`
2. registro en el contenedor de Reqnroll para inyeccion por constructor

## Diseño de Descripciones

Las descripciones deben ayudar al LLM a desambiguar:

1. cuando usar la funcion
2. cuando no usarla
3. que parametros espera
4. que forma de salida produce

## Limites

1. Las skills de base de datos no son el mecanismo por defecto para validacion funcional; para eso se prefieren pasos directos.
2. Las skills no deben depender de estado global mutable.
3. Una skill no debe reconfigurar el kernel ni leer secretos por su cuenta.

## Implementación Asociada

Para ejemplos concretos de `BrowserSkill` y `ApiSkill`, usar [prompts/03a_Skills_Implementation.md](prompts/03a_Skills_Implementation.md).



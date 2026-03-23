# Copilot Instructions — AiTemplateAutomation

## C# Code Style & StyleCop Compliance

Every C# file created or modified in this project **must** comply with the StyleCop.Analyzers rules
defined in `build/FXCop.ruleset` and `build/stylecop.json`. Violations produce build warnings that
block CI pipelines.

---

### Mandatory File Structure

All `.cs` files must follow this exact structure:

```csharp
// <copyright file="FileName.cs" company="GBM">
// GBM GRUPO BURSÁTIL MEXICANO, S.A DE C.V., CASA DE BOLSA
// </copyright>

using System;                  // ← using directives ALWAYS outside the namespace (SA1200)
using Third.Party.Namespace;

namespace AiTemplateAutomation.SubFolder;  // ← file-scoped namespace (no braces)

/// <summary>
/// One-sentence description of what this class does.
/// </summary>
public class MyClass
{
```

**Rules that must be satisfied:**

| Rule | Requirement |
|------|-------------|
| SA1633 / SA1634 | `// <copyright>` header is the first line of every file |
| SA1200 | `using` directives go **before** the `namespace` line |
| SA1600 | Every `public` / `protected` type and member has `<summary>` XML doc |
| SA1601 | Every `public` / `protected` partial class has `<summary>` XML doc |
| SA1611 | Every parameter has a `<param>` XML doc tag |
| SA1615 | Every non-void return has a `<returns>` XML doc tag |
| SA1516 | One blank line between members |
| SA1518 | File ends with a single newline |

---

### Copyright Header Template

Copy this block verbatim — replace only `FileName.cs`:

```csharp
// <copyright file="FileName.cs" company="GBM">
// GBM GRUPO BURSÁTIL MEXICANO, S.A DE C.V., CASA DE BOLSA
// </copyright>
```

---

### XML Documentation Templates

**Class / interface / record:**
```csharp
/// <summary>
/// SHORT description (max one sentence).
/// </summary>
public class Foo { }
```

**Constructor:**
```csharp
/// <summary>
/// Initializes a new instance of the <see cref="Foo"/> class.
/// </summary>
/// <param name="dep">Description of the injected dependency.</param>
public Foo(IMyDep dep) { }
```

**Method with return value:**
```csharp
/// <summary>
/// Short description of what the method does.
/// </summary>
/// <param name="input">Description of the input parameter.</param>
/// <returns>Description of what is returned.</returns>
public string DoSomething(string input) { }
```

**Void method / step definition:**
```csharp
/// <summary>
/// Short description.
/// </summary>
/// <param name="value">Description.</param>
public void DoWork(int value) { }
```

**Property:**
```csharp
/// <summary>Gets or sets the connection timeout in seconds.</summary>
public int TimeoutSeconds { get; set; }

/// <summary>Gets the list of validation errors.</summary>
public List<string> Errors { get; } = new List<string>();
```

**Inherited / implemented member:**
```csharp
/// <inheritdoc/>
public void Dispose() { }
```

---

### Patterns to Avoid

```csharp
// ❌ WRONG — using inside namespace
namespace Foo
{
    using System;
}

// ✅ CORRECT — using outside file-scoped namespace
using System;
namespace Foo;

// ❌ WRONG — missing copyright header
namespace Foo;
public class Bar { }

// ❌ WRONG — undocumented public member
public string GetData() => _data;

// ✅ CORRECT — documented
/// <summary>Returns the stored data string.</summary>
/// <returns>The current data value.</returns>
public string GetData() => _data;
```

---

### Reqnroll / NUnit Step & Test Methods

Step definitions and test methods are `public` and must be documented:

```csharp
/// <summary>
/// Executes the SQL query provided in the step and stores the result.
/// </summary>
/// <param name="query">The SQL SELECT query to run.</param>
[When(@"I execute the SQL query ""(.*)""")]
public async Task WhenIExecuteTheSqlQueryAsync(string query) { }

/// <summary>
/// Verifies that the AWS session can be established with the configured credentials.
/// </summary>
[Test]
[Category("AWS")]
public async Task TestAwsSessionValidation() { }
```

---

### StyleCop Configuration Files

| File | Purpose |
|------|---------|
| `build/stylecop.json` | Sets company name, copyright text, and `usingDirectivesPlacement: outsideNamespace` |
| `build/FXCop.ruleset` | Configures rule severity (Warning / None) for StyleCop, Roslyn, and Sonar analyzers |

`usingDirectivesPlacement: outsideNamespace` is **required** because the project uses
C# file-scoped namespace declarations (`namespace Foo;`). Without it SA1200 fires on
every `using` directive.

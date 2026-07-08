---
name: eclipse-java-format
description: Format Java files in D:\ngkh\m2-core with output that matches Eclipse UI Ctrl + Shift + F by using the workspace formatter helper, Eclipse profile, and parity-test flow. Use after creating, editing, or refactoring Java files in this workspace, especially controllers, services, mappers, DTOs, entities, configuration classes, and tests. Use when Codex needs to finish Java changes with workspace-standard formatting, verify formatter parity against Eclipse UI, or troubleshoot formatter-helper issues.
---

# Eclipse Java Format

Use the workspace formatter helper instead of ad hoc Java formatting.

This skill is for the `D:\ngkh\m2-core` workspace and uses the repo helper scripts plus the values in `eclipse-java-helper.psd1`.

For team setup or machine-specific installation details, read [references/team-setup.md](references/team-setup.md).

For `format only`, prefer the Eclipse-backed formatter when Eclipse is available. If Eclipse is not available, fall back to the portable runtime.

## Trigger rule

After editing any Java file in this workspace, run the formatter helper unless the user explicitly asks not to.

Common triggers:
- create or edit Java classes
- refactor Java code
- update controllers, services, mappers, DTOs, entities, config classes, or tests
- finish a code change and ensure Eclipse-compatible formatting
- compare helper output with Eclipse UI formatting
- troubleshoot formatter-helper behavior

## Default path

For format-only requests that should match Eclipse `Ctrl + Shift + F`, run:

```powershell
.\format-java.ps1 <path-to-java-file>
```

What this does:
- prefers the Eclipse-backed helper bundle in `tools\eclipse-jdt-helper` when Eclipse is available
- falls back to the portable formatter runtime from `tools\eclipse-java-format-portable\lib` for format-only work when Eclipse is not available
- resolves Eclipse home, formatter profile, and helper workspaces from `eclipse-java-helper.psd1`
- uses dedicated helper workspace/configuration caches under:
  - `D:\ngkh\m2-core\.formatter-workspace`
  - `D:\ngkh\m2-core\.formatter-configuration`
- refreshes the helper bundle from `D:\Software\eclipse\dropins`

## Parity test flow

When the user wants proof that helper output matches Eclipse UI formatting, use:

```powershell
.\test-java-format-parity.ps1 <path-to-java-file>
```

This creates a comparison workspace under `.format-parity\...` with:
- `eclipse-ui\...`
- `codex-helper\...`

Then:
1. Ask the user to open the `eclipse-ui` copy in Eclipse.
2. Ask them to press `Ctrl + Shift + F`.
3. Compare the two copies with `git diff --no-index`.

If the diff is empty, helper parity is confirmed for that file.

Decision rule:
- If the user says `format`, `reformat`, or asks for normal Java cleanup after edits, use this format-only flow.
- If Eclipse is available, use the Eclipse-backed formatter first.
- If the user has no Eclipse install and only needs format-only behavior, use the portable runtime.

## Troubleshooting

If formatting fails or Eclipse shows a popup:
1. Read `D:\ngkh\m2-core\.formatter-workspace\.metadata\.log`.
2. Check whether old `com.silverlake.codex.jdthelper_*.jar` files remain in `D:\Software\eclipse\dropins`.
3. Re-run `.\format-java.ps1 <file>` because it rebuilds and reinstalls the current helper bundle automatically.
4. If the machine uses different local paths, confirm `eclipse-java-helper.psd1` matches that machine or use explicit overrides such as `-EclipsePath`, `-ProfilePath`, or `-ConfigPath`.

If helper code changed, the important files are:
- `format-java.ps1`
- `build-eclipse-jdt-helper.ps1`
- `tools\eclipse-jdt-helper\plugin.xml`
- `tools\eclipse-jdt-helper\META-INF\MANIFEST.MF`
- `tools\eclipse-jdt-helper\src\com\silverlake\codex\jdthelper\FormatSourceApplication.java`
- `tools\eclipse-jdt-helper\src\com\silverlake\codex\jdthelper\FormatSourceCore.java`
- `tools\eclipse-jdt-helper\src\com\silverlake\codex\jdthelper\PortableFormatSourceMain.java`

## Expected behavior

- Prefer `format-java.ps1` over manual formatter edits.
- Prefer parity testing when the user doubts Eclipse/UI equivalence.
- Keep responses explicit about whether the result covers:
  - format only
  - save actions

Do not claim save-action parity unless it was tested separately.

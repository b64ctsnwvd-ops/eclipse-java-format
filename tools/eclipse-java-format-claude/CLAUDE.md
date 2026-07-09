# Eclipse Java Formatting Instructions

Use this workflow when editing Java files in the shared workspace.

## Goal

Apply Java formatting that matches Eclipse `Ctrl + Shift + F`.

## Default action

After creating, editing, or refactoring any Java file, run:

```powershell
.\format-java.ps1 <path-to-java-file>
```

Do this before treating the task as complete.

## Runtime selection

The formatter script already decides the runtime:
- if Eclipse is available, it uses Eclipse first
- otherwise it falls back to the portable format-only runtime

Do not replace this with another formatter unless the user explicitly asks.

## Scope

This workflow is for format-only behavior.

Do not assume import organization or save actions are part of this flow.
Do not claim organize-imports parity unless it was tested separately.

## Parity verification

If the user wants proof that formatting matches Eclipse UI, run:

```powershell
.\test-java-format-parity.ps1 <path-to-java-file>
```

Then:
1. ask the user to open the generated `eclipse-ui` copy in Eclipse
2. ask them to press `Ctrl + Shift + F`
3. compare `eclipse-ui` and `codex-helper` with `git diff --no-index`

If the diff is empty, parity is confirmed for that file.

## Config

Check `eclipse-java-helper.psd1` for machine-specific values such as:
- `EclipseHome`
- `FormatterProfilePath`
- `FormatterWorkspace`
- `FormatterConfiguration`
- `PortableFormatterLibRoot`

If local paths differ, update that file or pass explicit script overrides.

## Important files

- `format-java.ps1`
- `build-eclipse-jdt-helper.ps1`
- `sync-portable-java-formatter.ps1`
- `test-java-format-parity.ps1`
- `eclipse-java-helper.psd1`
- `tools\eclipse-jdt-helper\...`
- `tools\eclipse-java-format-portable\lib\...`

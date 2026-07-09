# Claude-Friendly Eclipse Java Formatter Package

This folder is a Claude-friendly wrapper around the formatter setup in this workspace.

It does not rely on Codex skill metadata. Instead, it provides:
- a plain setup/use guide for humans
- a `CLAUDE.md` instruction file that another Claude-style coding agent can follow

## Required workspace files

The formatter workflow depends on these files in the same workspace:
- `format-java.ps1`
- `build-eclipse-jdt-helper.ps1`
- `sync-portable-java-formatter.ps1`
- `test-java-format-parity.ps1`
- `eclipse-java-helper.psd1`
- `tools\eclipse-jdt-helper\...`
- `tools\eclipse-java-format-portable\lib\...`

## Runtime requirements

Required:
- Windows
- Java installed

Optional:
- Eclipse installed

Behavior:
- if Eclipse is available, `format-java.ps1` uses Eclipse first
- if Eclipse is not available, `format-java.ps1` falls back to the portable format-only runtime

## How another agent should use it

After editing Java files, run:

```powershell
.\format-java.ps1 <path-to-java-file>
```

If parity against Eclipse UI needs to be verified, run:

```powershell
.\test-java-format-parity.ps1 <path-to-java-file>
```

Then compare the generated `eclipse-ui` and `codex-helper` copies with `git diff --no-index`.

## Sharing outside this repo

If you want to share this with Claude users outside `m2-core`, copy:
- this folder
- the required workspace files listed above

The `CLAUDE.md` file in this folder is the main agent-facing instruction file.

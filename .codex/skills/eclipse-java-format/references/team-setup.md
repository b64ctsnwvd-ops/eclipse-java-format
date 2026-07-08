# Team Setup

Use this note when the skill is shared with teammates on different machines.

## Required repo files

The skill depends on these workspace files:
- `format-java.ps1`
- `build-eclipse-jdt-helper.ps1`
- `test-java-format-parity.ps1`
- `eclipse-java-helper.psd1`
- `tools\eclipse-jdt-helper\...`
 - `tools\eclipse-java-format-portable\lib\...`

Sharing only the skill folder is not enough unless the teammate already has the same repo helper files.

## Install options

Option 1: repo-local skill
- copy or commit `.codex\skills\eclipse-java-format`
- teammates use the skill from the repo workspace

Option 2: user-global skill
- copy `eclipse-java-format` into `C:\Users\<user>\.codex\skills\`
- use this only if the teammate still has access to the repo helper scripts

## Machine-specific config

The default runtime values come from `eclipse-java-helper.psd1`.

The most important settings are:
- `EclipseHome`
- `FormatterProfilePath`
- `FormatterWorkspace`
- `FormatterConfiguration`
 - `PortableFormatterLibRoot`

If teammates use different local paths, update `eclipse-java-helper.psd1` on their machine or pass overrides on the command line.

Useful overrides:
- `.\format-java.ps1 -EclipsePath "C:\path\to\eclipsec.exe" <file>`
- `.\format-java.ps1 -ProfilePath "C:\path\to\formatter.xml" <file>`
- `.\format-java.ps1 -ConfigPath "C:\path\to\custom-helper.psd1" <file>`

The formatter launcher also supports `ECLIPSEC_PATH` and `ECLIPSE_HOME`.

## Portable format-only mode

Format-only can run without a full Eclipse installation when these are available:
- Java runtime or JDK on the machine
- `tools\eclipse-java-format-portable\lib\...` committed in the repo

That portable runtime is the fallback path when Eclipse is not available for normal formatting.

If the maintainer needs to refresh the portable runtime from a machine that has Eclipse installed, run:

```powershell
.\sync-portable-java-formatter.ps1 -Force
```

This copies the required formatter jars into the repo-local portable runtime.

## Quick verification

After setup:
1. Run `.\format-java.ps1 <path-to-java-file>`.
2. If the user wants proof, run `.\test-java-format-parity.ps1 <path-to-java-file>`.
3. Compare the `eclipse-ui` and `codex-helper` copies with `git diff --no-index`.

If the diff is empty, formatter parity is confirmed for that file.

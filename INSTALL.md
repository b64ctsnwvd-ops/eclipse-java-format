# Install Eclipse Java Format Skill

## What this package contains

This package includes:
- the Codex skill at `.codex\skills\eclipse-java-format`
- the formatter launcher scripts
- the helper configuration file
- the parity test script
- the Eclipse JDT helper source/build files
- the portable format-only runtime jars

## Prerequisites

Required:
- Windows machine
- Java installed and available from command line

Optional:
- Eclipse installed

Behavior:
- if Eclipse is available, `format-java.ps1` uses Eclipse first
- if Eclipse is not available, `format-java.ps1` falls back to the portable format-only runtime

## Step 1: Put the files into a workspace

Copy the package contents into the workspace where you want to use the formatter.

Example:
- `D:\your-workspace\format-java.ps1`
- `D:\your-workspace\.codex\skills\eclipse-java-format\SKILL.md`
- `D:\your-workspace\tools\eclipse-java-format-portable\lib\...`

## Step 2: Make the skill visible to Codex

Choose one of these options.

Option A: repo-local skill
- keep `.codex\skills\eclipse-java-format` inside the workspace root

Option B: global user skill
- copy `eclipse-java-format` into:
- `C:\Users\<your-user>\.codex\skills\eclipse-java-format`

Repo-local is usually easier if the formatter files live in the same workspace.

## Step 3: Verify Java is installed

Run:

```powershell
java -version
```

If Java is not installed, install a JDK first.

## Step 4: Review configuration

Open `eclipse-java-helper.psd1` and check these values:
- `EclipseHome`
- `FormatterProfilePath`
- `FormatterWorkspace`
- `FormatterConfiguration`
- `PortableFormatterLibRoot`

Update them if your machine uses different paths.

## Step 5: Format a Java file

Run:

```powershell
.\format-java.ps1 <path-to-java-file>
```

Example:

```powershell
.\format-java.ps1 product\product.service\src\main\java\com\silverlake\core\product\service\ProductPrmDepositSubTypeService.java
```

## Step 6: Optional parity verification

If you want to compare helper output with Eclipse UI `Ctrl + Shift + F`, run:

```powershell
.\test-java-format-parity.ps1 <path-to-java-file>
```

Then:
1. Open the generated `eclipse-ui` copy in Eclipse.
2. Press `Ctrl + Shift + F`.
3. Save the file.
4. Compare the `eclipse-ui` and `codex-helper` copies with `git diff --no-index`.

## How to use the skill in Codex

Prompt example:

```text
Use $eclipse-java-format to format <path-to-java-file>
```

## Important note

Installing only the skill folder is not enough.

You also need the helper scripts and `tools` directory from this package in the same workspace.

# CLAUDE.md - Verdant Retreat (Rogue Town)

## Project Overview

Verdant Retreat is a fantasy-themed fork of Space Station 13, a multiplayer sandbox game built on the BYOND engine. The codebase is a hybrid architecture: DM (Dream Maker) for game logic and React/TypeScript (tgui) for the web-based UI layer.

**License:** AGPL-3.0

## Quick Reference

### Build Commands

```bash
# Full project build (requires BYOND installed)
tools/build/build.sh

# tgui only (from /tgui directory)
bun tgui:build            # Production build
bun tgui:dev              # Dev server with hot reload
bun tgui:lint             # ESLint check
bun tgui:prettier         # Prettier check
bun tgui:tsc              # TypeScript type check
bun tgui:test             # Run tests (Bun test runner)

# Fix formatting
bun tgui:prettier-fix     # Auto-fix Prettier issues
bun tgui:eslint-fix       # Auto-fix ESLint issues
```

### CI Pipeline (GitHub Actions)

CI runs on pushes and PRs to `main`. Two jobs:

1. **Run Linters** - DreamChecker, PHP lint, Python validators (DMI, map tests), changelog checks, file directory checks
2. **Build** - Full BYOND compilation with error log validation

Skip CI with `[ci skip]` in commit message.

### Key Dependency Versions

| Dependency | Version |
|---|---|
| BYOND | 515.1633 (CI uses 515.1636) |
| Bun | 1.2.16 |
| Node.js | 22.11.0 LTS |
| SpacemanDMM | suite-1.8 (CI uses suite-1.9) |
| React | 19.1.0 |
| TypeScript | 5.8.3 |
| Python | 3.9.0 |

All versions pinned in `dependencies.sh`.

## Project Structure

```
/
├── roguetown.dme          # Main BYOND project file (all includes)
├── dependencies.sh        # Pinned dependency versions
├── SpacemanDMM.toml       # DM linter configuration
├── Dockerfile             # Docker deployment
│
├── code/                  # DM game logic (primary codebase)
│   ├── __DEFINES/         # Preprocessor constants and macros
│   ├── __HELPERS/         # Utility macros
│   ├── _globalvars/       # Global variable definitions
│   ├── _onclick/          # Click handler system
│   ├── controllers/       # Game system controllers (subsystems)
│   ├── datums/            # Data objects (actions, AI, components, skills)
│   ├── game/              # World, mobs, objects, turfs, areas
│   ├── modules/           # Feature modules (admin, jobs, crafting, etc.)
│   └── unit_tests.dm      # Unit test definitions
│
├── tgui/                  # React/TypeScript UI framework
│   ├── packages/
│   │   ├── common/        # Shared utilities
│   │   ├── tgui/          # Main UI application
│   │   ├── tgui-panel/    # Panel interface
│   │   ├── tgui-dev-server/ # Development server
│   │   ├── tgui-setup/    # Setup utilities
│   │   └── tgfont/        # Icon font package
│   ├── .eslintrc.yml      # ESLint configuration
│   ├── .prettierrc.yml    # Prettier configuration
│   └── tsconfig.json      # TypeScript configuration
│
├── modular_azurepeak/     # Modular server variant
├── modular_hearthstone/   # Modular server variant
├── modular_helmsguard/    # Modular server variant
├── modular_scarletreach/  # Modular server variant
├── modular_stonehedge/    # Modular server variant
│
├── _maps/                 # Game maps and templates
├── config/                # Server configuration files
├── icons/                 # Sprite/icon assets (.dmi files)
├── sound/                 # Audio assets
├── strings/               # JSON text/localization data
├── SQL/                   # Database schemas and migrations
├── tools/                 # Build tools, CI scripts, utilities
│   ├── build/             # Juke build system (TypeScript)
│   └── ci/                # CI/CD helper scripts
└── .github/               # GitHub Actions workflows and templates
```

## Code Conventions

### DM (Dream Maker) Code

- **Indentation:** Tabs (4-wide)
- **Type paths:** Always use absolute type paths, never relative (enforced by linter)
- **Proc definitions:** No relative proc definitions (enforced by linter)
- **Parent calls:** Must call parent procs where required (`must_call_parent = "error"`)
- **Access modifiers:** Respect `private_proc`, `protected_proc`, `private_var`, `protected_var` (all errors)
- **Purity:** Honor `must_be_pure` and `must_not_sleep` annotations
- **Unreachable code:** Not allowed (enforced as error)
- **Includes:** All files must be included in `roguetown.dme` — duplicate includes are errors
- **Defines:** Place new constants in `code/__DEFINES/` in the appropriate file
- **New files:** Must be added to `roguetown.dme` include list

### TypeScript/JavaScript (tgui)

- **Indentation:** 2 spaces
- **Strings:** Single quotes (Prettier enforced)
- **Equality:** Always use `===` (`eqeqeq` rule)
- **Variables:** Use `const`/`let`, never `var`
- **Callbacks:** Prefer arrow functions
- **Imports:** Auto-sorted by `eslint-plugin-simple-import-sort`; unused imports are errors
- **React:** Functional components preferred; max JSX nesting depth of 10
- **State management:** Jotai (atomic state)
- **Bundler:** Rspack
- **Complexity:** Max cyclomatic complexity of 50 per function

### YAML Files

- **Indentation:** 2 spaces

### Python

- **Indentation:** Spaces (PEP 8)

## Linting and Static Analysis

### DM Linter (SpacemanDMM / DreamChecker)

Configuration in `SpacemanDMM.toml`. Nearly all diagnostics are set to `"error"`. Key rules:

- No relative type or proc definitions
- Type safety on field access and proc calls
- Integer precision loss is an error
- No duplicate includes or redefined macros
- Ambiguous operators flagged as errors
- Unreachable code and determinate conditions are errors

Run locally: `~/dreamchecker` (after installing SpacemanDMM)

### tgui Linting

ESLint config at `tgui/.eslintrc.yml` (extensive, ~770 lines). Prettier config at `tgui/.prettierrc.yml`.

Run from the `tgui/` directory:
```bash
bun tgui:lint          # ESLint
bun tgui:prettier      # Prettier check
bun tgui:tsc           # TypeScript check
```

## Testing

### DM Unit Tests

- Defined in `code/unit_tests.dm`
- Enabled via `UNIT_TESTS` compile flag
- Use `TEST_ONLY_ASSERT()` for assertions
- `PERFORM_ALL_TESTS()` for conditional execution
- Map validation via `REGISTER_REQUIRED_MAP_ITEM`

### tgui Tests

- Framework: Bun test runner
- Run: `bun tgui:test` (from `tgui/` directory)

### CI Tests

- Python validators: `dmi.test`, `mapmerge2.dmm_test`
- PHP syntax: `php -l` on all `.php` files
- DreamChecker: Full DM static analysis

## Database

- MariaDB/MySQL backend
- Schema: `SQL/tgstation_schema.sql`
- Changelog: `SQL/database_changelog.txt`
- Connection config: `config/dbconfig.txt`

## Modular Architecture

Server-specific gameplay variants live in `modular_*` directories. Each module is self-contained with its own code, icons, and configuration. Current modules:

- `modular_azurepeak`
- `modular_hearthstone`
- `modular_helmsguard`
- `modular_scarletreach`
- `modular_stonehedge`

## PR Guidelines

Pull requests require three sections (see `.github/PULL_REQUEST_TEMPLATE.md`):

1. **About The Pull Request** - Concise bullet points describing changes
2. **Testing Evidence** - Images, clips, or descriptions of testing
3. **Why It's Good For The Game** - Justify the changes

## Common Patterns

### Adding a New Feature (DM)

1. Create `.dm` files in the appropriate `code/` subdirectory
2. Add `#include` entries to `roguetown.dme`
3. Define any new constants in `code/__DEFINES/`
4. Ensure all type paths are absolute
5. Run DreamChecker to validate

### Adding a New tgui Interface

1. Create component in `tgui/packages/tgui/`
2. Use functional React components with Jotai for state
3. Run `bun tgui:lint` and `bun tgui:tsc` to validate
4. Run `bun tgui:build` to compile

### Editor Configuration

`.editorconfig` defines per-filetype settings. Recommended VS Code extensions are in `.vscode/extensions.json`.

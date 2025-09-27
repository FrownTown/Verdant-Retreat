# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RogueTown is a BYOND-based Space Station 13 codebase focused on medieval/fantasy roleplay. The project uses DreamMaker (DM) as the primary language and includes a web UI built with legacy JavaScript tooling.

## Build Commands

### DreamMaker Compilation
- **Main compilation**: Use BYOND DreamMaker to compile `roguetown.dme`
- **Environment file**: `roguetown.dme` - main project file that includes all source files
- **Dependencies**: Requires BYOND version 515.1633+ (see `dependencies.sh`)

### Web UI (TGUI)
- **Build**: `cd tgui && npm run build` or `cd tgui && gulp --min`
- **Watch mode**: `cd tgui && npm run watch` or `cd tgui && gulp watch`
- **Dependencies**: Node.js version 20 (specified in `dependencies.sh`)

### Linting and Validation
- **DreamChecker**: Configured in `SpacemanDMM.toml` with strict error checking
- **Python tools**: Various validation scripts in `tools/` directory
- **Map validation**: `tools/ci/validate_dme.py`

## Architecture

### Core Structure
- **`code/`**: Main DM source code
  - **`__DEFINES/`**: Preprocessor definitions and constants
  - **`__HELPERS/`**: Utility procedures and helper functions
  - **`_globalvars/`**: Global variable definitions
  - **`controllers/`**: Subsystem controllers and game loop management
  - **`datums/`**: Data structures and object definitions
  - **`game/`**: Core game mechanics (atoms, areas, turfs, objects, machinery)
  - **`modules/`**: Feature-specific modules (admin, antagonists, clothing, etc.)

### Key Files
- **`code/world.dm`**: Root world configuration (view size, fps, hub settings)
- **`code/rt.dm`**: RogueTown-specific compilation flags and map selection
- **`roguetown.dme`**: Main project file with all includes
- **`SpacemanDMM.toml`**: DreamChecker configuration with strict linting rules

### Modular Structure
- **`modular_*/`**: Separate modular codebases for different servers/variants
- **`_maps/`**: Map files and templates
- **`tgui/`**: Web-based user interface using Ractive.js framework

### Dependencies
- **BYOND**: 515.1633+ (DreamMaker compiler)
- **rust_g**: Version 3.1.0 (Rust library for BYOND)
- **SpacemanDMM**: Suite 1.8+ (tooling and linting)
- **Node.js**: Version 20+ for TGUI builds

## Development Patterns

### Code Standards
- Strict linting enabled via SpacemanDMM with error-level diagnostics
- Relative type/proc definitions disallowed
- Private/protected access modifiers enforced
- Pure procedure annotations required where applicable

### File Organization
- Features organized into modules under `code/modules/`
- Game mechanics in `code/game/` by object type
- Global definitions centralized in `__DEFINES/`
- Helper procedures in `__HELPERS/`

### Build Integration
- CI/CD configured via GitHub Actions (`ci_suite.yml`)
- Automated linting and validation on PRs
- Docker support available (`Dockerfile`)
# Repository Guidelines

## Communication
- Always write responses in English, even if the prompt is in Portuguese or another language.

## Project Structure & Module Organization
- `packages/`: OpenWrt package definitions and payload files. Runtime Lua code typically lives under `packages/<pkg>/files/usr/lib/lua/`, and package-level tests live under `packages/<pkg>/tests/`.
- Scope: always and only work with code under `packages/pirania/`; ignore all other items inside `packages/`.
- `tests/`: shared test utilities, fakes, and integration tests.
- `captive-portal-v0` … `captive-portal-v3`: captive portal assets by version.
- `Dockerfiles/`: container definitions (notably unit test image).
- `tools/`: helper scripts (e.g., `tools/dockertestshell`).
- `run_tests`: test runner script.
- `libremesh.mk`, `libremesh.sdk.config`: build/SDK integration files for OpenWrt.

## Build, Test, and Development Commands
- `./run_tests`: run Lua unit tests inside Docker using `busted` and generate coverage.
- `LUA_ENABLE_LOGGING=1 ./run_tests`: enable verbose Lua logging during tests.
- `./tools/dockertestshell`: open a shell inside the test container to iterate quickly.
- Only run or modify workflows that target `packages/pirania/`.
- Image building is done via OpenWrt Buildroot/ImageBuilder; see `README.md` for full workflows. Example ImageBuilder usage (run inside the ImageBuilder directory):
  ```sh
  make image PROFILE=<device_profile> PACKAGES="lime-system lime-proto-babeld ..." FILES=files
  ```

## Coding Style & Naming Conventions
- Preserve existing style within each file; there is no repo-wide formatter.
- Lua: follow current indentation in the file (tabs/spaces vary); keep module-level tables and `return` at end.
- Makefiles: use tabs for recipe lines (required by `make`).
- Shell: scripts such as `run_tests` use bash; avoid bashisms in `sh` scripts unless the file already uses bash.

## Testing Guidelines
- Framework: `busted` with coverage via `luacov` (run by `./run_tests`).
- Test locations:
  - Package tests: `packages/<pkg>/tests/test_*.lua`
  - Shared/integration tests: `tests/test_*.lua`
- Focus tests on `packages/pirania/` only; do not add or modify tests for other packages.
- When code uses UCI, prefer `lime.config.get_uci_cursor()` and the helpers in `tests/utils` (see `TESTING.md`).

## Commit & Pull Request Guidelines
- Branch from `master` and target `master` for PRs. Recommended branch format: `<type>/<name>` (e.g., `feature/new-ui`, `fix/bug-123`).
- Commit subjects in this repo are short and lowercase, often prefixed by area (`packages: ...`, `lime-system: ...`, or `fix(scope): ...`). Follow that pattern.
- PRs should include a clear description, reference issues when applicable, and mention test results (e.g., `./run_tests`).

## Developer Notes
- Unit tests require Docker running and a non-root user; see `TESTING.md` for setup details.
- Changes and investigations should stay within `packages/pirania/` unless explicitly requested otherwise.
- For deeper context, consult `CONTRIBUTING.md`, `TESTING.md`, and `HACKING.md`.

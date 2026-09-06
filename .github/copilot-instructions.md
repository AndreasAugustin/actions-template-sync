# Copilot instructions

## Repository overview

- This repository contains the `actions-template-sync` GitHub Action.
- The action implementation is shell-based and lives in `src/`.
- Action metadata and environment wiring are defined in `action.yml`.
- GitHub Actions workflows are stored in `.github/workflows/`.
- Docker images and local development services are defined in `Dockerfile` and
  `docker-compose.yml`.

## Making changes

- Keep changes focused and preserve the existing shell and YAML conventions.
- Update documentation when changing action inputs, outputs, workflows, or
  user-facing behavior.
- Release-based syncing is controlled by `is_sync_to_latest_semver`; it selects
  the latest semantic-version tag from the source remote. The
  `is_include_prerelease` input only affects this mode and defaults to stable
  releases.
- When changing the release-selection logic, keep remote tag handling in
  `src/sync_common.sh`, preserve support for lightweight and annotated tags,
  and update `README.md` and `docs/ARCHITECTURE.md`.
- Do not expose tokens, private keys, or other credentials in source,
  workflows, logs, or examples.
- Pin third-party GitHub Actions to full commit SHAs and include a comment
  naming the released version.
- Prefer existing Makefile targets and Docker services over adding new tooling.

## Validation

Run the smallest relevant checks for the files changed:

```bash
make shellcheck
make markdownlint
bash tests/sync_common_test.sh
```

For workflow or action changes, inspect `action.yml`, confirm input-to-
environment wiring, and run the applicable workflow tests when available.

## Commits and pull requests

- Use Conventional Commits, for example:
  `fix(sync): handle missing upstream branch`.
- Follow the repository's pull request template.
- Summarize behavior changes and validation in the pull request description.

# Copilot instructions

## Repository overview

- This repository contains the `actions-template-sync` GitHub Action.
- The action implementation is shell-based and lives in `src/`.
- GitHub Actions workflows are stored in `.github/workflows/`.
- Docker images and local development services are defined in `Dockerfile` and
  `docker-compose.yml`.

## Making changes

- Keep changes focused and preserve the existing shell and YAML conventions.
- Update documentation when changing action inputs, outputs, workflows, or
  user-facing behavior.
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
```

For workflow or action changes, also inspect the YAML and run the applicable
workflow tests when available.

## Commits and pull requests

- Use Conventional Commits, for example:
  `fix(sync): handle missing upstream branch`.
- Follow the repository's pull request template.
- Summarize behavior changes and validation in the pull request description.

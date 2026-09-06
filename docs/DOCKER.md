# DOCKER

## abstract

If you want to test things out or if you want to build your own action (e.g. in on prem environments) you are able to use docker images.

- [github registry][github-repo]
- [dockerhub registry][dockerhub-repo]

## Use the production image

The production image runs the same synchronization script used by the GitHub
Action. It expects the target repository to be mounted into the container and
requires tokens for both the source and target repositories.

The image entrypoint requires these environment variables:

| Variable | Description |
| --- | --- |
| `SOURCE_GH_TOKEN` | Token with read access to the source repository |
| `TARGET_GH_TOKEN` | Token with permission to create branches and pull requests in the target repository |
| `SOURCE_REPO_PATH` | Source repository path, for example `owner/template-repository` |
| `GITHUB_SERVER_URL` | GitHub server URL, for example `https://github.com` |

The container should run from the mounted target repository. Git, GitHub CLI,
SSH, Git LFS, and the synchronization scripts are included in the image.

### Pull and run

Use either registry image. Replace `v2` with the desired release tag:

```bash
docker run --rm \
  --workdir /github/workspace \
  --volume "$PWD:/github/workspace" \
  --env SOURCE_GH_TOKEN \
  --env TARGET_GH_TOKEN \
  --env SOURCE_REPO_PATH=owner/template-repository \
  --env UPSTREAM_BRANCH=main \
  --env GITHUB_SERVER_URL=https://github.com \
  --env GITHUB_ACTOR=automation \
  ghcr.io/andreasaugustin/actions-template-sync:v2
```

The same command using Docker Hub is:

```bash
docker run --rm \
  --workdir /github/workspace \
  --volume "$PWD:/github/workspace" \
  --env SOURCE_GH_TOKEN \
  --env TARGET_GH_TOKEN \
  --env SOURCE_REPO_PATH=owner/template-repository \
  --env GITHUB_SERVER_URL=https://github.com \
  andyaugustin/actions-template-sync:v2
```

The `--env NAME` form reads the value from the host environment. Set the token
variables without putting their values in shell history:

```bash
export SOURCE_GH_TOKEN='source-token'
export TARGET_GH_TOKEN='target-token'
export SOURCE_REPO_PATH='owner/template-repository'
```

For repeatable runs, put non-secret configuration in an environment file and
provide secrets through the environment or a secret manager:

```dotenv
SOURCE_REPO_PATH=owner/template-repository
UPSTREAM_BRANCH=main
GITHUB_SERVER_URL=https://github.com
GITHUB_ACTOR=automation
```

```bash
docker run --rm \
  --env-file ./templatesync.env \
  --env SOURCE_GH_TOKEN \
  --env TARGET_GH_TOKEN \
  --workdir /github/workspace \
  --volume "$PWD:/github/workspace" \
  ghcr.io/andreasaugustin/actions-template-sync:v2
```

### Private source repositories over SSH

Set `SSH_PRIVATE_KEY_SRC` to use SSH instead of the GitHub CLI token for the
source repository. The image already contains GitHub's SSH host key.

```bash
docker run --rm \
  --workdir /github/workspace \
  --volume "$PWD:/github/workspace" \
  --env SSH_PRIVATE_KEY_SRC \
  --env TARGET_GH_TOKEN \
  --env SOURCE_REPO_PATH=owner/private-template \
  --env GITHUB_SERVER_URL=https://github.com \
  ghcr.io/andreasaugustin/actions-template-sync:v2
```

For GitHub Enterprise or another Git provider, set `HOSTNAME` to the source
host and use the matching `GITHUB_SERVER_URL`.

### Build the image locally

Build the production target from a checkout of this repository:

```bash
docker build --target prod \
  --tag actions-template-sync:prod .
```

Then replace the registry image name in the examples with
`actions-template-sync:prod`.

[dockerhub-repo]: https://hub.docker.com/r/andyaugustin/actions-template-sync
[github-repo]: https://github.com/AndreasAugustin/actions-template-sync/pkgs/container/actions-template-sync

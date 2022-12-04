# actions-template-sync
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-12-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

![Lint](https://github.com/AndreasAugustin/actions-template-sync/workflows/Lint/badge.svg)

It is possible to create repositories within Github with
[GitHub templates](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-template-repository).
This is a nice approach to have some boilerplate within your repository.
Over the time the template repository will get some code changes.
The problem is that the already created repositories won't know about those changes.
This GitHub action will help you to keep track of the template changes.

## Features

* Sync template repository with the current repository
* Ignore files and folders from syncing using a `.templatesyncignore` file

## Usage

### GitHub Actions

Add this configuration to your github action

```yaml
# File: .github/workflows/template-sync.yml

on:
    # cronjob trigger
  schedule:
  - cron:  "0 0 1 * *"
  # manual trigger
  workflow_dispatch:
jobs:
  repo-sync:
    runs-on: ubuntu-latest

    steps:
      # To use this repository's private action, you must check out the repository
      - name: Checkout
        uses: actions/checkout@v3
      - name: actions-template-sync
        uses: AndreasAugustin/actions-template-sync@v0.4.2-draft
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          source_repo_path: <owner/repo>
          upstream_branch: <target_branch> # defaults to main
          pr_labels: <label1>,<label2>[,...] # optional, no default
```

You will receive a pull request within your repository if there are some changes available.

### Configuration parameters

| Variable | Description | Required | `[Default]` |
|----|----|----|----|
| github_token | Token for the repo. Can be passed in using `$\{{ secrets.GITHUB_TOKEN }}` | `true` |  |
| source_repo_path | Repository path of the template | `true` | |
| upstream_branch | The target branch | `true` | `main` |
| source_repo_ssh_private_key | `[optional]` private ssh key for the source repository. E.q. useful if using a private template repository. [see](#private-template-repository)| `false` |  |
| pr_branch_name_prefix | `[optional]` the prefix of branches created by this action | `false` | `chore/template_sync`  |
| pr_title | `[optional]` the title of PRs opened by this action. Must be already created. | `false` | `upstream merge template repository`  |
| pr_labels | `[optional]` comma separated list. [pull request labels][pr-labels]. Must be already created. | `false` | |
| hostname | `[optional]` the hostname of the repository | `false` | `github.com` |

### Example

This repo uses this [template][template] and this action from the [marketplace][marketplace].
See the definition [here][self-usage]

### Trigger

You can use all [triggers][action-triggers] which are supported for GitHub actions

### Private template repository

If you have a private template repository.

#### SSH

You have various options to use ssh keys with GitHub.
An example are [deployment keys][deployment-keys]. For our use case write permissions are not needed.
Within the repository where the GitHub action is enabled add a secret (e.q. `SOURCE_REPO_SSH_PRIVATE_KEY`) with the content of your private SSH key. Make sure that the read permissions of that secret fulfil your use case.
Set the optional `source_repo_ssh_private_key` input parameter.

```yaml
jobs:
  repo-sync:
    runs-on: ubuntu-latest

    steps:
      # To use this repository's private action, you must check out the repository
      - name: Checkout
        uses: actions/checkout@v3
      - name: actions-template-sync
        uses: AndreasAugustin/actions-template-sync@v0.4.2-draft
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          source_repo_path: ${{ secrets.SOURCE_REPO_PATH }} # <owner/repo>, should be within secrets
          upstream_branch: ${{ secrets.TARGET_BRANCH }} #<target_branch> # defaults to main
          pr_labels: <label1>,<label2>[,...] # optional, no default
          source_repo_ssh_private_key: ${{ secrets.SOURCE_REPO_SSH_PRIVATE_KEY }} # contains the private ssh key of the private repository
```

## Ignore Files

Create a `.templatesyncignore` file. Just like writing a `.gitignore` file, follow the [glob pattern](https://en.wikipedia.org/wiki/Glob_(programming)) in defining the files and folders that should be excluded from syncing with the template repository.

## Debug

You must create a secret named `ACTIONS_STEP_DEBUG` with the value `true` to see the debug messages set by this command in the log. For more information, see "[Enabling debug logging.][enabling-debug-logging]"

## DEV

The development environment targets are located in the [Makefile](Makefile)

```bash
make help
```

For some architectural notes please have a look into [docs](./docs/README.md)

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://github.com/AndreasAugustin"><img src="https://avatars0.githubusercontent.com/u/8027933?v=4?s=100" width="100px;" alt="andy Augustin"/><br /><sub><b>andy Augustin</b></sub></a><br /><a href="https://github.com/AndreasAugustin/actions-template-sync/commits?author=AndreasAugustin" title="Documentation">📖</a> <a href="https://github.com/AndreasAugustin/actions-template-sync/commits?author=AndreasAugustin" title="Code">💻</a> <a href="https://github.com/AndreasAugustin/actions-template-sync/pulls?q=is%3Apr+reviewed-by%3AAndreasAugustin" title="Reviewed Pull Requests">👀</a> <a href="#security-AndreasAugustin" title="Security">🛡️</a> <a href="#ideas-AndreasAugustin" title="Ideas, Planning, & Feedback">🤔</a> <a href="#question-AndreasAugustin" title="Answering Questions">💬</a></td>
      <td align="center"><a href="https://www.iit.it/people/ugo-pattacini"><img src="https://avatars.githubusercontent.com/u/3738070?v=4?s=100" width="100px;" alt="Ugo Pattacini"/><br /><sub><b>Ugo Pattacini</b></sub></a><br /><a href="https://github.com/AndreasAugustin/actions-template-sync/commits?author=pattacini" title="Documentation">📖</a></td>
      <td align="center"><a href="https://github.com/jg-rivera"><img src="https://avatars.githubusercontent.com/u/27613092?v=4?s=100" width="100px;" alt="Jose Gabrielle Rivera"/><br /><sub><b>Jose Gabrielle Rivera</b></sub></a><br /><a href="https://github.com/AndreasAugustin/actions-template-sync/commits?author=jg-rivera" title="Code">💻</a></td>
      <td align="center"><a href="http://pdrittenhouse.com"><img src="https://avatars.githubusercontent.com/u/1556730?v=4?s=100" width="100px;" alt="P.D. Rittenhouse"/><br /><sub><b>P.D. Rittenhouse</b></sub></a><br /><a href="#ideas-pdrittenhouse" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="https://github.com/Daniel-Boll"><img src="https://avatars.githubusercontent.com/u/43689101?v=4?s=100" width="100px;" alt="Daniel Boll"/><br /><sub><b>Daniel Boll</b></sub></a><br /><a href="https://github.com/AndreasAugustin/actions-template-sync/issues?q=author%3ADaniel-Boll" title="Bug reports">🐛</a></td>
      <td align="center"><a href="https://github.com/albertschwarzkopf"><img src="https://avatars.githubusercontent.com/u/35684914?v=4?s=100" width="100px;" alt="albertschwarzkopf"/><br /><sub><b>albertschwarzkopf</b></sub></a><br /><a href="#ideas-albertschwarzkopf" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="http://akulpillai.com"><img src="https://avatars.githubusercontent.com/u/32793567?v=4?s=100" width="100px;" alt="Akul Pillai"/><br /><sub><b>Akul Pillai</b></sub></a><br /><a href="#security-akulpillai" title="Security">🛡️</a></td>
    </tr>
    <tr>
      <td align="center"><a href="https://github.com/steveizzle"><img src="https://avatars.githubusercontent.com/u/45331237?v=4?s=100" width="100px;" alt="Stefan Riembauer"/><br /><sub><b>Stefan Riembauer</b></sub></a><br /><a href="#ideas-steveizzle" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center"><a href="http://fabriziocacicia.com"><img src="https://avatars.githubusercontent.com/u/7525888?v=4?s=100" width="100px;" alt="Fabrizio Cacicia"/><br /><sub><b>Fabrizio Cacicia</b></sub></a><br /><a href="#security-fabriziocacicia" title="Security">🛡️</a> <a href="https://github.com/AndreasAugustin/actions-template-sync/issues?q=author%3Afabriziocacicia" title="Bug reports">🐛</a></td>
      <td align="center"><a href="https://github.com/JTunis"><img src="https://avatars.githubusercontent.com/u/11543636?v=4?s=100" width="100px;" alt="Justin Tunis"/><br /><sub><b>Justin Tunis</b></sub></a><br /><a href="#ideas-JTunis" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/AndreasAugustin/actions-template-sync/commits?author=JTunis" title="Code">💻</a> <a href="https://github.com/AndreasAugustin/actions-template-sync/issues?q=author%3AJTunis" title="Bug reports">🐛</a></td>
      <td align="center"><a href="https://mikematos84.github.io"><img src="https://avatars.githubusercontent.com/u/4093433?v=4?s=100" width="100px;" alt="Michael Matos"/><br /><sub><b>Michael Matos</b></sub></a><br /><a href="https://github.com/AndreasAugustin/actions-template-sync/issues?q=author%3Amikematos84" title="Bug reports">🐛</a></td>
      <td align="center"><a href="https://github.com/fatmcgav-depop"><img src="https://avatars.githubusercontent.com/u/109519102?v=4?s=100" width="100px;" alt="Gavin Williams"/><br /><sub><b>Gavin Williams</b></sub></a><br /><a href="#ideas-fatmcgav-depop" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!

[enabling-debug-logging]: https://docs.github.com/en/actions/managing-workflow-runs/enabling-debug-logging
[deployment-keys]: https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys
[action-triggers]: https://docs.github.com/en/actions/reference/events-that-trigger-workflows
[template]: https://github.com/AndreasAugustin/template
[marketplace]: https://github.com/marketplace/actions/actions-template-sync
[self-usage]: https://github.com/AndreasAugustin/actions-template-sync/blob/main/.github/workflows/actions_template_sync.yml
[pr-labels]: https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels

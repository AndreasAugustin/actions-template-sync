# Architecture

## abstract

within this section you will find some

## Code

The architecture and logic within the code

```mermaid
flowchart TD
Exit[Exit]
Start[Start]
GitHubActionEnv{Read GitHubAction env}

style Start fill:#f9f,stroke:#333,stroke-width:4px
style Exit fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5

EnvCheckEntry{required environment variables exists}
SshCheckEntry{SSH private key defined}
SshConfigureEntry[Configure ssh related variables]
GitConfigureEntry[Configure git global settings]

EnvCheckSync{required environment variables exists}
SshConfigureSync[Configure SSH variables]
SetVariablesSync[Set the needed variables, e.q. with reading remote repository]
CheckTemplateFileExists{"Check if the .templatesyncrc file exists in repository"}
WriteTemplateVersionSync["Read and write the template sync version into variable"]
CompareTemplateVersionSync{"Compare the source repository version"}
GitCheckoutSync["create git branch <branch_prefix_git_hash>"]
GitPullSync["pull from remote repository"]
CheckIgnoreFileExistsSync{"check if .templatesyncignore file exists"}
ResetChangesSync["Reset the changes listed within the ignore file"]
GitCommitSync["commit the changes"]

CheckIsDryRun{"check if is_dry_run is set to true"}
GitPushSync["Push the changes to GitHub"]
GitPullRequestSync["create a pull request on GitHub"]

subgraph githubactions["GitHubActions"]

Start --> GitHubActionEnv
GitHubActionEnv -->|issues| Exit


end

subgraph entry["entrypoint.sh"]

GitHubActionEnv -->|all fine| EnvCheckEntry
EnvCheckEntry -->|do not exist| Exit
EnvCheckEntry -->|exist| SshCheckEntry

SshCheckEntry -->|is defined| SshConfigureEntry
SshCheckEntry -->|is not defined| GitConfigureEntry
SshConfigureEntry --> GitConfigureEntry

end


subgraph sync["sync_template.sh"]
GitConfigureEntry --> EnvCheckSync

EnvCheckSync -->|do not exist| Exit
EnvCheckSync -->|do exist| SshConfigureSync
SshConfigureSync --> SetVariablesSync

subgraph compareVersion["compare the sync version"]
SetVariablesSync --> CheckTemplateFileExists
CheckTemplateFileExists -->|exists| WriteTemplateVersionSync
CheckTemplateFileExists -->|does not exist|CompareTemplateVersionSync
WriteTemplateVersionSync --> CompareTemplateVersionSync
CompareTemplateVersionSync -->|equal versions| Exit
end

subgraph git["Git actions"]
CompareTemplateVersionSync -->|versions not equal| GitCheckoutSync
GitCheckoutSync --> GitPullSync
GitPullSync --> CheckIgnoreFileExistsSync
CheckIgnoreFileExistsSync -->|does not exist| GitCommitSync
CheckIgnoreFileExistsSync -->|exists| ResetChangesSync
ResetChangesSync --> GitCommitSync
end

subgraph github["gitHub actions"]
GitCommitSync --> CheckIsDryRun
CheckIsDryRun -->|is true| Exit
CheckIsDryRun -->|is not true| GitPushSync
GitPushSync --> GitPullRequestSync
GitPullRequestSync --> Exit

end

end

```

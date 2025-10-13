" support highlighting git command in bash
syntax match bashGitCmd /\<git\>/
syntax match bashGitSubCmd /\<\%(commit\|push\|pull\|status\|add\|clone\|checkout\|merge\|rebase\|log\|diff\|branch\|tag\|stash\|fetch\|remote\|reset\|init\|rm\|mv\|show\|blame\|cherry-pick\|revert\|bisect\|describe\|config\|submodule\)\>/
highlight default link bashGitCmd Statement
highlight default link bashGitSubCmd Identifier

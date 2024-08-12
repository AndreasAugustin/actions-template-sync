SHELL := /bin/bash
.DEFAULT_GOAL := help

###########################
# VARIABLES
###########################

###########################
# MAPPINGS
###########################

###########################
# TARGETS
###########################

.PHONY: help
help:  ## help target to show available commands with information
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |  awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: markdownlint
markdownlint: ## Validate markdown files
	docker compose run docs markdownlint .

.PHONY: zsh
zsh: ## open dev container with build environment
	docker compose run --service-ports dev

.PHONY: prod
prod: ## run the prod docker image with bash
	docker compose run prod

.PHONY: prune
prune: ## delete the whole environment
	docker compose down -v --rmi all --remove-orphans

.Phony: shellcheck
shellcheck:  ## run shellcheck
	docker compose run shellcheck -x src/*.sh

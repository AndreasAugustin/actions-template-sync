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
	docker compose run shellcheck -x src/*.sh tests/*.sh

.PHONY: shelltest
shelltest:  ## run shell BDD tests
	bash tests/sync_common_test.sh
	bash tests/sync_template_test.sh

.PHONY: docker-test
docker-test: ## build and test all Docker image targets
	docker build --target prod --tag actions-template-sync:prod .
	docker build --target dev --tag actions-template-sync:dev .
	docker build --target docs --tag actions-template-sync:docs .
	@container_structure_test="$$(mktemp)"; \
	trap 'rm -f "$$container_structure_test"' EXIT; \
	curl --fail --silent --show-error \
		https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 \
		-o "$$container_structure_test"; \
	chmod +x "$$container_structure_test"; \
	"$$container_structure_test" test \
		--image actions-template-sync:prod --config docker-test-config.yml; \
	"$$container_structure_test" test \
		--image actions-template-sync:dev --config docker-test-config.yml; \
	"$$container_structure_test" test \
		--image actions-template-sync:docs --config docker-docs-test-config.yml

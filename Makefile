# Environment
PWD ?= `pwd`

# Kurz
BIN_NAME ?= kurz
AUTHOR ?= marceloboeira
VERSION ?= 0.0.1
DEFAULT_HTTP_PORT ?= 8000

# Docker
DOCKER ?= `which docker`
DOCKER_PATH ?= $(PWD)/docker
DOCKER_FILE ?= $(DOCKER_PATH)/Dockerfile
DOCKER_TAG ?= $(AUTHOR)/$(BIN_NAME):$(VERSION)

# Docker Testing
DGOSS ?= `which dgoss`

.PHONY: help
help: ## Lists the available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: docker-build
docker-build: ## Builds the core docker image compiling source for Rust and Elm
	$(DOCKER) build -t $(DOCKER_TAG) -f $(DOCKER_FILE) $(PWD)

.PHONY: docker-test
docker-test: ## Tests the latest docker generated image
	cd $(DOCKER_PATH); $(DGOSS) run -p $(DEFAULT_HTTP_PORT) $(DOCKER_TAG)

.PHONY: test-all
test-all: docker-build docker-test ## Tests everything, EVERYTHING

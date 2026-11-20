# Make = a language-agnostic "task runner". Many teams wrap every tool behind it,
# so CI and humans run the SAME commands:   make build   make test   make docker
#
# IMPORTANT: recipe lines must start with a TAB, not spaces.

APP      := demo-app
VERSION  ?= $(shell git describe --tags --always 2>/dev/null || echo dev)
IMAGE    := registry.example.local/$(APP):$(VERSION)

.PHONY: help install test build docker run clean

help:            ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

install:         ## Install dependencies
	cd node && npm install

test: install    ## Run unit tests
	cd node && npm test

build: test      ## Build the app (runs tests first)
	@echo "Building $(APP) version $(VERSION)"

docker: build    ## Build a Docker image tagged with the git version
	docker build -t $(IMAGE) node

run:             ## Run locally
	cd node && PORT=3000 npm start

clean:           ## Remove build output
	rm -rf node/node_modules dist target build

GOLANG_VERSION := 1.15.6
ALPINE_VERSION := 3.13

GIT_REPO := https://github.com/michalswi/webshell
DOCKER_REPO := michalsw
APPNAME := webshell

VERSION ?= $(shell git describe --tags --always)
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d %H:%M:%S')
LAST_COMMIT_USER ?= $(shell git log -1 --format='%cn <%ce>')
LAST_COMMIT_HASH ?= $(shell git log -1 --format=%H)
LAST_COMMIT_TIME ?= $(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S')
RANDOM ?= $(shell shuf -i 30000-45000 -n 1)

SERVICE_ADDR ?= 8080

AZ_RG ?= $(APPNAME)rg
AZ_LOCATION ?= westeurope
AZ_DNS_LABEL ?= $(APPNAME)-$(RANDOM)

.DEFAULT_GOAL := help
.PHONY: test go-run go-build docker-build docker-run docker-stop azure-rg azure-rg-del azure-aci azure-aci-logs azure-aci-delete

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

test:
	go test -v ./...

go-run: 		## Run - no binary
	$(info -run - no binary-)
	SERVICE_ADDR=$(SERVICE_ADDR) \
	go run .	

go-build: 		## Build binary
	$(info -build binary-)
	CGO_ENABLED=0 \
	go build \
	-v \
	-ldflags "-s -w -X '$(GIT_REPO)/version.AppVersion=$(VERSION)' \
	-X '$(GIT_REPO)/version.BuildTime=$(BUILD_TIME)'" \
	-o $(APPNAME)-$(VERSION) .

docker-build:	## Build docker image
	$(info -build docker image-)
	docker build \
	--pull \
	--build-arg GOLANG_VERSION="$(GOLANG_VERSION)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--build-arg APPNAME="$(APPNAME)" \
	--build-arg VERSION="$(VERSION)" \
	--build-arg BUILD_TIME="$(BUILD_TIME)" \
	--label="build.version=$(VERSION)" \
	--tag="$(DOCKER_REPO)/$(APPNAME):latest" \
	--tag="$(DOCKER_REPO)/$(APPNAME):$(VERSION)" \
	.

docker-run:		## Once docker image is ready run with default parameters (or overwrite)
	$(info -run docker-)
	docker run -d --rm \
	--name $(APPNAME) \
	-p $(SERVICE_ADDR):$(SERVICE_ADDR) \
	$(DOCKER_REPO)/$(APPNAME):latest

docker-stop:	## Stop running docker
	$(info -stop docker-)
	docker stop $(APPNAME)

azure-rg:	## Create Azure Resource Group
	az group create --name $(AZ_RG) --location $(AZ_LOCATION)

azure-rg-del:	## Delete Azure Resource Group
	az group delete --name $(AZ_RG)

azure-aci:	## Run app (Azure Container Instance)
	az container create \
	--resource-group $(AZ_RG) \
	--name $(APPNAME) \
	--image michalsw/$(APPNAME) \
	--restart-policy Always \
	--ports 80 \
	--dns-name-label $(AZ_DNS_LABEL) \
	--location $(AZ_LOCATION) \
	--environment-variables \
		SERVICE_ADDR=80

azure-aci-logs:	## Get app logs (Azure Container Instance)
	az container logs \
	--resource-group $(AZ_RG) \
	--name $(APPNAME)

azure-aci-delete:	## Delete app (Azure Container Instance)
	az container delete \
	--resource-group $(AZ_RG) \
	--name $(APPNAME)

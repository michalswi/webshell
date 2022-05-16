
```
$ make

Usage:
  make <target>

Targets:
  go-run           Run - no binary
  go-build         Build binary
  docker-build     Build docker image
  docker-run       Run docker container with default parameters (or overwrite)
  docker-stop      Stop docker container
  azure-rg         Create Azure Resource Group
  azure-rg-del     Delete Azure Resource Group
  azure-aci        Run app (Azure Container Instance)
  azure-aci-logs   Get app logs (Azure Container Instance)
  azure-aci-delete  Delete app (Azure Container Instance)

$ az login
$ make <option>
```
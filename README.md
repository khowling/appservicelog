
Example repo to build and deploy custom container to Azure App Service, includes:

 * `infra/main.bicep` bicep Infra provisioning 
    * Azure Container registry
    * EventHub for logging
    * Plan & Webapp, including:
      * Diagnostic settings for logging to Eventhub
      * Pull Authorisation for webapp Managed Ideneity
 * `./Dockfile` Example nodejs custom container, with
   * build tasks in ACR to create image
 * `./newrelicfn` TO-BE-COMPLETED NewReclic push function

## Provision Infra

```
# alphanumeric only (no dashes)
NAME=applog$(date +%s | cut -c 6-10)

az group create -n $NAME -l westeurope
az deployment group create -g $NAME  --template-file ./infra/main.bicep --parameters name=${NAME}
```

## Container Build & Deploy

Build (using ACR build tasks)

```
az acr build --registry $NAME --image appservicelog:0.1 .
```


Deploy

```
az resource update --ids  $(az webapp show -g $NAME -n $NAME  --query id --output tsv)/config/web \
    --set properties.linuxFxVersion="Docker|$NAME.azurecr.io/appservicelog:0.1" \
    --set properties.acrUseManagedIdentityCreds=True
```

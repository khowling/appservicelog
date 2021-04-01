
Example repo to build and deploy custom container to Azure App Service, includes:

 * `infra/main.bicep` bicep Infra provisioning 
    * Azure Container registry
    * EventHub for logging
    * Plan & Webapp, including:
      * Diagnostic settings for logging to Eventhub
      * Pull Authorisation for webapp Managed Ideneity
 * `./Dockfile` Example nodejs custom container, with
   * build tasks in ACR to create image
 * `./newrelicfn` function app that pushes the Diagnostic data to NewReclic

## Provision Infra

```
# alphanumeric only (no dashes)
APPNAME=applog$(date +%s | cut -c 6-10)

az group create -n $APPNAME -l westeurope
az deployment group create -g $APPNAME  --template-file ./infra/main.bicep --parameters \
  name=${APPNAME} \
  NR_LICENSE_KEY=<YOUR NEWRELIC LICENCE KEY>
```

## Container Build & Deploy

### Build (using ACR build tasks)

```
az acr build --registry $APPNAME --image appservicelog:0.1 .
```


### Deploy the container webapp

```
az resource update --ids  $(az webapp show -g $APPNAME -n $APPNAME  --query id --output tsv)/config/web \
    --set properties.linuxFxVersion="Docker|$APPNAME.azurecr.io/appservicelog:0.1" \
    --set properties.acrUseManagedIdentityCreds=True
```


### Deploy the function app (sending to newrelic)

```
(cd newrelicfn/ && zip -r ../out.zip .)
 az functionapp deployment source config-zip -g $APPNAME -n ${APPNAME}fnlog --src ./out.zip
 ```
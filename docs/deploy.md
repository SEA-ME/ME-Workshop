# Deploy

## Prerequisite: Service Principal
Create a service principal to provision all Azure Services and also deploy the CarSharing App to Azure.

1. Open [Azure Cloud Shell]([/azure/cloud-shell/overview](http://shell.azure.com/)) in the Azure portal or [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) locally.

2. Create a new service principal in the Azure portal for your app. The service principal must be assigned the Contributor role.

    ```azurecli-interactive
        az ad sp create-for-rbac --name "CarSharingMES" --role contributor \
                                    --scopes /subscriptions/{subscription-id} \
                                    --sdk-auth
    ```
    
3. Copy the JSON object for your service principal.

    ```json
    {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        (...)
    }
    ```

## Deploy from local environment
Note: You need to have [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed locally.

1. Log into Azure
    ```
    az login --service-principal -u <clientId> -p <clientSecret> --tenant <tenantId>
    ```

2. Deploy Azure Services / our infrastructure

    ```azurecli-interactive
    az group create -g <group> -l canadacentral
    az deployment group create -g <group> -f ./deploy/infrastructure/main.bicep
    ```


## Deploy via GitHub Actions

TODO
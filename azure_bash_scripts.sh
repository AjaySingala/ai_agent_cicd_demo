# 1. Set Variables
echo "1. Set Variables"
# General
RESOURCE_GROUP=ajs-agentic-ai-demo-rg
LOCATION=centralindia

# ACR
ACR_NAME=ajsagenticacr123
IMAGE_NAME=langgraph-agent
IMAGE_TAG=latest

# App Service
APP_SERVICE_PLAN=ajs-agentic-plan
WEB_APP_NAME=ajs-agentic-webapp

# 2. Create Resource Group
echo "2. Create Resource Group"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
  
# 3. Create Azure Container Registry (ACR)
echo "3. Create Azure Container Registry (ACR)"
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true
  
# Get ACR login server:
echo "Get ACR login server:"
ACR_LOGIN_SERVER=$(az acr show \
  --name $ACR_NAME \
  --query loginServer \
  --output tsv)

echo $ACR_LOGIN_SERVER

# 4. Login to ACR
echo "4. Login to ACR"
az acr login --name $ACR_NAME

# 5. Build & Push Docker Image
echo "5. Build & Push Docker Image"
docker build -t $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG .
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

# 6. Create App Service Plan (Linux)
echo "6. Create App Service Plan (Linux)"
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux
  
# 7. Create Web App (Container-based)
echo "7. Create Web App (Container-based)"
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $WEB_APP_NAME \
  --runtime "PYTHON:3.13"
  
# 8. Configure Container Image (NEW WAY)
echo "8. Configure Container Image (NEW WAY)"
az webapp config container set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG \
  --container-registry-url https://$ACR_LOGIN_SERVER

# 9. Configure Web App to Pull from ACR
echo "9. Configure Web App to Pull from ACR"
# Using ACR Admin Credentials:
ACR_USERNAME=$(az acr credential show \
  --name $ACR_NAME \
  --query username \
  --output tsv)

echo $ACR_USERNAME

ACR_PASSWORD=$(az acr credential show \
  --name $ACR_NAME \
  --query passwords[0].value \
  --output tsv)

echo $ACR_PASSWORD

az webapp config container set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG \
  --container-registry-url https://$ACR_LOGIN_SERVER \
  --container-registry-user $ACR_USERNAME \
  --container-registry-password $ACR_PASSWORD

# 10. CRITICAL: Configure Port (VERY IMPORTANT)
echo "10. CRITICAL: Configure Port (VERY IMPORTANT)"
# Azure App Service expects your app to listen on port 80 by default, but your container uses 8000.
# So you MUST set:
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --settings WEBSITES_PORT=8000
  
# 11. Restart App
echo "11. Restart App"
az webapp restart \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP

# 12. Get App URL
echo "12. Get App URL"
az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName \
  --output tsv

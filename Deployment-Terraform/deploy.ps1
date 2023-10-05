Function DecoratedOutput {
    param(
        [Parameter (Mandatory = $true)] [String]$baseMessage,
        [Parameter (Mandatory = $false)] [String]$secondaryMessage
    )

    Write-Host "$(Get-Date -Format G): " -ForegroundColor Yellow -NoNewline

    if ($secondaryMessage) {
        Write-Host "$baseMessage " -NoNewLine
        Write-Host "$secondaryMessage" -ForegroundColor Green
    }
    else {
        Write-Host "$baseMessage"
    }    
}

$TFSTATE_RG = "cloud-shell-storage-eastus"
$STORAGEACCOUNTNAME = "cs2100320021c77e489"
$CONTAINERNAME = "cdc-terraform"

DecoratedOutput "Initializing Terraform..."
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"

if ($lastexitcode -ne 0) { return }

DecoratedOutput "Creating Terraform plan..."
terraform plan -out my.plan --var-file parameters.tfvars

if ($lastexitcode -ne 0) { return }

DecoratedOutput "Applying Terraform plan..."
terraform apply my.plan
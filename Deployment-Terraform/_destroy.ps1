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

DecoratedOutput "Creating Destroy Plan..."
terraform plan -destroy -out my.plan --var-file parameters.tfvars

if ($lastexitcode -ne 0) { return }

DecoratedOutput "Applying Destroy plan..."
terraform apply my.plan

if ($lastexitcode -ne 0) { exit }

remove-item my.plan -ErrorAction SilentlyContinue
remove-item .terraform.lock.hcl -ErrorAction SilentlyContinue
remove-item terraform.tfstate.backup -ErrorAction SilentlyContinue
remove-item terraform.tfstate -ErrorAction SilentlyContinue
remove-item .terraform -Recurse -ErrorAction SilentlyContinue
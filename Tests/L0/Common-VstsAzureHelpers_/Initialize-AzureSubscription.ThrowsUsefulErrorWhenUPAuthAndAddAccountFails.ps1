[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot/../../lib/Initialize-Test.ps1
Microsoft.PowerShell.Core\Import-Module Microsoft.PowerShell.Security
$module = Microsoft.PowerShell.Core\Import-Module $PSScriptRoot/../../../Tasks/AzurePowerShell/ps_modules/VstsAzureHelpers_ -PassThru
$endpoint = @{
    Auth = @{
        Parameters = @{
            UserName = 'Some user name'
            Password = 'Some password'
        }
        Scheme = 'UserNamePassword'
    }
    Data = @{
        SubscriptionId = 'Some subscription ID'
        SubscriptionName = 'Some subscription name'
    }
}
$variableSets = @(
    @{ Classic = $true }
    @{ Classic = $false }
)
foreach ($variableSet in $variableSets) {
    Write-Verbose ('-' * 80)
    Unregister-Mock Add-AzureAccount
    Unregister-Mock Add-AzureRMAccount
    Unregister-Mock Write-VstsTaskError
    Unregister-Mock Set-UserAgent
    Register-Mock Add-AzureAccount { throw 'Some add account error' }
    Register-Mock Add-AzureRMAccount { throw 'Some add account error' }
    Register-Mock Write-VstsTaskError
    Register-Mock Set-UserAgent
    if ($variableSet.Classic) {
        & $module {
            $script:azureModule = @{ Version = [version]'1.0' }
            $script:azureRMProfileModule = $null
        }
    } else {
        & $module {
            $script:azureModule = $null
            $script:azureRMProfileModule = @{ Version = [version]'1.2.3.4' }
        }
    }

    # Act/Assert.
    Assert-Throws {
        & $module Initialize-AzureSubscription -Endpoint $endpoint
    } -MessagePattern AZ_CredentialsError

    # Assert.
    Assert-WasCalled Write-VstsTaskError -- -Message 'Some add account error'
    if ($variableSet.Classic) {
        Assert-WasCalled Add-AzureAccount
    } else {
        Assert-WasCalled Add-AzureRMAccount
    }
}

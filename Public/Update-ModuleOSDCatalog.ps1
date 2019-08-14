<#
.SYNOPSIS
Updates the OSDCatalog PowerShell Module to the latest version

.DESCRIPTION
Updates the OSDCatalog PowerShell Module to the latest version from the PowerShell Gallery

.LINK
https://osdcatalog.osdeploy.com/module/functions/update-moduleosdcatalog

.Example
Update-ModuleOSDCatalog
#>
function Update-ModuleOSDCatalog {
    [CmdletBinding()]
    PARAM ()
    try {
        Write-Warning "Uninstall-Module -Name OSDCatalog -AllVersions -Force"
        Uninstall-Module -Name OSDCatalog -AllVersions -Force
    }
    catch {}

    try {
        Write-Warning "Install-Module -Name OSDCatalog -Force"
        Install-Module -Name OSDCatalog -Force
    }
    catch {}

    try {
        Write-Warning "Import-Module -Name OSDCatalog -Force"
        Import-Module -Name OSDCatalog -Force
    }
    catch {}
}
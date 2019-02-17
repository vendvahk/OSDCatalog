#Requires -Modules PoshWSUS
function Get-OSDWSUSUpdate {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$True)]
        [string]$WsusServer,
        #[Parameter(Mandatory)]
        [string]$WsusPort = 8530,
        [string]$Category,
        [string]$KBNumber,
        [ValidateSet('OSDBuild Windows 10','OSDBuild Server 2016','OSDBuild Server 2019','OSDUpdate Office 365','OSDUpdate Office 2016','OSDUpdate Office 2013','OSDUpdate Office 2010')]
        [string]$OSDCatalog,
        [switch]$GridView
    )

    Import-Module -Name PoshWSUS -Force
    Write-Host "Connect-PSWSUSServer" -ForegroundColor Cyan
    Connect-PSWSUSServer -WSUSserver $WsusServer -Port $WsusPort
    $Global:WsusServer = $WsusServer
    $Global:WsusPort = $WsusPort
<#     $null = $WsusServer
    $null = $WsusPort #>

    if ($OSDCatalog -eq 'OSDBuild Windows 10') {$Category = 'Windows 10'}
    if ($OSDCatalog -eq 'OSDBuild Server 2016') {$Category = 'Windows Server 2016'}
    if ($OSDCatalog -eq 'OSDBuild Server 2019') {$Category = 'Windows Server 2019'}
    if ($OSDCatalog -eq 'OSDUpdate Office 2010') {$Category = 'Office 2010'}
    if ($OSDCatalog -eq 'OSDUpdate Office 2013') {$Category = 'Office 2013'}
    if ($OSDCatalog -eq 'OSDUpdate Office 2016') {$Category = 'Office 2016'}
    if ($OSDCatalog -eq 'OSDUpdate Office 365') {$Category = 'Office 365 Client'}


    if ($Category) {
        $WsusCategory = Get-PSWSUSCategory | Where-Object {$_.Title -match "$Category"}
    } else {
        $WsusCategory = Get-PSWSUSCategory | Out-GridView -OutputMode Single -Title 'Select WSUS Category'
    }

    #$WsusCategoryName = $($WsusCategory.Title)
    #Write-Host "WsusCategoryName: $WsusCategoryName"

    $WsusCategoryUpdates = @()
    $WsusCategoryUpdates = Get-PSWSUSUpdate -Category $WsusCategory | `
    Where-Object {$_.Title -notlike "*Dynamic Cumulative*"} | `
    Where-Object {$_.IsSuperseded -eq $false} | `
    Where-Object {$_.IsLatestRevision -eq $true} | `
    Where-Object {$_.RequiresLicenseAgreementAcceptance -eq $false} | `
    Select-Object -Property * | Sort-Object -Property CreationDate -Descending

    if ($OSDCatalog -eq 'OSDUpdate Office 2010') {
        $WsusCategoryUpdates = $WsusCategoryUpdates | `
        Where-Object {$_.CreationDate -gt [datetime]'2013-07-22'} | `
        Where-Object {$_.KnowledgebaseArticles -notlike "KB2460011"} | `
        Where-Object {$_.KnowledgebaseArticles -notlike "KB2553006"} | `
        Where-Object {$_.Title -notlike "*farm-deployment*"} | `
        Where-Object {$_.Title -notlike "*Sharepoint*"} | `
        Where-Object {$_.Title -notlike "*Server*"}
        foreach ($Office in $WsusCategoryUpdates) {
            $Office.Description = ''
        }
    }

    if ($OSDCatalog -eq 'OSDUpdate Office 2013') {
        $WsusCategoryUpdates = $WsusCategoryUpdates | `
        Where-Object {$_.CreationDate -gt [datetime]'2014-01-01'} | `
        Where-Object {$_.Title -notlike "*Server*"} | `
        Where-Object {$_.Title -notlike "*Sharepoint*"} | `
        Where-Object {$_.Title -notlike "*SkyDrive*"}
        foreach ($Office in $WsusCategoryUpdates) {
            $Office.Description = ''
        }
    }

    if ($OSDCatalog -eq 'OSDUpdate Office 2016') {
        $WsusCategoryUpdates = $WsusCategoryUpdates | `
        Where-Object {$_.Title -notlike "*Server*"}
        foreach ($Office in $WsusCategoryUpdates) {
            $Office.Description = ''
        }
    }

    if ($OSDCatalog -eq 'OSDUpdate Office 365') {
        $WsusCategoryUpdates = $WsusCategoryUpdates | `
        Where-Object {$_.Title -notlike "*Server*"}
        foreach ($Office in $WsusCategoryUpdates) {
            $Office.Description = ''
        }
    }

    if ($OSDCatalog -eq 'OSDBuild Windows 10') {
        $WsusCategoryUpdates = $WsusCategoryUpdates | `
        Where-Object {$_.UpdateClassificationTitle -ne 'Upgrades'} | `
        Where-Object {$_.UpdateType -eq 'Software'} | `
        Where-Object {$_.Title -notlike "*ARM64*"} | `
        Where-Object {$_.Title -notlike "*Version Next*"}
    }

    if ($KBNumber) {
        $WsusCategoryUpdates = $WsusCategoryUpdates | Where-Object {$_.KnowledgebaseArticles -match $KBNumber}
    }

    if ($GridView.IsPresent) {
        $WsusCategoryUpdates = $WsusCategoryUpdates | Out-GridView -PassThru -Title 'Select WSUS Updates'
    }
    Return $WsusCategoryUpdates
}
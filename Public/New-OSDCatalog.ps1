<#
.SYNOPSIS
Creates Stand Alone Update Catalogs from WSUS.  Used by OSDBuilder and OSDUpdate

.DESCRIPTION
Creates Stand Alone Update Catalogs from WSUS.  Used by OSDBuilder and OSDUpdate

.LINK
https://osdcatalog.osdeploy.com/module/functions/new-osdcatalog

.PARAMETER WsusServer
WSUS Server Name

.PARAMETER WsusPort
WSUS Server Port.  Defaults to 8530

.PARAMETER CatalogName
Custom Catalog Name.  Default Name is the WSUS Update Category Name

.PARAMETER DownloadUri
Mirrors the selected Internet or WSUS Uri location.  Useful for hiding WSUS Server Information from Results

.PARAMETER GridViewGetUpdates
Select the GetUpdates in GridView before the Files are processed

.PARAMETER GridViewResults
Select the Results in GridView before the XML is created

.PARAMETER SaveDirectory
Directory to save the exported CliXml Catalogs

.PARAMETER UpdateCategory
Sets the Update Category.  If omitted, all Update Categories will be presented in GridView

.PARAMETER UpdateTextIncludes
Optionally search for the specified string in the WSUS Database

.PARAMETER UpdateTextNotIncludes
Removes results that contain the specified string

.PARAMETER OSDeployCatalog
Generates Update Catalogs used by OSDUpdate and OSDBuilder

#   Other Great Links
#   https://www.powershellgallery.com/packages/PoshWSUS
#   https://devblogs.microsoft.com/scripting/get-windows-update-status-information-by-using-powershell/
#   https://www.reddit.com/r/PowerShell/comments/3b979k/wsus_updates_combining_the_results_of_two/
#>
function New-OSDCatalog {
    [CmdletBinding(DefaultParameterSetName='WSUS')]
    PARAM (
        #===================================================================================================
        #   Both Tabs
        #===================================================================================================
        [Parameter(Mandatory = $True)]
        [string]$WsusServer,
        [string]$CatalogName,

        [ValidateSet('Internet','WSUS')]
        [string]$DownloadUri,
        #[switch]$GridViewExclude,
        [switch]$GridViewGetUpdates,
        [switch]$GridViewResults,
        [string]$SaveDirectory,
        [string]$WsusPort = '8530',
        #===================================================================================================
        #   WSUS Tab Only
        #===================================================================================================
        [Parameter(ParameterSetName = 'WSUS')]
        [string]$UpdateCategory,

        [Parameter(ParameterSetName = 'WSUS')]
        [string]$UpdateTextIncludes,
        
        [Parameter(ParameterSetName = 'WSUS')]
        [string]$UpdateTextNotIncludes,
        #===================================================================================================
        #   OSDeploy Tab Only
        #===================================================================================================
        [Parameter(ParameterSetName = 'OSDeploy')]
        [ValidateSet(
            'Office 2010 32-Bit',
            'Office 2010 64-Bit',
            'Office 2013 32-Bit',
            'Office 2013 64-Bit',
            'Office 2016 32-Bit',
            'Office 2016 64-Bit',
            'Windows 7',
            #'Windows 8.1',
            'Windows 8.1 Dynamic Update',
            'Windows 10',
            'Windows 10 1903',
            'Windows 10 Dynamic Update',
            'Windows 10 Feature On Demand',
            'Windows 10 Language Packs',
            'Windows 10 Language Interface Packs',
            'Windows Server 2012 R2',
            'Windows Server 2012 R2 Dynamic Update',
            'Windows Server 2016',
            'Windows Server 2019')]
        [string]$OSDeployCatalog
    )
    #===================================================================================================
    #   19.2.28 OSDCatalog Version
    #===================================================================================================
    $OSDCatalogVersion = $(Get-Module -Name OSDCatalog | Sort-Object Version | Select-Object Version -Last 1).Version
    Write-Verbose "OSDCatalog Module $OSDCatalogVersion" -Verbose
    #===================================================================================================
    #   19.2.28 UpdateServices Namespace
    #===================================================================================================
    try 
    {
        [Reflection.Assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
    }
    catch 
    {
        Throw  "Unable to load WSUS assembly, do you have the WSUS Admin console installed?"
    }
    #===================================================================================================
    #   19.2.28 Wsus Registry
    #===================================================================================================
    #If ((Get-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer).WUServer -match '(?<Protocol>^http(s)?)(?:://)(?<Computername>(?:(?:\w+(?:\.)?)+))(?::)?(?<Port>.*)') {
    #    $WsusServer = $Matches.Computername
    #    $WsusPort = $Matches.Port
    #}
    #===================================================================================================
    #   19.2.28 Wsus Connect
    #===================================================================================================
    try 
    {
        Write-Verbose "Connecting to $($WsusServer) Port: $($WsusPort)" -Verbose
        $Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$Secure,$WsusPort)  
    }
    catch
    {
        Throw ("Unable to connect to Server: {0} on port {1}" -f $ServerName, $ServerPort)
    }
    #===================================================================================================
    #   19.2.28 OSDeploy Catalog
    #===================================================================================================
    if ($OSDeployCatalog) {
        if ($OSDeployCatalog -eq 'Office 2010 32-Bit') {
            $UpdateCategory = 'Office 2010'
        }
        if ($OSDeployCatalog -eq 'Office 2010 64-Bit') {
            $UpdateCategory = 'Office 2010'
        }
        if ($OSDeployCatalog -eq 'Office 2013 32-Bit') {
            $UpdateCategory = 'Office 2013'
        }
        if ($OSDeployCatalog -eq 'Office 2013 64-Bit') {
            $UpdateCategory = 'Office 2013'
        }
        if ($OSDeployCatalog -eq 'Office 2016 32-Bit') {
            $UpdateCategory = 'Office 2016'
        }
        if ($OSDeployCatalog -eq 'Office 2016 64-Bit') {
            $UpdateCategory = 'Office 2016'
        }
        if ($OSDeployCatalog -like "*Windows*") {$UpdateCategory = $OSDeployCatalog}
        $CatalogName = "$OSDeployCatalog"
        
        if ($OSDeployCatalog -eq "Windows 10 1903") {
            $OSDeployCatalog -eq "Windows 10"
            $CatalogName = "Windows 10 1903"
            $UpdateCategory = 'Windows 10, version 1903 and later'
        }
    }
    #===================================================================================================
    #   19.3.1 Select Update Category
    #===================================================================================================
    if (!($UpdateCategory)) {
        $SelectUpdateCategory = $Wsus.GetUpdateCategories() | `
        Where-Object {$_.Type -eq 'Product'} | `
        Select-Object -Property Title | `
        Out-GridView -OutputMode Single -Title 'Select a WSUS Update Category'
        $UpdateCategory = "$($SelectUpdateCategory.Title)"
    }
    Write-Verbose "WSUS Update Category: $UpdateCategory" -Verbose
    #===================================================================================================
    #   19.3.1 Set Catalog Name
    #===================================================================================================
    if (!($CatalogName)) {$CatalogName = $UpdateCategory}
    Write-Verbose "OSDCatalog Name: $CatalogName" -Verbose
    #===================================================================================================
    #   19.3.1 Set UpdateCategories
    #===================================================================================================
    $UpdateCategories = $null
    $UpdateCategories = $Wsus.GetUpdateCategories() | Where-Object {$_.Title -eq "$UpdateCategory"}
    if ($null -eq $UpdateCategories) {
        Write-Warning "WSUS Update Category: Not Found . . . Exiting!"
        Return
    }
    #===================================================================================================
    #   19.3.1 Setup UpdateScope
    #===================================================================================================
    $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    $UpdateScope.ApprovedStates = 'Any'
    $UpdateScope.UpdateTypes = 'All'
    $UpdateScope.TextIncludes = "$UpdateTextIncludes"
    $UpdateScope.TextNotIncludes = "$UpdateTextNotIncludes"
    if ($UpdateCategories) {
        $UpdateScope.Categories.AddRange($UpdateCategories)
    }
    #$UpdateScope.Classifications              : {}
    $UpdateScope.IncludedInstallationStates = 'All'
    $UpdateScope.ExcludedInstallationStates = '0'
    #$UpdateScope.IsWsusInfrastructureUpdate   : False
    #$UpdateScope.UpdateApprovalActions        : All
    #$UpdateScope.ApprovedComputerTargetGroups : {}
    #$UpdateScope.UpdateSources                : All
    #$UpdateScope.ExcludeOptionalUpdates       : False
    #$UpdateScope.UpdateApprovalScope          : 
    #$UpdateScope.FromArrivalDate              : 1/1/0001 12:00:00 AM
    #$UpdateScope.ToArrivalDate                : 12/31/9999 11:59:59 PM
    #$UpdateScope.FromCreationDate             : 1/1/0001 12:00:00 AM
    #$UpdateScope.ToCreationDate               : 12/31/9999 11:59:59 PM
    #$UpdateScope
    #===================================================================================================
    #   19.3.1 GetUpdates
    #===================================================================================================
    $GetUpdates = $Wsus.GetUpdates($UpdateScope)
    #===================================================================================================
    #   19.3.1 Filter GetUpdates OSDEploy
    #===================================================================================================
    if ($OSDeployCatalog) {
        $GetUpdates = $GetUpdates | Where-Object {$_.IsDeclined -eq $false}
        $GetUpdates = $GetUpdates | Where-Object {$_.IsLatestRevision -eq $true}
        $GetUpdates = $GetUpdates | Where-Object {$_.IsSuperseded -eq $false}
        $GetUpdates = $GetUpdates | Where-Object {$_.LegacyName -notlike "*ARM64*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.LegacyName -notlike "*Partner*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.LegacyName -notlike "*PreRTM*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.LegacyName -notlike "*farm-deployment*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*ARM64*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Beta*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Insider Preview*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Preview of*"}
        #$GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -ne 'Drivers'}

        #Feature Updates
        $GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -ne 'Upgrades'}
        #$GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'5/5/2019'}
        #$GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -eq 'Upgrades'}
    }
    if ($OSDeployCatalog -eq 'Office 2010 32-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*32-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'7/1/2013'}
    }
    if ($OSDeployCatalog -eq 'Office 2010 64-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*64-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'7/1/2013'}
    }
    if ($OSDeployCatalog -eq 'Office 2013 32-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*32-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
    }
    if ($OSDeployCatalog -eq 'Office 2013 64-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*64-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
    }
    if ($OSDeployCatalog -eq 'Office 2016 32-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*32-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
    }
    if ($OSDeployCatalog -eq 'Office 2016 64-Bit') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -like "*64-Bit*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*SharePoint*"}
    }
    if ($OSDeployCatalog -eq 'Windows 7x') {
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'5/1/2012'}
    }
    if ($OSDeployCatalog -eq 'Windows 7x') {
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'5/1/2012'}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Internet Explorer 8*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Internet Explorer 9*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Internet Explorer 10*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '977074'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '978542'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979099'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979309'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979482'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979538'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979687'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '979688'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '980408'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '982132'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '982665'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '982799'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2032276'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2281679'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2284742'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2345886'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2347290'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2378111'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2387149'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2387530'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2419640'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2423089'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2442962'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2454826'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2467023'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2483614'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2535512'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2748349'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2853587'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2912390'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2928120'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2984976'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2998812'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3020387'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3075222'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3081954'}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Language*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Security Only*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -ne 'Feature Packs' -and $_.LegacyName -notlike "*DOTNET45x*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -ne 'Service Packs'}
        #Internet Explorer
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB3170106'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB3185319'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4014661'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4018271'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4021558'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4025252'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4034733'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4036586'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4040685'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4047206'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4052978'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4056568'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4074736'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4089187'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4092946'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4096040'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4103768'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4230450'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4339093'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne 'KB4343205'}
    }
    if ($OSDeployCatalog -eq 'Windows 8.1') {
    }
    if ($OSDeployCatalog -eq 'Windows 8.1 Dynamic Update') {
    }
    if ($OSDeployCatalog -eq 'Windows 10') {
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3186568'}   #Microsoft .NET Framework 4.7 for Windows 10 Version 1607 (KB3186568)
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '4033393'}   #Microsoft .NET Framework 4.7.1 for Windows 10 Version 1607 (KB4033393)
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Language Packs*"}
    }
    if ($OSDeployCatalog -eq 'Windows 10 1903') {
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Language Packs*"}
    }
    if ($OSDeployCatalog -eq 'Windows 10 Dynamic Update') {
    }
    if ($OSDeployCatalog -eq 'Windows 10 Feature On Demand') {
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'1/1/2016'}
        $GetUpdates = $GetUpdates | Where-Object {$_.LegacyName -notlike "*FeatureOnDemandLang*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*GDRDU*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Language*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Windows Server 2016*"}
    }
    if ($OSDeployCatalog -eq 'Windows 10 Language Packs') {

    }
    if ($OSDeployCatalog -eq 'Windows 10 Language Interface Packs') {
    }
    if ($OSDeployCatalog -eq 'Windows Server 2012 R2') {
        $GetUpdates = $GetUpdates | Where-Object {$_.CreationDate -gt [datetime]'7/7/2014'}
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '2934520'}   #Microsoft .NET Framework 4.5.2
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3102467'}   #Microsoft .NET Framework 4.6.1
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '3186539'}   #Microsoft .NET Framework 4.7
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -ne '4033369'}   #Microsoft .NET Framework 4.7.1
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Internet Explorer 8*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Internet Explorer 9*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Language*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.Title -notlike "*Security Only*"}
        $GetUpdates = $GetUpdates | Where-Object {$_.UpdateClassificationTitle -ne 'Feature Packs' -and $_.LegacyName -notlike "*DOTNET45x*"}
    }  
    $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*3125217*"}
    $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*3186568*"} # Microsoft .NET Framework 4.7
    $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*3186607*"} # Microsoft .NET Framework 4.7 Language Packs for Windows 10 Version 1607
    $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*4033393*"} # Microsoft .NET Framework 4.7.1
    $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*4033418*"} # Microsoft .NET Framework 4.7.1 Language Packs for Windows 10 Version 1607
    #===================================================================================================
    #   Process Excluded Updates
    #===================================================================================================
<#     $ExcludeXmls = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\Exclude" "*$UpdateCategory.xml"
    foreach ($ExcludeXml in $ExcludeXmls) {
        [array]$ExcludedUpdates += Import-Clixml -Path "$($ExcludeXml.FullName)"
    }
    foreach ($ExcludedUpdate in $ExcludedUpdates) {
        $GetUpdates = $GetUpdates | Where-Object {$_.KnowledgeBaseArticles -notlike "*$($ExcludedUpdate.KnowledgebaseArticles)*"}
    } #>
    #===================================================================================================
    #   GridViewGetUpdates
    #===================================================================================================
    If ($GridViewGetUpdates) {$GetUpdates = $GetUpdates | Sort-Object CreationDate | Out-GridView -PassThru -Title 'Select Updates'}
    #===================================================================================================
    #   NewExcludedUpdates
    #===================================================================================================
    if ($GridViewExclude) {
        $NewExcludedUpdates = $GetUpdates | Sort-Object CreationDate | Out-GridView -PassThru -Title 'Select Updates to Exclude'
        $NewExcludedUpdates = $NewExcludedUpdates | Select-Object -Property CreationDate, Title, KnowledgeBaseArticles
        $NewExcludedUpdates | Export-Clixml "$env:TEMP\$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $UpdateCategory.xml"
        Return
    }
    #===================================================================================================
    #   Get Update Information
    #===================================================================================================
    $AllUpdates = @()

    foreach ($CategoryItem in $GetUpdates) {
        Write-Host "$($CategoryItem.KnowledgeBaseArticles) $($CategoryItem.CreationDate) $($CategoryItem.Title)" -ForegroundColor Gray
        
        $UpdateFile = @()
        $UpdateFile = Get-WsusUpdateFile -UpdateName $($CategoryItem.Title) | Select-Object -Property *
        #$UpdateFile | Out-GridView -Wait
        #===================================================================================================
        #   OSDeploy Catalog Filters
        #===================================================================================================
        if ($OSDeployCatalog) {
            $UpdateFile = $UpdateFile | Where-Object {$_.Type -ne 'Express'}
            $UpdateFile = $UpdateFile | Where-Object {$_.Name -notlike "*ARM64*"}
            $UpdateFile = $UpdateFile | Where-Object {$_.Name -notlike "*.exe"}
            $UpdateFile = $UpdateFile | Where-Object {$_.Name -notlike "*.txt"}
        }

        foreach ($Update in $UpdateFile) {
            #===================================================================================================
            #   DownloadUri
            #===================================================================================================
            $FileUri = $Update.FileUri
            $OriginUri = $Update.OriginUri
            $OSDCore = ''
            $OSDWinPE = ''

            if ($DownloadUri -eq 'Internet') {$FileUri = $OriginUri}
            if ($DownloadUri -eq 'WSUS') {$OriginUri = $FileUri}
            #===================================================================================================
            #   Update OS
            #===================================================================================================
            $UpdateOS = ''
            if ($CatalogName -like "Windows 7*") {$UpdateOS = 'Windows 7'}
            elseif ($CatalogName -like "Windows 8.1*") {$UpdateOS = 'Windows 8.1'}
            elseif ($CatalogName -like "Windows 10*") {$UpdateOS = 'Windows 10'}
            elseif ($CatalogName -like "Windows Server 2012 R2*") {$UpdateOS = 'Windows Server 2012 R2'}
            elseif ($CatalogName -like "Windows Server 2016*") {$UpdateOS = 'Windows Server 2016'}
            elseif ($CatalogName -like "Windows Server 2019*") {$UpdateOS = 'Windows Server 2019'}
            if ($UpdateOS -eq 'Windows 7') {$OSDCore = $True}
            if ($UpdateOS -eq 'Windows 8.1') {$OSDCore = $True}
            if ($UpdateOS -eq 'Windows Server 2012 R2') {$OSDCore = $True}
            #===================================================================================================
            #   Update Arch
            #===================================================================================================
            $UpdateArch = ''
            if ($Update.Title -like "*32-Bit*") {$UpdateArch = 'x86'}
            elseif ($Update.Title -like "*64-Bit*") {$UpdateArch = 'x64'}
            elseif ($CategoryItem.LegacyName -like "*x86*") {$UpdateArch = 'x86'}
            elseif ($CategoryItem.LegacyName -like "*x64*") {$UpdateArch = 'x64'}
            elseif ($CategoryItem.LegacyName -like "*amd64*") {$UpdateArch = 'x64'}
            elseif ($Update.FileName -like "*x86*") {$UpdateArch = 'x86'}
            elseif ($Update.FileName -like "*x64*") {$UpdateArch = 'x64'}
            elseif ($Update.Title -like "*x86*") {$UpdateArch = 'x86'}
            elseif ($Update.Title -like "*x64*") {$UpdateArch = 'x64'}

            #===================================================================================================
            #   Update Build
            #===================================================================================================
            $UpdateBuild = ''
            if ($Update.Title -like "*1507*") {$UpdateBuild = '1507'}
            if ($Update.Title -like "*1511*") {$UpdateBuild = '1511'}
            if ($Update.Title -like "*1607*") {$UpdateBuild = '1607'}
            if ($Update.Title -like "*1703*") {$UpdateBuild = '1703'}
            if ($Update.Title -like "*1709*") {$UpdateBuild = '1709'}
            if ($Update.Title -like "*1803*") {$UpdateBuild = '1803'}
            if ($Update.Title -like "*1809*") {$UpdateBuild = '1809'}
            if ($Update.Title -like "*1903*") {$UpdateBuild = '1903'}
            if ($Update.Title -like "*Windows Server 2019*") {$UpdateBuild = '1809'}

            if ($Update.KnowledgeBaseArticles -eq '3079343') {$UpdateBuild = '1507'}
            if ($Update.KnowledgeBaseArticles -eq '3125217') {$UpdateBuild = '1507'}
            if ($Update.KnowledgeBaseArticles -eq '3125217') {$UpdateBuild = '1507'}
            if ($Update.KnowledgeBaseArticles -eq '3173427') {$UpdateBuild = '1507'}
            if ($Update.KnowledgeBaseArticles -eq '3173428') {$UpdateBuild = '1511'}

            if (!($UpdateBuild)) {
                if ($CategoryItem.LegacyName -like "*RS1*") {$UpdateBuild = '1607'}
                if ($CategoryItem.LegacyName -like "*RS2*") {$UpdateBuild = '1703'}
                if ($CategoryItem.LegacyName -like "*RS3*") {$UpdateBuild = '1709'}
                if ($CategoryItem.LegacyName -like "*RS4*") {$UpdateBuild = '1803'}
                if ($CategoryItem.LegacyName -like "*RS5*") {$UpdateBuild = '1809'}
            }

            if ($CategoryItem.LegacyName -like "KB3161102-Win10-RTM-X*") {$UpdateBuild = '1507'}

            if (!($UpdateBuild)) {
                if ($CategoryItem.LegacyName -like "*TH1*") {$UpdateBuild = '1507'}
                if ($CategoryItem.LegacyName -like "*TH2*") {$UpdateBuild = '1511'}
            }
            #===================================================================================================
            #   Update Group
            #===================================================================================================
            $UpdateGroup = ''
            if ($CategoryItem.LegacyName -like "*MRT*") {$UpdateGroup = 'MRT'}
            if ($CategoryItem.Description -like "ComponentUpdate*") {$UpdateGroup = 'ComponentDU'}
            if ($CategoryItem.LegacyName -like "*CriticalDU*") {$UpdateGroup = 'ComponentDU Critical'}
            if ($CategoryItem.LegacyName -like "*SafeOSDU*") {$UpdateGroup = 'ComponentDU SafeOS'}
            if ($CategoryItem.Description -like "SetupUpdate*") {$UpdateGroup = 'SetupDU'}
            if ($CategoryItem.LegacyName -like "*SetupDU*") {$UpdateGroup = 'SetupDU'}
            if ($CategoryItem.LegacyName -like "*ServicingStack*") {$UpdateGroup = 'SSU'}
            if ($Update.Title -like "*Adobe Flash Player*") {$UpdateGroup = 'AdobeSU'}
            if ($Update.Title -like "*Cumulative Update for Windows*") {$UpdateGroup = 'LCU'}
            if ($Update.Title -like "*Cumulative Update for .NET*") {$UpdateGroup = 'DotNetCU'}

            if ($Update.KnowledgeBaseArticles -eq '3173427') {$UpdateGroup = 'SSU'}
            if ($Update.KnowledgeBaseArticles -eq '3173428') {$UpdateGroup = 'SSU'}
            #===================================================================================================
            #   Update Title (Remove Special Characters)
            #===================================================================================================
            $Update.Title = $Update.Title -replace '\[',''
            $Update.Title = $Update.Title -replace ']',''
            $Update.Title = $Update.Title -replace '\"',''  #Quote
            $Update.Title = $Update.Title -replace '\\',''
            $Update.Title = $Update.Title -replace '/',''
            $Update.Title = $Update.Title -replace '\?',''
            $Update.Title = $Update.Title -replace ',',''
            $Update.Title = $Update.Title -replace ':',''
            $Update.Title = $Update.Title -replace ';',''
            $Update.Title = $Update.Title -replace '  ',''  #Double Space

            if (!($UpdateGroup)) {if ($Update.Title -like "*.NET Framework*") {$UpdateGroup = 'DotNet'}}
            #$CategoryItem | Out-GridView
            #Return
            #===================================================================================================
            #   Create Object
            #===================================================================================================
            Write-Host "$($Update.Name) $($Update.LegacyName) " -ForegroundColor DarkGray
            $UpdateProperties = [PSCustomObject]@{
                'Catalog' = $CatalogName;
                'OSDVersion' = $OSDCatalogVersion;
                'OSDStatus' = '';
                'UpdateOS' = $UpdateOS;
                'UpdateBuild' = $UpdateBuild;
                'UpdateArch' = $UpdateArch;
                'UpdateGroup' = $UpdateGroup;
            
                'CreationDate' = [datetime]$CategoryItem.CreationDate;
                'KBNumber' = [string]$CategoryItem.KnowledgeBaseArticles;
                'Title' = $Update.Title;
                'LegacyName' = $CategoryItem.LegacyName;
                'Type' = $Update.Type;
                'FileName' = $Update.Name;
                'Size' = $Update.TotalBytes;
            
                'CompanyTitles' = $CategoryItem.CompanyTitles;
                'ProductFamilyTitles' = $CategoryItem.ProductFamilyTitles;
                'Category' = $CategoryItem.ProductTitles;
                'UpdateClassificationTitle' = $CategoryItem.UpdateClassificationTitle;
                'MsrcSeverity' = $CategoryItem.MsrcSeverity;
                'SecurityBulletins' = $CategoryItem.SecurityBulletins;
                'UpdateType' = $CategoryItem.UpdateType;
                'PublicationState' = $CategoryItem.PublicationState;
                'HasLicenseAgreement' = $CategoryItem.HasLicenseAgreement;
                'RequiresLicenseAgreementAcceptance' = $CategoryItem.RequiresLicenseAgreementAcceptance;
                'State' = $CategoryItem.State;
                'IsLatestRevision' = $CategoryItem.IsLatestRevision;
                'HasEarlierRevision' = $CategoryItem.HasEarlierRevision;
                'IsBeta' = $CategoryItem.IsBeta;
                'HasStaleUpdateApprovals' = $CategoryItem.HasStaleUpdateApprovals;
                'IsApproved' = $CategoryItem.IsApproved;
                'IsDeclined' = $CategoryItem.IsDeclined;
                'HasSupersededUpdates' = $CategoryItem.HasSupersededUpdates;
                'IsSuperseded' = $CategoryItem.IsSuperseded;
                'IsWsusInfrastructureUpdate' = $CategoryItem.IsWsusInfrastructureUpdate;
                'IsEditable' = $CategoryItem.IsEditable;
                'UpdateSource' = $CategoryItem.UpdateSource;
                'AdditionalInformationUrls' = $CategoryItem.AdditionalInformationUrls;
                'Description' = $CategoryItem.Description;
                'ReleaseNotes' = $CategoryItem.ReleaseNotes;
                
                'FileUri' = $FileUri;
                'OriginUri' = $OriginUri;
                'Hash' = [string]$Update.Hash;
                'AdditionalHash' = [string]$Update.AdditionalHash;
                'OSDCore' = $OSDCore;
                'OSDWinPE' = $OSDWinPE;
                'OSDGuid' = New-Guid
            }
            $AllUpdates += $UpdateProperties
        }
    }
    $AllUpdates = $AllUpdates | Sort-Object OriginUri -Unique
    $AllUpdates = $AllUpdates | Sort-Object CreationDate, KBNumber, Title
    If ($GridViewResults) {
        $AllUpdates = $AllUpdates | Sort-Object CreationDate | Out-GridView -PassThru -Title 'Select OSDCatalog Results'
    }
    if ($SaveDirectory) {
        $AllUpdates | Export-Clixml -Path "$SaveDirectory\$CatalogName.xml" -Force
        Write-Verbose "Results: Import-CliXml '$SaveDirectory\$CatalogName.xml' | Out-GridView" -Verbose
    } else {
        Return $AllUpdates
    }
}
function Get-WsusUpdateFile {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [string]$UpdateName
    )

    Write-Verbose "Using 'Update Name' set name"
    #Search for updates
    Write-Verbose "Searching for update/s"
    $patches = @($wsus.SearchUpdates($UpdateName))
    If ($patches -eq 0) {
        Write-Error "Update $update could not be found in WSUS!"
        Break
    } Else {
        $Items = $patches | ForEach {
            $Patch = $_
            Write-Verbose ("Adding NoteProperty for {0}" -f $_.Title)                    
            $_.GetInstallableItems() | ForEach {
                $itemdata = $_ | Add-Member -MemberType NoteProperty -Name KnowledgeBaseArticles -value $patch.KnowledgeBaseArticles -PassThru
                $itemdata | Add-Member -MemberType NoteProperty -Name Title -value $patch.Title -PassThru
            }
        }                
    }
    ForEach ($item in $items) {
        Write-Verbose ("Getting installable items on {0}" -f $item.Title)
        Try {
            $filedata = $item | Select-Object -Expand Files | Add-Member -MemberType NoteProperty -Name KnowledgeBaseArticles -value $item.KnowledgeBaseArticles -PassThru
            $filedata | Add-Member -MemberType NoteProperty -Name Title -value $item.Title -PassThru
        } Catch {
            Write-Warning ("{0}: {1}" -f $item.id.id,$_.Exception.Message)
        }
    }
}
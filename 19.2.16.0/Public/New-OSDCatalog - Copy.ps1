#Requires -Modules PoshWSUS
function New-OSDCatalog {
    [CmdletBinding()]
    PARAM (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$InputObject,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$WsusServer = 'wsus',
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$WsusPort = '8530'
    )

    begin {
        Import-Module -Name PoshWSUS -Force
        Connect-PSWSUSServer -WSUSserver $WsusServer -Port $WsusPort
        $AllUpdates = @()
    }
    process {

        $InputObject | Out-GridView -PassThru
        Return

        foreach ($CategoryItem in $InputObject) {
            Write-Host "$($CategoryItem.Title)" -ForegroundColor Cyan
            Return
            $UpdateFile = @()
            $UpdateFile = Get-PSWSUSUpdateFile -UpdateName $($CategoryItem.Title) | Select-Object -Property *
            
            foreach ($Update in $UpdateFile) {
                $UpdateProperties = [PSCustomObject]@{
                    'DateCreated' = $CategoryItem.CreationDate;
                    'CompanyTitles' = $CategoryItem.CompanyTitles;
                    'ProductFamilyTitles' = $CategoryItem.ProductFamilyTitles;
                    'Category' = $CategoryItem.ProductTitles;
                    'UpdateClassificationTitle' = $CategoryItem.UpdateClassificationTitle;
                    'MsrcSeverity' = $CategoryItem.MsrcSeverity;
                    'Title' = $Update.Title;
                    'KBNumber' = $Update.KnowledgeBaseArticles;
                    'FileName' = $Update.Name;
                    'Size' = $Update.TotalBytes;
                    'IsLatestRevision' = $CategoryItem.IsLatestRevision;
                    'HasEarlierRevision' = $CategoryItem.HasEarlierRevision;
                    'IsBeta' = $CategoryItem.IsBeta;
                    'IsApproved' = $CategoryItem.IsApproved;
                    'IsDeclined' = $CategoryItem.IsDeclined;
                    'DefaultPropertiesLanguage' = $CategoryItem.DefaultPropertiesLanguage;
                    'HasLicenseAgreement' = $CategoryItem.HasLicenseAgreement;
                    'RequiresLicenseAgreementAcceptance' = $CategoryItem.RequiresLicenseAgreementAcceptance;
                    'State' = $State.IsLatestRevision;
                    'HasSupersededUpdates' = $HasSupersededUpdates.IsLatestRevision;
                    'IsSuperseded' = $CategoryItem.IsSuperseded;
                    'Description' = $CategoryItem.Description;
                    'ReleaseNotes' = $CategoryItem.ReleaseNotes;
                    'KBUrl' = $CategoryItem.AdditionalInformationUrls;
                    'OriginUri' = $Update.OriginUri;
                    'UpdateID' = $CategoryItem.UpdateID
                }
                $AllUpdates += $UpdateProperties
            }
        }
        Return
        $AllUpdates = $AllUpdates | Sort-Object DateCreated -Descending
        $AllUpdates
<#         Write-Host "$CatalogPath\$CategoryName.xml" -ForegroundColor Cyan
        $AllUpdates | Export-Clixml -Path "$CatalogPath\$CategoryName.xml"
        
        Write-Host "$CatalogPath\$CategoryName.json" -ForegroundColor Cyan
        $AllUpdates | ConvertTo-Json | Out-File "$CatalogPath\$CategoryName.json" #>
    }
    end {}
}
#Requires -Modules PoshWSUS
function New-OSDCatalog {
    [CmdletBinding()]
    PARAM (
        [Parameter(            
            Mandatory = $True,
            Position = 0,
            ValueFromPipeline = $True)]
            [system.object]
            [ValidateNotNullOrEmpty()]
            $InputObject,
        #[Parameter(ValueFromPipeline)]
        #[string]$WsusServer,
        #[Parameter(ValueFromPipeline)]
        #[string]$WsusPort = '8530',
        [string]$SaveXML,
        [switch]$GridView
    )

    begin {
        Import-Module -Name PoshWSUS -Force
        Connect-PSWSUSServer -WSUSserver $WsusServer -Port $WsusPort
        $CategoryUpdates = @()
        $AllUpdates = @()
    }
    process {
        foreach ($Item in $InputObject) {
            if ($Item.Title) {
                #Write-Host "Reading $($Item.Title)" -ForegroundColor DarkGray
                $CategoryUpdates += $Item
            }
        }
    }
    end {
        foreach ($CategoryItem in $CategoryUpdates) {
            Write-Host "Processing $($CategoryItem.Title)" -ForegroundColor DarkGray
    
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
        $AllUpdates = $AllUpdates | Sort-Object DateCreated -Descending

        if ($Gridview.IsPresent) {
            $AllUpdates = $AllUpdates | Out-GridView -PassThru -Title 'Select Updates'
        }

        if ($SaveXML) {
            Write-Host "SaveXML: $SaveXML" -ForegroundColor Cyan
            $AllUpdates | Export-Clixml -Path "$SaveXML"
        }

        Return $AllUpdates
    }
}
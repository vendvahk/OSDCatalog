# OSDCatalog

# View the RAW Windows 10 Updates without the links
Get-OSDWSUSUpdate -WsusServer wsus -OSDCatalog "OSDBuild Windows 10" -GridView

# View Office 2016 Category
Get-OSDWSUSUpdate -WsusServer wsus -Category "Office 2016" -GridView

# Pipe to New-OSDCatalog to get the URLs
Get-OSDWSUSUpdate -WsusServer wsus -OSDCatalog "OSDBuild Windows 10" | `
New-OSDCatalog -SaveXML "C:\Catalogs\OSDBuild Windows 10.xml"

# Office Catalogs
Get-OSDWSUSUpdate -WsusServer wsus -OSDCatalog "OSDUpdate Office 2010" | `
New-OSDCatalog -SaveXML "C:\Catalogs\OSDUpdate Office 2010.xml"

Get-OSDWSUSUpdate -WsusServer wsus -OSDCatalog "OSDUpdate Office 2013" | `
New-OSDCatalog -SaveXML "C:\Catalogs\OSDUpdate Office 2013.xml"

Get-OSDWSUSUpdate -WsusServer wsus -OSDCatalog "OSDUpdate Office 2016" | `
New-OSDCatalog -SaveXML "C:\Catalogs\OSDUpdate Office 2016.xml"
## OSDCatalog
https://osdcatalog.osdeploy.com/

This is fork of deleted https://github.com/OSDeploy/OSDCatalog repo.

## OSDCatalog usage

### Create Windows 10 catalog
```
New-OSDCatalog -WsusServer wsus -SaveDirectory "C:\Catalogs\" -OSDeployCatalog "Windows 10"
```
### Create Windows Server 2012 R2 catalog
```
New-OSDCatalog -WsusServer wsus -SaveDirectory "C:\Catalogs\" -OSDeployCatalog "Windows Server 2012 R2"
```
### Office 2016 Catalog
```
New-OSDCatalog -WsusServer wsus -SaveDirectory "C:\Catalogs\" -OSDeployCatalog "Office 2016"
```

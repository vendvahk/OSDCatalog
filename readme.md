This is fork of deleted https://github.com/OSDeploy/OSDCatalog repo.

## OSDCatalog
https://osdcatalog.osdeploy.com/

### Overview (form link above)
OSDCatalog is the PowerShell Module that I use to generation WSUS XML files for [OSDBuilder](https://www.osdeploy.com/osdbuilder) and [OSDUpdate](https://www.osdeploy.com/osdupdate). I didn't develop this for everybody's to use, just for me personally so I wouldn't have to do everything manually, but I have always been one to share my work.
Keep in mind this is not 100% ready for your environment, as I've only tested it on my WSUS Virtual Machine. I don't have plans to make this work for YOUR environment, but if you would like to help me with that, feel free to pull from GitHub (original repo has been deleted) and give me a hand.

## How to setup WSUS enviroment
[WSUS Server readme](wsus/WSUS%20server%20readme.md)

## Module Usage

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

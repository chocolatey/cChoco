[![Build status](https://ci.appveyor.com/api/projects/status/qma3jnh23w5vjt46?svg=true)](https://ci.appveyor.com/project/LawrenceGripper/cchoco)

Community Chocolatey DSC Resource - @lawrencegripper
=============================

This resource is aimed at getting and installing packages from the choco gallery.

The resource takes the name of the package and will then install that package. 

See list of packages here: https://chocolatey.org/packages

Contributing
=============================

Happy to accept new features and fixes. Outstanding issues which can be worked on tagged HelpedWanted under issues. 

Build and Publishing 
============================

AppveyorCIScript.ps1 and appveyor.yaml are used to package up the resource and publish to the Powershell Gallery. 

The script does the following:
- Test the resources using 'xDSCResourceDesigner'
- Update the version in the manifest file
- Publish the module to the powershell gallery
- Checkin updated manifest file to github

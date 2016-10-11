| Branch        | Status        |
| ------------- | ------------- |
| master        | [![Build status](https://ci.appveyor.com/api/projects/status/qma3jnh23w5vjt46/branch/master?svg=true&passingText=master%20-%20OK&pendingText=master%20-%20PENDING&failingText=master%20-%20FAILED)](https://ci.appveyor.com/project/LawrenceGripper/cchoco/branch/master) |
| dev           | [![Build status](https://ci.appveyor.com/api/projects/status/qma3jnh23w5vjt46/branch/development?svg=true&passingText=development%20-%20OK&pendingText=development%20-%20PENDING&failingText=development%20-%20FAILED)](https://ci.appveyor.com/project/LawrenceGripper/cchoco/branch/development) |

Community Chocolatey DSC Resource
=============================

This resource is aimed at getting and installing packages from the choco gallery.

The resource takes the name of the package and will then install that package. 

See [ExampleConfig.ps1](ExampleConfig.ps1) for example usage.

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
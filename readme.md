| Branch        | Status        |
| ------------- | ------------- |
| master        | [![Build status](https://ci.appveyor.com/api/projects/status/qma3jnh23w5vjt46/branch/master?svg=true&passingText=master%20-%20OK&pendingText=master%20-%20PENDING&failingText=master%20-%20FAILED)](https://ci.appveyor.com/project/LawrenceGripper/cchoco/branch/master) |
| development           | [![Build status](https://ci.appveyor.com/api/projects/status/qma3jnh23w5vjt46/branch/development?svg=true&passingText=development%20-%20OK&pendingText=development%20-%20PENDING&failingText=development%20-%20FAILED)](https://ci.appveyor.com/project/LawrenceGripper/cchoco/branch/development) |

# Community Chocolatey DSC Resource

[![Join the chat at https://gitter.im/chocolatey/cChoco](https://badges.gitter.im/chocolatey/cChoco.svg)](https://gitter.im/chocolatey/cChoco?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This resource is aimed at getting and installing packages using Chocolatey.

The resource takes the name of the package and will then install that package.

See [ExampleConfig.ps1](ExampleConfig.ps1) for example usage.

See list of packages here: https://chocolatey.org/packages

## Contributing

Happy to accept new features and fixes. Outstanding issues which can be worked on tagged `Up For Grabs` under issues.

### Submitting a PR

Here's the general process of fixing an issue in the DSC Resource Kit:
1. Fork the repository.
3. Clone your fork to your machine.
4. It's preferred to create a non-master working branch where you store updates.
5. Make changes.
6. Write pester tests to ensure that the issue is fixed.
7. Submit a pull request to the development branch.
8. Make sure all tests are passing in AppVeyor for your pull request.
9. Make sure your code does not contain merge conflicts.
10. Address comments (if any).

### Build and Publishing

AppVeyor is used to package up the resource and publish to the PowerShell Gallery (on successful build from a newly pushed tag only).

The AppVeyor scripts do the following:
- Test the resources using 'xDSCResourceDesigner'
- Verify best practises using 'PSScriptAnalyzer'
- Update the version in the manifest file
- Publish the module to the PowerShell gallery
- Check in updated manifest file to GitHub

To build:

1. Update `ModuleVersion` in `cChoco.psd1` - use `major.minor.patch.0`;
2. Update `version` in `appveyor.yml` - use `major.minor.patch.{build}`;
3. Merge development branch to master - `git checkout master`, `git merge development`;
4. Tag master with new version - `git tag v<major.minor.patch>`;
5. Push changes with tag `git push v<major.minor.patch>`

## Known Issues / Troubleshooting

### WS-Management - Exceeds the maximum envelope size allowed

The maximum envelope size for WinRM is not sufficient for installing large packages. To increase the envelope size use `winrm set winrm/config @{MaxEnvelopeSizekb=”153600″}` - this exampe will increase it to 150MB.
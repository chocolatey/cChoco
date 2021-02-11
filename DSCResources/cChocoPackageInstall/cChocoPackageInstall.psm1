# Copyright (c) 2017 Chocolatey Software, Inc.
# Copyright (c) 2013 - 2017 Lawrence Gripper & original authors/contributors from https://github.com/chocolatey/cChoco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Get-TargetResource
{
    [OutputType([hashtable])]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [ValidateNotNullOrEmpty()]
        [string]
        $Params,
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,
        [ValidateNotNull()]
        [string]
        $MinimumVersion,
        [string]
        $Source
    )

    Write-Verbose -Message 'Start Get-TargetResource'

    if (-Not (Test-ChocoInstalled)) {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name    = $Name
        Params  = $Params
        Version = $Version
        Source  = $Source
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present',
        [ValidateNotNullOrEmpty()]
        [string]
        $Params,
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,
        [ValidateNotNull()]
        [string]
        $MinimumVersion,
        [string]
        $Source,
        [String]
        $chocoParams,
        [bool]
        $AutoUpgrade = $false
    )
    Write-Verbose -Message 'Start Set-TargetResource'
    $isVersionPresent = $PSBoundParameters.ContainsKey('Version')
    $isMinimumVersionPresent = $PSBoundParameters.ContainsKey('MinimumVersion')
    if ($isVersionPresent -and $isMinimumVersionPresent ) {
        throw "Cannot specify 'Version' and 'MinimumVersion' in the same configuration"
    }

    if (-Not (Test-ChocoInstalled)) {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }

    $isInstalled = IsPackageInstalled -pName $Name

    #Determine the correct package version to use get to desired state
    if ($isVersionPresent -or $isMinimumVersionPresent) {
        if ($isVersionPresent) {
            $versionToInstall = $PSBoundParameters['Version']
        }
        else {
            $versionToInstall = $PSBoundParameters['MinimumVersion']
        }
    }

    #Uninstall if Ensure is set to absent and the package is installed
    if ($isInstalled) {
        if ($Ensure -eq 'Absent') {
            $whatIfShouldProcess = $pscmdlet.ShouldProcess("$Name", 'Remove Chocolatey package')
            if ($whatIfShouldProcess) {
                Write-Verbose -Message "Removing $Name as ensure is set to absent"
                UninstallPackage -pName $Name -pParams $Params
            }
        } else {
            $whatIfShouldProcess = $pscmdlet.ShouldProcess("$Name", 'Installing / upgrading package from Chocolatey')
            if ($whatIfShouldProcess) {
                if ($Version) {
                    Write-Verbose -Message "Uninstalling $Name due to version mis-match"
                    UninstallPackage -pName $Name -pParams $Params
                    Write-Verbose -Message "Re-Installing $Name with correct version $versionToInstall"
                    InstallPackage -pName $Name -pParams $Params -pVersion $versionToInstall -pSource $Source -cParams $chocoParams
                }
                elseif ($MinimumVersion) {
                    Write-Verbose -Message "Upgrading $Name because installed version is lower that the specified minimum"
                    $chocoParams += " --version='$versionToInstall'"
                    Upgrade-Package -pName $Name -pParams $Params -pSource $Source -cParams $chocoParams
                }
                elseif ($AutoUpgrade) {
                    Write-Verbose -Message "Upgrading $Name due to version mis-match"
                    Upgrade-Package -pName $Name -pParams $Params -pSource $Source -cParams $chocoParams
                }
            }
        }
    } else {
        $whatIfShouldProcess = $pscmdlet.ShouldProcess("$Name", 'Install package from Chocolatey')
        if ($whatIfShouldProcess) {
            InstallPackage -pName $Name -pParams $Params -pVersion $versionToInstall -pSource $Source -cParams $chocoParams
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present',
        [ValidateNotNullOrEmpty()]
        [string]
        $Params,
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,
        [ValidateNotNull()]
        [string]
        $MinimumVersion,
        [string]
        $Source,
        [ValidateNotNullOrEmpty()]
        [String]
        $chocoParams,
        [bool]
        $AutoUpgrade = $false
    )

    Write-Verbose -Message 'Start Test-TargetResource'
    $isVersionPresent = $PSBoundParameters.ContainsKey('Version')
    $isMinimumVersionPresent = $PSBoundParameters.ContainsKey('MinimumVersion')
    if ($isVersionPresent -and $isMinimumVersionPresent ) {
        throw "Cannot specify 'Version' and 'MinimumVersion' in the same configuration"
    }

    if (-Not (Test-ChocoInstalled)) {
        return $false
    }

    $isInstalled = IsPackageInstalled -pName $Name

    if ($ensure -eq 'Absent') {
         if ($isInstalled -eq $false) {
            return $true
         } else {
            return $false
         }
    }

    if ($version) {
        Write-Verbose -Message "Checking if $Name is installed and if version matches $version"
        $result = IsPackageInstalled -pName $Name -pVersion $Version
    }
    elseif ($MinimumVersion) {
        Write-Verbose -Message "Checking if $Name is installed and version is $MinimumVersion or higher"
        $result = IsPackageInstalled -pName $Name -pMinimumVersion $MinimumVersion
    }
    else {
        Write-Verbose -Message "Checking if $Name is installed"

        if ($AutoUpgrade -and $isInstalled) {
            $testParams = @{
                pName = $Name
            }
            if ($Source){
                $testParams.pSource = $Source
            }
            $result = Test-LatestVersionInstalled @testParams
        } else {
            $result = $isInstalled
        }
    }

    Return $result
}
function Test-ChocoInstalled
{
    Write-Verbose -Message 'Test-ChocoInstalled'
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    Write-Verbose -Message "Env:Path contains: $env:Path"
    if (Test-Command -command choco)
    {
        Write-Verbose -Message 'YES - Choco is Installed'
        return $true
    }

    Write-Verbose -Message 'NO - Choco is not Installed'
    return $false
}

Function Test-Command
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param (
        [string]$command = 'choco'
    )
    Write-Verbose -Message "Test-Command $command"
    if (Get-Command -Name $command -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "$command exists"
        return $true
    } else {
        Write-Verbose -Message "$command does NOT exist"
        return $false
    }
}

function InstallPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression','')]
    param(
        [Parameter(Position=0,Mandatory)]
        [string]$pName,
        [Parameter(Position=1)]
        [string]$pParams,
        [Parameter(Position=2)]
        [string]$pVersion,
        [Parameter(Position=3)]
        [string]$pSource,
        [Parameter(Position=4)]
        [string]$cParams
    )

    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    [string]$chocoParams = '-y'
    if ($pParams) {
        $chocoParams += " --params=`"$pParams`""
    }
    if ($pVersion) {
        $chocoParams += " --version=`"$pVersion`""
    }
    if ($pSource) {
        $chocoParams += " --source=`"$pSource`""
    }
    if ($cParams) {
        $chocoParams += " $cParams"
    }
    # Check if Chocolatey version is Greater than 0.10.4, and add --no-progress
    if ((Get-ChocoVersion) -ge [System.Version]('0.10.4')){
        $chocoParams += " --no-progress"
    }

    $cmd = "choco install $pName $chocoParams"
    Write-Verbose -Message "Install command: '$cmd'"
    $packageInstallOuput = Invoke-Expression -Command $cmd
    Write-Verbose -Message "Package output $packageInstallOuput"

    # Clear Package Cache
    Get-ChocoInstalledPackage -Purge

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')
}

function UninstallPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression','')]
    param(
        [Parameter(Position=0,Mandatory)]
        [string]$pName,
        [Parameter(Position=1)]
        [string]$pParams
    )

    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    [string]$chocoParams = "-y"
    if ($pParams) {
        $chocoParams += " --params=`"$pParams`""
    }
    if ($pVersion) {
        $chocoParams += " --version=`"$pVersion`""
    }
    # Check if Chocolatey version is Greater than 0.10.4, and add --no-progress
    if ((Get-ChocoVersion) -ge [System.Version]('0.10.4')){
        $chocoParams += " --no-progress"
    }

    $cmd = "choco uninstall $pName $chocoParams"
    Write-Verbose -Message "Uninstalling $pName with: '$cmd'"
    $packageUninstallOuput = Invoke-Expression -Command $cmd

    Write-Verbose -Message "Package uninstall output $packageUninstallOuput "

    # Clear Package Cache
    Get-ChocoInstalledPackage -Purge

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')
}

function IsPackageInstalled
{
    [CmdletBinding(DefaultParameterSetName = 'RequiredVersion')]
    [OutputType([Boolean])]
    param(
        [Parameter(Position=0, Mandatory)]
        [string]$pName,

        [Parameter(ParameterSetName = 'RequiredVersion')]
        [string]$pVersion,

        [Parameter(ParameterSetName = 'MinimumVersion')]
        [string]$pMinimumVersion
    )
    Write-Verbose -Message "Start IsPackageInstalled $pName"

    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')
    Write-Verbose -Message "Path variables: $($env:Path)"

    $installedPackages = Get-ChocoInstalledPackage

    if ($pVersion) {
        Write-Verbose 'Comparing required version'
        $installedPackages = $installedPackages | Where-Object { $_.Name -eq $pName -and $_.Version -eq $pVersion}
    }
    elseif ($pMinimumVersion) {
        Write-Verbose 'Comparing minimum version'
        # version comparison can be done with [System.Version] but this lacks the ability to compare pre-release versions
        # because of this limitation MinimumVersion cannot be used in conjuction with pre-release packages
        $pre = ($pMinimumVersion -split "-")[1]
        if ($pre) {
            throw "MinimumVersion does not support comparing pre-releases, please use Version parameter instead"
        }

        $comparablePackages = $installedPackages | Where-Object { $_.Name -eq $pName} | ForEach-Object {
            # as mentioned above we cant convert prerelease versions to [Sytem.Version] so we ignore anything after "-"
            # leaving just the . seperated numeric version. this is loosely equivalent to "rounding down"
            $parseableVersion = ($_.Version -split "-")[0]
            $v = [System.Version]($parseableVersion)
            $_ | Add-Member -MemberType NoteProperty -Name ComparableVersion -Value $v -PassThru
        }
        $installedPackages = $comparablePackages | Where-Object {$_.ComparableVersion -ge $pMinimumVersion}
    }
    else {
        Write-Verbose "Finding packages -eq $pName"
        $installedPackages = $installedPackages | Where-Object { $_.Name -eq $pName}
    }

    $count = @($installedPackages).Count
    Write-Verbose "Found $Count matching packages"
    if ($Count -gt 0)
    {
        $installedPackages | ForEach-Object {Write-Verbose -Message "Found: $($_.Name) with version $($_.Version)"}
        return $true
    }

    return $false
}

Function Test-LatestVersionInstalled {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression','')]
    param(
        [Parameter(Mandatory)]
        [string]$pName,
        [string]$pSource
    )
    Write-Verbose -Message "Testing if $pName can be upgraded"

    [string]$chocoParams = '--noop'
    if ($pSource) {
        $chocoParams += " --source=`"$pSource`""
    }

    $cmd = "choco upgrade $pName $chocoParams"
    Write-Verbose -Message "Testing if $pName can be upgraded: '$cmd'"

    $packageUpgradeOuput = Invoke-Expression -Command $cmd
    $packageUpgradeOuput | ForEach-Object {Write-Verbose -Message $_}

    if ($packageUpgradeOuput -match "$pName.*is the latest version available based on your source") {
        return $true
    }
    return $false
}

##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts.
function global:Write-Host
{
    Param(
        [Parameter(Mandatory, Position = 0)]
        [Object]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor

    )

    #Override default Write-Host...
    Write-Verbose -Message $Object
}

Function Upgrade-Package {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs','')]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression','')]
    param(
        [Parameter(Position=0,Mandatory)]
        [string]$pName,
        [Parameter(Position=1)]
        [string]$pParams,
        [Parameter(Position=2)]
        [string]$pSource,
        [Parameter(Position=3)]
        [string]$cParams
    )

    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')
    Write-Verbose -Message "Path variables: $($env:Path)"

    [string]$chocoParams = '-dv -y'
    if ($pParams) {
        $chocoParams += " --params=`"$pParams`""
    }
    if ($pSource) {
        $chocoParams += " --source=`"$pSource`""
    }
    if ($cParams) {
        $chocoParams += " $cParams"
    }
    # Check if Chocolatey version is Greater than 0.10.4, and add --no-progress
    if ((Get-ChocoVersion) -ge [System.Version]('0.10.4')){
        $chocoParams += " --no-progress"
    }

    $cmd = "choco upgrade $pName $chocoParams"
    Write-Verbose -Message "Upgrade command: '$cmd'"

    if (-not (IsPackageInstalled -pName $pName))
    {
        throw "$pName is not installed, you cannot upgrade"
    }

    $packageUpgradeOuput = Invoke-Expression -Command $cmd
    $packageUpgradeOuput | ForEach-Object { Write-Verbose -Message $_ }

    # Clear Package Cache
    Get-ChocoInstalledPackage -Purge
}

function Get-ChocoInstalledPackage {
    [CmdletBinding()]
    param (
        [switch]$Purge,
        [switch]$NoCache
    )

    $ChocoInstallLP = Join-Path -Path $env:ChocolateyInstall -ChildPath 'cache'
    if ( -not (Test-Path $ChocoInstallLP)){
        New-Item -Name 'cache' -Path $env:ChocolateyInstall -ItemType Directory | Out-Null
    }
    $ChocoInstallList = Join-Path -Path $ChocoInstallLP -ChildPath 'ChocoInstalled.xml'

    if ($Purge.IsPresent) {
        Remove-Item $ChocoInstallList -Force
        $res = $true
    } else {
        $PackageCacheSec = (Get-Date).AddSeconds('-60')
        if ( $PackageCacheSec -lt (Get-Item $ChocoInstallList -ErrorAction SilentlyContinue).LastWriteTime ) {
                $res = Import-Clixml $ChocoInstallList
        } else {
            $res = choco list -lo -r | ConvertFrom-Csv -Header 'Name', 'Version' -Delimiter "|"
            if ( -not $NoCache){
                $res | Export-Clixml -Path $ChocoInstallList
            }
        }
    }

    Return $res
}

function Get-ChocoVersion {
    [CmdletBinding()]
    param (
        [switch]$Purge,
        [switch]$NoCache
    )

    $chocoInstallCache = Join-Path -Path $env:ChocolateyInstall -ChildPath 'cache'
    if ( -not (Test-Path $chocoInstallCache)){
        New-Item -Name 'cache' -Path $env:ChocolateyInstall -ItemType Directory | Out-Null
    }
    $chocoVersion = Join-Path -Path $chocoInstallCache -ChildPath 'ChocoVersion.xml'

    if ($Purge.IsPresent) {
        Remove-Item $chocoVersion -Force
        $res = $true
    } else {
        $cacheSec = (Get-Date).AddSeconds('-60')
        if ( $cacheSec -lt (Get-Item $chocoVersion -ErrorAction SilentlyContinue).LastWriteTime ) {
            $res = Import-Clixml $chocoVersion
        } else {
            $cmd = choco -v
            $res = [System.Version]($cmd.Split('-')[0])
            $res | Export-Clixml -Path $chocoVersion
        }
    }
    Return $res
}

Export-ModuleMember -Function *-TargetResource

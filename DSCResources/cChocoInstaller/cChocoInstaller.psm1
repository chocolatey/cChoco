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
        $InstallDir,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [parameter(Mandatory = $false)]
        [UInt32]
        $RandomTimeOutBeforeInstallSec = 1,

        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $Source = 'https://chocolatey.org/api/v2'
    )
    Write-Verbose 'Start Get-TargetResource'

    #Needs to return a hashtable that returns the current status of the configuration component
    $Configuration = @{
        InstallDir            = $env:ChocolateyInstall
        Version               = $Version
        Source                = $Source
    }

    Return $Configuration
}

function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [parameter(Mandatory = $false)]
        [UInt32]
        $RandomTimeOutBeforeInstallSec = 1,

        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials = $(New-Object System.Management.Automation.PSCredential ("anonymouse", $(ConvertTo-SecureString " " -AsPlainText -Force))),

        [parameter(Mandatory = $false)]
        [System.String]
        $Source = 'https://chocolatey.org/api/v2'
    )
    Write-Verbose 'Start Set-TargetResource'

    $uri = Get-ChocoPackageUrl -Version $Version -Source $Source -Credentials $Credentials
    $whatIfShouldProcess = $pscmdlet.ShouldProcess('Chocolatey', 'Download and Install')
    if ($whatIfShouldProcess) {
        Install-Chocolatey -InstallDir $InstallDir -URI $uri -Credentials $Credentials -TimeOut $RandomTimeOutBeforeInstallSec
    }
}

function Test-TargetResource
{
    [OutputType([bool])]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [parameter(Mandatory = $false)]
        [UInt32]
        $RandomTimeOutBeforeInstallSec = 1,

        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $Source = 'https://chocolatey.org/api/v2'
    )

    Write-Verbose 'Test-TargetResource'
    if (-not (Test-ChocoInstalled))
    {
        Write-Verbose 'Choco is not installed, calling set'
        Return $false
    }

    ##Test to see if the Install Directory is correct.
    $env:ChocolateyInstall = [Environment]::GetEnvironmentVariable('ChocolateyInstall','Machine')
    if(-not ($InstallDir -eq $env:ChocolateyInstall))
    {
        Write-Verbose "Choco should be installed in $InstallDir but is installed to $env:ChocolateyInstall calling set"
        Return $false
    }

    Return $true
}

# Custom functions
function Join-Uri
{
    Param (
        [string[]] $Parts,
        [string] $Seperator = '/'
    )
    $search = '(?<!:)' + [regex]::Escape($Seperator) + '+'  #Replace multiples except in front of a colon for URLs.
    $replace = $Seperator
    Return $($($Parts | Where-Object {$_ -and $_.Trim().Length}) -join $Seperator -replace $search, $replace)
}

function Get-ChocoPackageUrl
{
    Param (
        [string] $Version,
        [PSCredential] $Credentials,

        [parameter(Mandatory = $true)]
        [System.String] $Source
    )

    Write-Verbose 'Get-ChocoLatestVersionUrl'
    [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192 -bor 48
    if ($Version) {
        $query = "Packages(Id='chocolatey',Version='$Version')"
        $url = Join-Uri -Parts @($Source, $query) -Seperator '/'
        Write-Verbose "Invoke-WebRequest $url"
        if ($Credentials) {$res = Invoke-WebRequest -URI $url -Credential $Credentials -UseBasicParsing} else {$res = Invoke-WebRequest -URI $url -UseBasicParsing}
        Write-Verbose "URL $($([xml]$res).feed.entry.content.src)"
        return $([xml]$res.Content).entry.content.src
    } else {
        $query = 'Packages()?$filter=((Id%20eq%20%27chocolatey%27)%20and%20(not%20IsPrerelease))%20and%20IsLatestVersion'
        $url = Join-Uri -Parts @($Source, $query) -Seperator '/'
        Write-Verbose "Invoke-WebRequest $url"
        if ($Credentials) {$res = Invoke-WebRequest -URI $url -Credential $Credentials -UseBasicParsing} else {$res = Invoke-WebRequest -URI $url -UseBasicParsing}
        Write-Verbose "URL $($([xml]$res).feed.entry.content.src)"
        return $([xml]$res.Content).feed.entry.content.src
    }
}

function Test-ChocoInstalled
{
    Write-Verbose 'Test-ChocoInstalled'
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    Write-Verbose "Env:Path contains: $env:Path"
    if (Test-Command -command choco)
    {
        Write-Verbose 'YES - Choco is Installed'
        return $true
    }

    Write-Verbose "NO - Choco is not Installed"
    return $false
}

Function Test-Command
{
    Param (
        [string]$command = 'choco'
    )
    Write-Verbose "Test-Command $command"
    if (Get-Command -Name $command -ErrorAction SilentlyContinue) {
        Write-Verbose "$command exists"
        return $true
    } else {
        Write-Verbose "$command does NOT exist"
        return $false
    }
}

#region - chocolately installer work arounds. Main issue is use of write-host
function global:Write-Host
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalFunctions")]
    Param(
        [Parameter(Mandatory,Position = 0)]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor
    )
    #Redirecting Write-Host -> Write-Verbose.
    Write-Verbose $Object
}
#endregion

Function Install-Chocolatey {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $URI,

        [parameter(Mandatory = $true)]
        [PSCredential]
        $Credentials,

        [parameter(Mandatory = $false)]
        [UInt32]
        $TimeOut = 1
    )
    Write-Verbose 'Install-Chocolatey'

    #Create install directory if it does not exist
    If(-not (Test-Path -Path $InstallDir)) {
        Write-Verbose "[ChocoInstaller] Creating $InstallDir"
        New-Item -Path $InstallDir -ItemType Directory
    }

    #Set permanent EnvironmentVariable
    Write-Verbose 'Setting ChocolateyInstall environment variables'
    [Environment]::SetEnvironmentVariable('ChocolateyInstall', $InstallDir, [EnvironmentVariableTarget]::Machine)
    $env:ChocolateyInstall = [Environment]::GetEnvironmentVariable('ChocolateyInstall','Machine')
    Write-Verbose "Env:ChocolateyInstall has $env:ChocolateyInstall"

    #Download and install package
    Write-Verbose 'Create Temp Directory'
    if ($null -eq $env:TEMP) {$env:TEMP = Join-Path $env:SystemDrive 'temp'}
    $chocTempDir = Join-Path $env:TEMP "chocolatey"
    $tempDir = Join-Path $chocTempDir "chocInstall"
    if (-not $(Test-Path -LiteralPath $tempDir -PathType Container)) {New-Item -ItemType "directory" -Path $tempDir}
    $file = Join-Path $tempDir "chocolatey.zip"

    [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192 -bor 48

    $sleep = $(Get-Random -Maximum $TimeOut -Minimum 0)
    Write-Verbose "Pause before download: $sleep sec"
    Start-Sleep -Seconds $sleep
    Write-Verbose 'Download choco package'
    Invoke-WebRequest -URI $URI -Credential $Credentials -OutFile $file -UseBasicParsing

    Write-Verbose 'Unzip package'
    Expand-Archive -Path "$file" -DestinationPath "$tempDir" -Force

    Write-Output "Installing chocolatey on this machine"
    $toolsFolder = Join-Path $tempDir "tools"
    $chocInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"

    & $chocInstallPS1

    Write-Output 'Ensuring chocolatey commands are on the path'
    $chocoPath = $env:ChocolateyInstall
    if ($null -eq $chocoPath -or $chocoPath -eq '') {
      $chocoPath = "$env:ALLUSERSPROFILE\Chocolatey"
    }

    if (!(Test-Path ($chocoPath))) {
      $chocoPath = "$env:SYSTEMDRIVE\ProgramData\Chocolatey"
    }

    $chocoExePath = Join-Path $chocoPath 'bin'

    if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
      $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
    }

    Write-Output 'Ensuring chocolatey.nupkg is in the lib folder'
    $chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
    $nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
    if (-not $(Test-Path -LiteralPath $chocoPkgDir -PathType Container)) {New-Item -ItemType "directory" -Path $chocoPkgDir}
    Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue

    #refresh after install
    Write-Verbose 'Adding Choco to path'
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')
    if ($env:path -notlike "*$InstallDir*") {
        $env:Path += ";$InstallDir"
    }

    Write-Verbose "Env:Path has $env:path"
    #InstallChoco $InstallDir
    $Null = Choco
    Write-Verbose 'Finish InstallChoco'
}

Export-ModuleMember -Function *-TargetResource

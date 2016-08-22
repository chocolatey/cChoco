function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ChocoInstallScriptUrl = "https://chocolatey.org/install.ps1",
        [parameter(Mandatory = $false)]
        [System.String]
        $ChocoDownloadUrl

    )
    Write-Verbose " Start Get-TargetResource"


    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        InstallDir = $env:ChocolateyInstall
        ChocoInstallScriptUrl = $ChocoInstallScriptUrl
        ChocoDownloadUrl = $ChocoDownloadUrl
    }

    if (-not (IsChocoInstalled))
    {
        #$Configuration.Ensure = "Absent"
        Return $Configuration
    }
    else
    {
        #$Configuration.Ensure = "Present"
        Return $Configuration

    }
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ChocoInstallScriptUrl = "https://chocolatey.org/install.ps1",
        [parameter(Mandatory = $false)]
        [System.String]
        $ChocoDownloadUrl
    )
    Write-Verbose " Start Set-TargetResource"
    
    if (-not (DoesCommandExist choco) -or -not (IsChocoInstalled))
    {
        #$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')

        Write-Verbose '[ChocoInstaller] Start InstallChoco'
        If(-not (Test-Path -Path $InstallDir)) {
            New-Item -Path $InstallDir -ItemType Directory
        }
        $file = Join-Path $InstallDir "install.ps1"
        [Environment]::SetEnvironmentVariable("ChocolateyInstall", $InstallDir, [EnvironmentVariableTarget]::Machine)
        if ($ChocoDownloadUrl) {
            [Environment]::SetEnvironmentVariable("ChocolateyDownloadUrl", $ChocoDownloadUrl, [System.EnvironmentVariableTarget]::Machine)
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")        
        
        $env:ChocolateyInstall = $InstallDir
        Download-File $ChocoInstallScriptUrl $file
        . $file
        
        #InstallChoco $InstallDir
        Write-Verbose '[ChocoInstaller] Finish InstallChoco'

        #refresh path varaible in powershell, as choco doesn"t, to pull in git
    }
	elseif((-not ($InstallDir -eq $env:ChocolateyInstall)) -and (Test-Path "$($InstallDir)\choco.exe"))
	{
		[Environment]::SetEnvironmentVariable("ChocolateyInstall", $InstallDir, [EnvironmentVariableTarget]::Machine)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")        
        $env:ChocolateyInstall = $InstallDir
	}
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ChocoInstallScriptUrl = "https://chocolatey.org/install.ps1",
        [parameter(Mandatory = $false)]
        [System.String]
        $ChocoDownloadUrl
    )

    Write-Verbose " Start Test-TargetResource"

    if (-not (IsChocoInstalled))
    {
        Return $false
    }
    ##Test to see if the Install Directory is right.
    if(-not ($InstallDir -eq $env:ChocolateyInstall)) 
    {
        Return $false
    }

    Return $true
}

function IsChocoInstalled
{

    Write-Verbose " Is choco installed? "

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

    if (DoesCommandExist choco)
    {
        Write-Verbose " YES - Choco is Installed"

        return $true
    }

    Write-Verbose " NO - Choco isn't Installed"

    return $false

    
}

function DoesCommandExist
{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try 
    {
        if(Get-Command $command)
        {
            return $true
        }
    }
    Catch 
    {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
} 


##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
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
    Write-Verbose $Object
}

function Download-File {
param (
  [string]$url,
  [string]$file
 )
  Write-Output "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient

  $defaultCreds = [System.Net.CredentialCache]::DefaultCredentials

  $downloader.DownloadFile($url, $file)
}

Export-ModuleMember -Function *-TargetResource

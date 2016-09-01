function Get-TargetResource
{
    [OutputType([hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ChocoInstallScriptUrl = 'https://chocolatey.org/install.ps1'

    )
    Write-Verbose ' Start Get-TargetResource'


    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        InstallDir = $env:ChocolateyInstall
        ChocoInstallScriptUrl = $ChocoInstallScriptUrl
    }

    if (-not (Test-ChocoInstalled))
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
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ChocoInstallScriptUrl = 'https://chocolatey.org/install.ps1'
    )
    Write-Verbose ' Start Set-TargetResource'
    
    if (-not (Test-Command -command choco) -or -not (Test-ChocoInstalled))
    {
        #$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')

        Write-Verbose '[ChocoInstaller] Start InstallChoco'
        If(-not (Test-Path -Path $InstallDir)) {
            New-Item -Path $InstallDir -ItemType Directory
        }
        $file = Join-Path $InstallDir 'install.ps1'
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $InstallDir, [EnvironmentVariableTarget]::Machine)
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')        
        
        $env:ChocolateyInstall = $InstallDir
        Get-FileDownload $ChocoInstallScriptUrl $file
        . $file
        
        #InstallChoco $InstallDir
        Write-Verbose '[ChocoInstaller] Finish InstallChoco'

        #refresh path varaible in powershell, as choco doesn"t, to pull in git
    }
	elseif((-not ($InstallDir -eq $env:ChocolateyInstall)) -and (Test-Path "$($InstallDir)\choco.exe"))
	{
		[Environment]::SetEnvironmentVariable('ChocolateyInstall', $InstallDir, [EnvironmentVariableTarget]::Machine)
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')        
        $env:ChocolateyInstall = $InstallDir
	}
}

function Test-TargetResource
{
    [OutputType([bool])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ChocoInstallScriptUrl = 'https://chocolatey.org/install.ps1'
    )

    Write-Verbose ' Start Test-TargetResource'

    if (-not (Test-ChocoInstalled))
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

function Test-ChocoInstalled
{

    Write-Verbose ' Is choco installed? '
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine')

    if (Test-Command choco)
    {
        Write-Verbose ' YES - Choco is Installed'
        return $true
    }

    Write-Verbose " NO - Choco isn't Installed"
    return $false
}

Function Test-Command
{
  Param (
    [string]$command
  )
  if (Get-Command -Name $command -ErrorAction SilentlyContinue) {
    return $true
  } else {
    return $false
  } 
} 


##region - chocolately installer work arounds. Main issue is use of write-host
##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Object,
        [Switch]$NoNewLine,
        [ConsoleColor]$ForegroundColor,
        [ConsoleColor]$BackgroundColor
    )
    #Override default Write-Host...
    Write-Verbose $Object
}

function Get-FileDownload {
  param (
    [string]$url,
    [string]$file
  )
  Write-Output "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $file)
}

Export-ModuleMember -Function *-TargetResource

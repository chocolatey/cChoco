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
        [System.String]
        $ChocoInstallScriptUrl = "https://chocolatey.org/install.ps1",
        [parameter(Mandatory = $false)]
        [System.String]
        $ChocoDownloadUrl


    )
    Write-Verbose 'Start Get-TargetResource'

    #Needs to return a hashtable that returns the current status of the configuration component
    $Configuration = @{
        InstallDir            = $env:ChocolateyInstall
        ChocoInstallScriptUrl = $ChocoInstallScriptUrl
        ChocoDownloadUrl = $ChocoDownloadUrl
    }

    Return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
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


        [parameter()]
        [string]
        $ChocoInstallScriptUrl = 'https://chocolatey.org/install.ps1'
    )
    Write-Verbose 'Start Set-TargetResource'
    $whatIfShouldProcess = $pscmdlet.ShouldProcess('Chocolatey', 'Download and Install')
    if ($whatIfShouldProcess) {
        Install-Chocolatey @PSBoundParameters
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
        [System.String]
        $ChocoInstallScriptUrl = "https://chocolatey.org/install.ps1",
        [parameter(Mandatory = $false)]
        [System.String]
        $ChocoDownloadUrl

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

function Get-FileDownload {
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$url,
        
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$file
    )
    # Set security protocol preference to avoid the download error if the machine has disabled TLS 1.0 and SSLv3
    # See: https://chocolatey.org/install (Installing With Restricted TLS section)
    # Since cChoco requires at least PowerShell 4.0, we have .NET 4.5 available, so we can use [System.Net.SecurityProtocolType] enum values by name.
    $securityProtocolSettingsOriginal = [System.Net.ServicePointManager]::SecurityProtocol
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Ssl3

    Write-Verbose "Downloading $url to $file"
    $downloader = new-object -TypeName System.Net.WebClient
    $downloader.DownloadFile($url, $file)

    [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocolSettingsOriginal
}

Function Install-Chocolatey {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir,

        [parameter()]
        [string]
        $ChocoInstallScriptUrl = 'https://chocolatey.org/install.ps1'
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
    
    #Download an execute install script    
    $file = Join-Path -Path $InstallDir -ChildPath 'install.ps1'
    Get-FileDownload -url $ChocoInstallScriptUrl -file $file
    . $file

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

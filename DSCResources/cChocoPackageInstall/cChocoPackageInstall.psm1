function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version

    )

    Write-Verbose "Start Get-TargetResource"

    CheckChocoInstalled

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
        Params = $Params
        Version = $Version
    }

    return $Configuration
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,   
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version     

    )
    Write-Verbose "Start Set-TargetResource"

    CheckChocoInstalled

    if (-not (IsPackageInstalled $Name))
    {
        InstallPackage -pName $Name -pParams $Params -pVersion $Version
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
        $Name,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version
    )

    Write-Verbose "Start Test-TargetResource"

    CheckChocoInstalled

    if (-not (IsPackageInstalled $Name))
    {
        Return $false
    }

    Return $true
}


function CheckChocoInstalled
{
    if (-not (DoesCommandExist choco))
    {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }
}

function InstallPackage
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName,
            [Parameter(Position=1,Mandatory=0)][string]$pParams,
            [Parameter(Position=2,Mandatory=0)][string]$pVersion
    ) 

    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    
    #Todo: Refactor
    if ((-not ($pParams)) -and (-not $pVersion))
    {
        $packageInstallOuput = choco install $pName -y
    }
    elseif ($pParams -and $pVersion)
    {
        $packageInstallOuput = choco install $pName --params="$pParams" --version=$pVersion -y        
    }
    elseif ($pParams)
    {
        $packageInstallOuput = choco install $pName --params="$pParams" -y            
    }
    elseif ($pVersion)
    {
        $packageInstallOuput = choco install $pName --version=$pVersion -y        
    }
    
    Write-Verbose "package output $packageInstallOuput "

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}


function IsPackageInstalled
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName
        ) 
    Write-Verbose "Start IsPackageInstalled $pName"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")


    $installedPackages = choco list -lo | Where-object { $_.Contains($pName) }

    if ($installedPackages.Count -gt 0)
    {
        return $true
    }

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

Export-ModuleMember -Function *-TargetResource
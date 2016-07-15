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
        $Version,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    Write-Verbose "Start Get-TargetResource"

    if (-Not (CheckChocoInstalled)) {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
        Params = $Params
        Version = $Version
		Source = $Source
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present',
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,   
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source

    )
    Write-Verbose "Start Set-TargetResource"
	
    if (-Not (CheckChocoInstalled)) {
        throw "cChocoPackageInstall requires Chocolatey to be installed, consider using cChocoInstaller with 'dependson' in dsc config"
    }

    $isInstalled = IsPackageInstalled $Name
    $isInstalledVersion = IsPackageInstalled -pName $Name -pVersion $Version

    if ($Ensure -ieq 'Present') {
	    if ($Source)
	    {
		    $SourceCmdOutput = choco source remove -n="$Name"
		    $SourceCmdOutput += choco source add -n="$Name" -s="$Source"
		    Write-Verbose "Source command output: $SourceCmdOutput"
	    }

	    if	( `
			    (-not $Version) -and -not ($isInstalled) `
			    -or `
			    ($Version) -and -not ($isInstalledVersion) `
	    )
        {
            InstallPackage -pName $Name -pParams $Params -pVersion $Version
        }
    }
    elseif ($isInstalled) {
        UninstallPackage -pName $Name -pParams $Params
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present',
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Params,    
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,
		[parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    Write-Verbose "Start Test-TargetResource"

    if (-Not (CheckChocoInstalled)) {
        retuirn $false
    }

    $isInstalled = IsPackageInstalled $Name
    $isInstalledVersion = IsPackageInstalled -pName $Name -pVersion $Version

    if ($Ensure -ieq 'Present') {
	    if	( `
			    (-not $Version) -and -not ($isInstalled) `
			    -or `
			    ($Version) -and -not ($isInstalledVersion) `
	    )
        {
            Return $false
        }
    }
    elseif ($isInstalled) {
        Return $false
    }

    Return $true
}


function CheckChocoInstalled
{
    return DoesCommandExist choco
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
        Write-Verbose "Installing Package Standard"
        $packageInstallOuput = choco install $pName -y
    }
    elseif ($pParams -and $pVersion)
    {
        Write-Verbose "Installing Package with Params $pParams and Version $pVersion"
        $packageInstallOuput = choco install $pName --params="$pParams" --version=$pVersion -y        
    }
    elseif ($pParams)
    {
        Write-Verbose "Installing Package with params $pParams"
        $packageInstallOuput = choco install $pName --params="$pParams" -y            
    }
    elseif ($pVersion)
    {
        Write-Verbose "Installing Package with version $pVersion"
        $packageInstallOuput = choco install $pName --version=$pVersion -y        
    }
    
    
    Write-Verbose "Package output $packageInstallOuput "

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function UninstallPackage 
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName,
            [Parameter(Position=1,Mandatory=0)][string]$pParams
    )

    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    
    #Todo: Refactor
    if (-not ($pParams))
    {
        Write-Verbose "Uninstalling Package Standard"
        $packageUninstallOuput = choco uninstall $pName -y
    }
    elseif ($pParams)
    {
        Write-Verbose "Uninstalling Package with params $pParams"
        $packageUninstallOuput = choco uninstall $pName --params="$pParams" -y            
    }
    
    
    Write-Verbose "Package uninstall output $packageUninstallOuput "

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}


function IsPackageInstalled
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName,
            [Parameter(Position=1,Mandatory=0)][string]$pVersion
        ) 
    Write-Verbose "Start IsPackageInstalled $pName"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

	if ($pVersion) {
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) -and $_.ToLower().Contains($pVersion.ToLower()) }
	} else {
		$installedPackages = choco list -lo | Where-object { $_.ToLower().Contains($pName.ToLower()) }
	}
	
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
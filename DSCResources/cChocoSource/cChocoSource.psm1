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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present',
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    Write-Verbose "Start Get-TargetResource"

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
        Priority = $Priority
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
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )
    Write-Verbose "Start Set-TargetResource"

	if($Ensure -eq "Present")
	{
		if($priority -eq $null)
		{
			choco sources add -n"$name" -s"$source"
		}
		else
		{
			choco sources add -n"$name" -s"$source" --priority=$priority
		}
	}
	else
	{
		choco sources remove -n"$name"
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
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    Write-Verbose "Start Test-TargetResource"
	$exe = (get-command choco).Source
	$chocofolder = $exe.Substring(0,$exe.LastIndexOf("\"))

	if( $chocofolder.EndsWith("bin") )
	{
		$chocofolder = $chocofolder.Substring(0,$chocofolder.LastIndexOf("\"))
	}

	$configfolder = "$chocofolder\config"
	$configfile = Get-ChildItem $configfolder | Where-Object {$_.Name -match "chocolatey.config"}

	$xml = [xml](Get-Content $configfile.FullName)
	$sources = $xml.chocolatey.sources.source

	foreach($chocosource in $sources)
	{
		if($chocosource.id -eq $name -and $ensure -eq 'Present')
		{		
			return $true
		}
		elseif($chocosource.id -eq $name -and $ensure -eq 'Absent')
		{
			return $false
		}
	}
	
	if($Ensure -eq 'Present')
	{
		return $false
	}
	else
	{
		return $true
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
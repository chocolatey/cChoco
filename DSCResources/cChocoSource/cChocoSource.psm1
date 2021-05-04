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
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials,
        [parameter(Mandatory = $false)]
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
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials,
        [parameter(Mandatory = $false)]
        [System.String]
        $Source
    )
    Write-Verbose "Start Set-TargetResource"

    # Remove source if we'removing or updating it.
    # If the source does not exists, this is a noop.
    choco sources remove -n"$name"

    if($Ensure -eq "Present")
    {
        $args = @("sources", "add", "-n`"$name`"", "-s`"$source`"")

        if($null -ne $priority)
        {
            $args += "--priority=$priority"
        }

        if($null -ne $Credentials)
        {
            $username = $Credentials.UserName
            $password = $Credentials.GetNetworkCredential().Password

            $args += @("-u=`"$username`"", "-p=`"$password`"")
        }

        & choco $args
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
        [UInt32]
        $Priority,
        [parameter(Mandatory = $false)]
        [PSCredential]
        $Credentials,
        [parameter(Mandatory = $false)]
        [System.String]
        $Source
    )

    Write-Verbose "Start Test-TargetResource"

    if($env:ChocolateyInstall -eq "" -or $null -eq $env:ChocolateyInstall)
    {
        $exe = (get-command choco).Source
        $chocofolder = $exe.Substring(0,$exe.LastIndexOf("\"))

        if( $chocofolder.EndsWith("bin") )
        {
            $chocofolder = $chocofolder.Substring(0,$chocofolder.LastIndexOf("\"))
        }
    }
    else
    {
        $chocofolder = $env:ChocolateyInstall
    }
    $configfolder = "$chocofolder\config"
    $configfile = Get-ChildItem $configfolder | Where-Object {$_.Name -match "chocolatey.config$"}

    $xml = [xml](Get-Content $configfile.FullName)
    $sources = $xml.chocolatey.sources.source

    foreach($chocosource in $sources)
    {
        if($chocosource.id -eq $name -and $ensure -eq 'Present')
        {
            $configMatches = $true
            if ($chocosource.value -ne $Source)
            {
                $configMatches = $false
            }

            if ($chocosource.priority -ne $Priority)
            {
                $configMatches = $false
            }

            return $configMatches
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


Export-ModuleMember -Function *-TargetResource

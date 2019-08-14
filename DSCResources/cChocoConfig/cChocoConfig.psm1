# Copyright (c) 2017 Chocolatey Software, Inc.
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

<#
    .SYNOPSIS
    DSC Resource to set/unset chocolatey config settings

    .NOTES
    This resource supports querying the XML file directly. This is faster but not recommended as it does not respect the chocolatey api.
    Use this feature if you will not be upgrading chocolatey as updates may change the xml format and break this resource!
#>
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [System.String]$Key,

        [Parameter()]
        [System.String]$Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]$Ensure = 'Present',

        [Parameter()]
        [System.Boolean]$QueryXML
    )

    $return = @{
        'Key' = $Key
        'Value' = $Value
        'Ensure' = $Ensure
        'QueryXML' = $QueryXML
    }

    if ($Ensure -eq 'Absent') {
        # if value and absent specified remove value as it can be confusing output
        $return['Value'] = $null
    }

    return $return
}

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.String]$Key,

        [Parameter()]
        [System.String]$Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]$Ensure = 'Present',

        [Parameter()]
        [System.Boolean]$QueryXML
    )

    # validate value is given when ensure present
    if ($Ensure -eq 'Present' -and -not $PSBoundParameters.ContainsKey('Value')) {
        throw "Missing parameter 'Value' when ensuring config is present!"
    }

    # query config to determine current setting
    $ChocoConfig = @{
        'Key' = $Key
        'QueryXML' = $QueryXML
    }
    $CurrentValue = Get-ChocoConfig @ChocoConfig

    # make it so
    if ($Ensure -eq 'Absent' -and -not [String]::IsNullOrEmpty($CurrentValue)) {
        Write-Verbose "Unsetting $Key..."
        & choco config unset $Key
    }
    else {
        Write-Verbose "Setting $Key to '$Value'..."
        & choco config set --name $Key --value $Value
    }

}

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [System.String]$Key,

        [Parameter()]
        [System.String]$Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]$Ensure = 'Present',

        [Parameter()]
        [System.Boolean]$QueryXML
    )

    # validate value is given when ensure present
    if ($Ensure -eq 'Present' -and -not $PSBoundParameters.ContainsKey('Value')) {
        throw "Missing parameter 'Value' when ensuring config is present!"
    }

    # query config to determine current setting
    $ChocoConfig = @{
        'Key' = $Key
        'QueryXML' = $QueryXML
    }
    $CurrentValue = Get-ChocoConfig @ChocoConfig

    # determine if in desired state
    if ($Ensure -eq 'Absent') {
        if ([String]::IsNullOrEmpty($CurrentValue)) {
            Write-Verbose "$Key is in desired state"
            return $true
        }
        else {
            Write-Verbose "$key not in desired state: value should be unset but was '$CurrentValue'"
            return $false
        }
    }
    else {
        if ($Value -eq $CurrentValue) {
            Write-Verbose "$Key is in desired state"
            return $true
        }
        else {
            Write-Verbose "$key not in desired state: value should be '$Value' but was '$CurrentValue'"
            return $false
        }
    }
}

function Get-ChocoConfig {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory)]
        [System.String]$Key,

        [Parameter()]
        [Switch]$QueryXML
    )

    if ($QueryXML.IsPresent) {
        Write-Verbose "Querying chco config via chocolatey.config xml..."
        $ConfigXmlPath = Join-Path $env:ChocolateyInstall -ChildPath "config\chocolatey.config"
        try {
            $ConfigXml = [xml](Get-Content -Path $ConfigXmlPath)
            # xpath is case sensitive so we must convert all to lower case
            $XPath = "/chocolatey/config/add[translate(@key, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')  = '$($Key.ToLower())']"
            $ConfigValue = $ConfigXml.SelectSingleNode($XPath).value
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    else {
        Write-Verbose "Querying choco config via CLI"
        $ConfigValue = & choco config get $Key -r 
    }

    return $ConfigValue
}

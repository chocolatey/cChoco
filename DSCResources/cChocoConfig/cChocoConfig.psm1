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
.Description
Returns the configuration for cChocoConfig.

.Example
Get-TargetResource -ConfigName cacheLocation -Ensure 'Present' -Value 'c:\temp\choco'
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $ConfigName,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present',

        [parameter(Mandatory = $false)]
        [string]
        $Value
    )

    Write-Verbose "Starting cChocoConfig Get-TargetResource - Config Name: $ConfigName, Ensure: $Ensure"

    $returnValue = @{
        ConfigName = $ConfigName
        Ensure = $Ensure
        Value = $Value
    }

    $returnValue

}

<#
.Description
Performs the set for the cChocoConfig resource.

.Example
Set-TargetResource -ConfigName cacheLocation -Ensure 'Present' -Value 'c:\temp\choco'

#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $ConfigName,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present',

        [parameter(Mandatory = $false)]
        [string]
        $Value
    )


    Write-Verbose "Starting cChocoConfig Set-TargetResource - Config Name: $ConfigName, Ensure: $Ensure"

    if ($pscmdlet.ShouldProcess("Choco config $ConfigName will be ensured $Ensure."))
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose "Setting choco config $ConfigName."
            choco config set --name "'$ConfigName'" --value "'$Value'"
        }
        else 
        {
            Write-Verbose "Unsetting choco config $ConfigName."
            choco config unset --name "'$ConfigName'"
        }
    }

}

<#
.Description
Performs the test for cChocoFeature.

.Example
Test-TargetResource -ConfigName cacheLocation -Ensure 'Present' -Value 'c:\temp\choco'
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $ConfigName,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present',

        [parameter(Mandatory = $false)]
        [string]
        $Value
    )

    Write-Verbose "Starting cChocoConfig Test-TargetResource - Config Name: $ConfigName, Ensure: $Ensure."

    # validate value is given when ensure present
    if ($Ensure -eq 'Present' -and (-not $PSBoundParameters.ContainsKey('Value') -or [String]::IsNullOrEmpty($Value))) {
        throw "Missing parameter 'Value' when ensuring config is present!"
    }

    if($env:ChocolateyInstall -eq "" -or $null -eq $env:ChocolateyInstall)
    {
        $command = Get-Command -Name choco.exe -ErrorAction SilentlyContinue

        if(!$command) {
            throw "Unable to find choco.exe. Please make sure Chocolatey is installed correctly."
        }

        $chocofolder = Split-Path $command.Source

        if( $chocofolder.EndsWith("bin") )
        {
            $chocofolder = Split-Path $chocofolder
        }
    }
    else
    {
        $chocofolder = $env:ChocolateyInstall
    }

    if(!(Get-Item -Path $chocofolder -ErrorAction SilentlyContinue)) {
        throw "Unable to find Chocolatey installation folder. Please make sure Chocolatey is installed and configured properly."
    }
    
    $configfolder = Join-Path -Path $chocofolder -ChildPath "config"
    $configfile = Get-ChildItem -Path $configfolder | Where-Object {$_.Name -match "chocolatey.config$"}

    if(!(Get-Item -Path $configfile.FullName -ErrorAction SilentlyContinue)) {
        throw "Unable to find Chocolatey config file. Please make sure Chocolatey is installed and configured properly."
    }

    # There is currently no choco command that only returns the settings in an CSV format.
    # choco config list -r shows settings, sources, features and a note about API keys.
    $xml = [xml](Get-Content -Path $configfile.FullName)
    $settings = $xml.chocolatey.config.add
    foreach($setting in $settings)
    {
        # If the config name matches and it should be present, check the value and 
        # if it matches it returns true.
        if($setting.key -eq $ConfigName -and $Ensure -eq 'Present')
        {
            return ($setting.value -eq $Value)
        }
        # If the config name matches and it should be absent, check the value and
        # if it is null or empty, return true
        elseif($setting.key -eq $ConfigName -and $Ensure -eq 'Absent')
        {
            return ([String]::IsNullOrEmpty($setting.value))
        }
    }

    # If we get this far, the configuraion item hasn't been found.
    # There is currently no value, so return false if it should be present.
    # True otherwise.
    return !($Ensure -eq 'Present')
}

Export-ModuleMember -Function *-TargetResource

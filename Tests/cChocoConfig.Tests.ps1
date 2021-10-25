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


$ResourceName = ((Split-Path $MyInvocation.MyCommand.Path -Leaf) -split '_')[0]
$ResourceFile = (Get-DscResource -Name $ResourceName).Path

$TestsPath    = (split-path -path $MyInvocation.MyCommand.Path -Parent)
$ResourceFile = Get-ChildItem -Recurse $TestsPath\.. -File | Where-Object {$_.name -eq "$ResourceName.psm1"}

Import-Module -Name $ResourceFile.FullName


#---------------------------------#
# Pester tests for cChocoConfig   #
#---------------------------------#
Describe "Testing cChocoConfig" {

    Context "Test-TargetResource" {

        mock -ModuleName cChocoConfig -CommandName Get-Content -MockWith {'<?xml version="1.0" encoding="utf-8"?>
<chocolatey xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <config>
    <add key="commandExecutionTimeoutSeconds" value="1339" description="Default timeout for command execution. for infinite (starting in 0.10.4)." />
    <add key="proxy" value="" description="Explicit proxy location. Available in 0.9.9.9+." />
  </config>
  <sources>
    <source id="chocolatey" value="https://chocolatey.org/api/v2/" disabled="false" bypassProxy="false" selfService="false" adminOnly="false" priority="0" />
  </sources>
</chocolatey>'
        } -Verifiable

        it 'Test-TargetResource returns true when Present and Configured.' {
            Test-TargetResource -ConfigName 'commandExecutionTimeoutSeconds' -Ensure 'Present' -Value '1339' | Should be $true
        }

        it 'Test-TargetResource returns false when Present and Not configured' {
            Test-TargetResource -ConfigName 'proxy' -Ensure 'Present' -Value 'http://myproxy.url' | Should be $false
        }

        it 'Test-TargetResource returns false when Present and Unknown' {
            Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value 'MyValue' | Should be $false
        }

        it 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        it 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value '' } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        it 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value $null } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        it 'Test-TargetResource returns false when Absent and Configured' {
            Test-TargetResource -ConfigName 'commandExecutionTimeoutSeconds' -Ensure 'Absent' | Should be $false
        }

        it 'Test-TargetResource returns true when Absent and Not configured' {
            Test-TargetResource -ConfigName 'proxy' -Ensure 'Absent' | Should be $true
        }

        it 'Test-TargetResource returns true when Absent and Unknown' {
            Test-TargetResource -ConfigName 'MyParam' -Ensure 'Absent' | Should be $true
        }

    }

    Context "Set-TargetResource" {

        InModuleScope -ModuleName cChocoConfig -ScriptBlock {
            function choco {}
            mock choco {} 
        }

        Set-TargetResource -ConfigName "TestConfig" -Ensure "Present" -Value "MyValue"

        it "Present - Should have called choco, with set" { 
            Assert-MockCalled -CommandName choco -ModuleName cChocoConfig -ParameterFilter {
                $args -contains "'MyValue'"
            }
        }

        Set-TargetResource -ConfigName "TestConfig" -Ensure "Absent"

        it "Absent - Should have called choco, with unset" {
            Assert-MockCalled -CommandName choco -ModuleName cChocoConfig -ParameterFilter {
                $args -contains "unset"
            }
        }
    }
}
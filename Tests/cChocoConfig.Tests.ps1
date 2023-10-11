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

#---------------------------------#
# Pester tests for cChocoConfig   #
#---------------------------------#
Describe "Testing cChocoConfig" {
    BeforeAll {
        $ModuleUnderTest = "cChocoConfig"

        Import-Module $PSScriptRoot\..\DSCResources\$($ModuleUnderTest)\$($ModuleUnderTest).psm1 -Force

        if (-not $env:ChocolateyInstall) {
            # Chocolatey doesn't need to be installed for these tests, but the resource tests for it
            $env:ChocolateyInstall = "C:\ProgramData\chocolatey"
        }

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            function global:choco {}
        }

        Mock Get-Item -ModuleName $ModuleUnderTest -ParameterFilter {
            $Path.StartsWith($env:ChocolateyInstall)
        } -MockWith {
            $true
        }

        Mock Get-ChildItem -ModuleName $ModuleUnderTest -ParameterFilter {
            $Path -eq (Join-Path $env:ChocolateyInstall "config")
        } -MockWith {
            @{
                Name = "chocolatey.config"
                FullName = Join-Path $env:ChocolateyInstall "config/chocolatey.config"
            }
        }
    }
    
    AfterAll {
        Remove-Module $ModuleUnderTest
    }
    
    Context "Test-TargetResource" {
        BeforeAll {
            Mock Get-Content -ModuleName $ModuleUnderTest -ParameterFilter {
                $Path.EndsWith('chocolatey.config')
            } -MockWith {
                '<?xml version="1.0" encoding="utf-8"?>
                <chocolatey xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <config>
                    <add key="commandExecutionTimeoutSeconds" value="1339" description="Default timeout for command execution. for infinite (starting in 0.10.4)." />
                    <add key="proxy" value="" description="Explicit proxy location. Available in 0.9.9.9+." />
                </config>
                <sources>
                    <source id="chocolatey" value="https://chocolatey.org/api/v2/" disabled="false" bypassProxy="false" selfService="false" adminOnly="false" priority="0" />
                </sources>
                </chocolatey>'
            }
        }

        It 'Test-TargetResource returns true when Present and Configured.' {
            Test-TargetResource -ConfigName 'commandExecutionTimeoutSeconds' -Ensure 'Present' -Value '1339' | Should -Be $true
        }

        It 'Test-TargetResource returns false when Present and Not configured' {
            Test-TargetResource -ConfigName 'proxy' -Ensure 'Present' -Value 'http://myproxy.url' | Should -Be $false
        }

        It 'Test-TargetResource returns false when Present and Unknown' {
            Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value 'MyValue' | Should -Be $false
        }

        It 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        It 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value '' } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        It 'Test-TargetResource throws when Present and no value' {
            { Test-TargetResource -ConfigName 'MyParam' -Ensure 'Present' -Value $null } | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        It 'Test-TargetResource returns false when Absent and Configured' {
            Test-TargetResource -ConfigName 'commandExecutionTimeoutSeconds' -Ensure 'Absent' | Should -Be $false
        }

        It 'Test-TargetResource returns true when Absent and Not configured' {
            Test-TargetResource -ConfigName 'proxy' -Ensure 'Absent' | Should -Be $true
        }

        It 'Test-TargetResource returns true when Absent and Unknown' {
            Test-TargetResource -ConfigName 'MyParam' -Ensure 'Absent' | Should -Be $true
        }
    }

    Context "Set-TargetResource" {
        BeforeAll {
            Mock choco -ModuleName $ModuleUnderTest
        }

        Context "Setting a config value when Present" {
            BeforeAll {
                Set-TargetResource -ConfigName "TestConfig" -Ensure "Present" -Value "MyValue"
            }

            It "Present - Should have called choco, to set the specified ConfigName with the specified Value" {
                Assert-MockCalled choco -ModuleName $ModuleUnderTest -ParameterFilter {
                    $args[0] -eq 'config' -and
                    $args -match "\bset\b" -and
                    $args -match "'MyValue'"
                } -Scope Context
            }
        }

        Context "Removing a config value when Absent" {
            BeforeAll {
                Set-TargetResource -ConfigName "TestConfig" -Ensure "Absent"
            }

            It "Absent - Should have called choco, to unset the specified ConfigName" {
                Assert-MockCalled choco -ModuleName $ModuleUnderTest -ParameterFilter {
                    $args[0] -eq "config" -and
                    $args -match "\bunset\b" -and
                    $args -match "'TestConfig'"
                } -Scope Context
            }
        }
    }
}
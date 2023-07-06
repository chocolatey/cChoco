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

#----------------------------------------#
# Pester tests for cChocoPackageInstall  #
#----------------------------------------#
Describe -Name "Testing cChocoPackageInstall" {
    BeforeAll {
        $ModuleUnderTest = "cChocoPackageInstall"

        Import-Module $PSScriptRoot\..\DSCResources\$($ModuleUnderTest)\$($ModuleUnderTest).psm1 -Force

        if (-not $env:ChocolateyInstall) {
            # Chocolatey doesn't need to be installed for these tests, but the resource tests for it
            $env:ChocolateyInstall = "C:\ProgramData\chocolatey"
        }

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            function global:choco {}
        }
    }
    
    AfterAll {
        Remove-Module $ModuleUnderTest
    }

    Context "Package is not installed" {
        BeforeAll {
            Mock 'Get-ChocoInstalledPackage' -ModuleName 'cChocoPackageInstall' -MockWith {
                return [pscustomobject]@{
                    'Name'    = 'NotGoogleChrome'
                    'Version' = '1.0.0'
                }
            }
        }

        $TestCases = @(
            @{
                Name = "Ensure Present"
                Scenario = @{
                    Name   = 'GoogleChrome'
                    Ensure = 'Present'
                }
                ExpectedResult = $false
            }
            @{
                Name = "Ensure Absent"
                Scenario = @{
                    Name   = 'GoogleChrome'
                    Ensure = 'Absent'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Present with Version"
                Scenario = @{
                    Name    = 'GoogleChrome'
                    Ensure  = 'Absent'
                    Version = '1.0.0'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Absent with AutoUpgrade"
                Scenario = @{
                    Name        = 'GoogleChrome'
                    Ensure      = 'Absent'
                    AutoUpgrade = $True
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Absent with Version and AutoUpgrade"
                Scenario = @{
                    Name        = 'GoogleChrome'
                    Ensure      = 'Absent'
                    Version     = '1.0'
                    AutoUpgrade = $True
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Absent with MinimumVersion"
                Scenario = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Absent'
                    MinimumVersion = '1.0'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Present with MinimumVersion"
                Scenario = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Present'
                    MinimumVersion = '1.0'
                }
                ExpectedResult = $false
            }
        )

        It "Test-TargetResource <Name> should return <ExpectedResult>" -TestCases $TestCases {
            Test-TargetResource @Scenario | Should -Be $ExpectedResult
        }
    }

    Context -Name "Package is installed with version 1.0.0" {
        BeforeAll {
            Mock 'Get-ChocoInstalledPackage' -ModuleName 'cChocoPackageInstall' -MockWith {
                return [pscustomobject]@{
                    'Name'    = 'GoogleChrome'
                    'Version' = '1.0.0'
                }
            }
        }

        $TestCases = @(
            @{
                Name = "Ensure Present"
                Scenario       = @{
                    Name   = 'GoogleChrome'
                    Ensure = 'Present'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Absent"
                Scenario       = @{
                    Name   = 'GoogleChrome'
                    Ensure = 'Absent'
                }
                ExpectedResult = $false
            }
            @{
                Name = "Ensure Present with Version"
                Scenario       = @{
                    Name    = 'GoogleChrome'
                    Ensure  = 'Present'
                    Version = '1.0.0'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Present with Version"
                Scenario       = @{
                    Name    = 'GoogleChrome'
                    Ensure  = 'Present'
                    Version = '1.0.1'
                }
                ExpectedResult = $false
            }
            @{
                Name = "Ensure Present with MinimumVersion"
                Scenario       = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Present'
                    MinimumVersion = '0.9.0'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Present with MinimumVersion higher than current"
                Scenario       = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Present'
                    MinimumVersion = '1.0.1'
                }
                ExpectedResult = $false
            }
        )

        It "Test-TargetResource <Name> should return <ExpectedResult>" -TestCases $TestCases {
            Test-TargetResource @Scenario | Should -Be $ExpectedResult
        }
    }

    Context -Name "Package is installed with prerelease version 1.0.0-1" -Fixture {
        BeforeAll {
            Mock -CommandName 'Get-ChocoInstalledPackage' -ModuleName 'cChocoPackageInstall' -MockWith {
                return [pscustomobject]@{
                    'Name'    = 'GoogleChrome'
                    'Version' = '1.0.0-1'
                }
            }
        }

        $TestCases = @(
            @{
                Name = "Ensure Present with MinimumVersion lower than current version"
                Scenario       = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Present'
                    MinimumVersion = '0.9.0'
                }
                ExpectedResult = $true
            }
            @{
                Name = "Ensure Present with MinimumVersion higher than pre-release"
                Scenario       = @{
                    Name           = 'GoogleChrome'
                    Ensure         = 'Present'
                    MinimumVersion = '1.0.1'
                }
                ExpectedResult = $false
            }
        )


        It "Test-TargetResource <Name> should return <ExpectedResult>" -TestCases $TestCases {
            Test-TargetResource @Scenario | Should -Be $ExpectedResult
        }
    }
}
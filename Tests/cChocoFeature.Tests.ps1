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
# Pester tests for cChocoInstall  #
#---------------------------------#
Describe "Testing cChocoFeature" {
    BeforeAll {
        $ModuleUnderTest = "cChocoFeature"

        Import-Module $PSScriptRoot\..\DSCResources\$($ModuleUnderTest)\$($ModuleUnderTest).psm1 -Force

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            function global:choco {}
        }
    }
    
    AfterAll {
        Remove-Module $ModuleUnderTest
    }

    Context "Test-TargetResource" {
        BeforeAll {
            Mock -CommandName Get-ChocoFeature -ModuleName $ModuleUnderTest -MockWith {
                @([pscustomobject]@{
                    Name = "allowGlobalConfirmation"
                    State = "Enabled"
                    Description = "blah"
                },
                [pscustomobject]@{
                    Name = "powershellhost"
                    State = "Disabled"
                    Description = "blah"
                } ) | Where-Object { $_.Name -eq $FeatureName }
            } -Verifiable
        }

        It 'Test-TargetResource returns true when Present and Enabled.' {
            Test-TargetResource -FeatureName 'allowGlobalConfirmation' -Ensure 'Present' | Should -Be $true
        }

        It 'Test-TargetResource returns false when Present and Disabled' {
            Test-TargetResource -FeatureName 'powershellhost' -Ensure 'Present' | Should -Be $false
        }

        It 'Test-TargetResource returns false when Absent and Enabled' {
            Test-TargetResource -FeatureName 'allowGlobalConfirmation' -Ensure 'Absent' | Should -Be $false
        }

        It 'Test-TargetResource returns true when Absent and Disabled' {
            Test-TargetResource -FeatureName 'powershellhost' -Ensure 'Absent' | Should -Be $true
        }
    }

    Context "Set-TargetResource" {
        BeforeAll {
            Mock choco -ModuleName $ModuleUnderTest
        }

        Context "Enabling a Feature" {
            BeforeAll {
                Set-TargetResource -FeatureName "TestFeature" -Ensure "Present"
            }

            It "Present - Should have called choco, with enable, and the specified FeatureName" { 
                Assert-MockCalled choco -ModuleName cChocoFeature -ParameterFilter {
                    $args[0] -eq "feature" -and
                    $args[1] -eq "enable" -and
                    $args -contains "TestFeature"
                } -Scope Context
            }
        }

        Context "Disabling a Feature" {
            BeforeAll {
                Set-TargetResource -FeatureName "TestFeature" -Ensure "Absent"
            }

            It "Absent - Should have called choco, with disable, and the specified FeatureName" {
                Assert-MockCalled choco -ModuleName cChocoFeature -ParameterFilter {
                    $args[0] -eq "feature" -and
                    $args[1] -eq "disable" -and
                    $args -contains "TestFeature"
                } -Scope Context
            }
        }
    }
}
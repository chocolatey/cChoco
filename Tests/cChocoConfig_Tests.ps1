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
$ResourceName = ((Split-Path -Path $MyInvocation.MyCommand.Path -Leaf) -split '_')[0]
$ResourceFile = (Get-DscResource -Name $ResourceName).Path

$TestsPath    = (split-path -path $MyInvocation.MyCommand.Path -Parent)
$ResourceFile = Get-ChildItem -Recurse $TestsPath\.. -File | Where-Object {$_.name -eq "$ResourceName.psm1"}

Import-Module -Name $ResourceFile.FullName

Describe -Name "Testing $ResourceName loaded from $ResourceFile" -Fixture {
    $MyProxyUrl = 'http://foo'
    Context -Name "Proxy config is set to '$MyProxyUrl'" -Fixture {
        Mock -CommandName 'Get-ChocoConfig' -ModuleName 'cChocoConfig' -MockWith {
            return 'http://foo'
        }

        # returns true if config matches supplied value
        $Scenario1 = @{
            Key    = 'Proxy'
            Ensure = 'Present'
            Value  = $MyProxyUrl
        }
        It -name "Test-TargetResource -ensure 'Present' -Value '$MyProxyUrl' should return True" -test {
            Test-TargetResource @Scenario1 | Should Be $true
        }

        # returns true if config matches supplied value (via xml)
        $Scenario2 = @{
            Key      = 'Proxy'
            Ensure   = 'Present'
            Value    = $MyProxyUrl
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Present' -Value '$MyProxyUrl' -QueryXML `$true should return True" -test {
            Test-TargetResource @Scenario2 | Should Be $true
        }

        # returns false if config does not match supplied value
        $Scenario3 = @{
            Key      = 'Proxy'
            Ensure   = 'Present'
            Value    = 'http://some/other/url'
        }
        It -name "Test-TargetResource -ensure 'Present' -Value 'http://some/other/url' should return False" -test {
            Test-TargetResource @Scenario3 | Should Be $false
        }

        # returns false if config does not match supplied value (via xml)
        $Scenario4 = @{
            Key      = 'Proxy'
            Ensure   = 'Present'
            Value    = 'http://some/other/url'
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Present' -Value 'http://some/other/url' -QueryXML `$true should return False" -test {
            Test-TargetResource @Scenario4 | Should Be $false
        }

        # returns false if ensure absent
        $Scenario5 = @{
            Key      = 'Proxy'
            Ensure   = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return False" -test {
            Test-TargetResource @Scenario5 | Should Be $false
        }

        # returns false if ensure absent (via xml)
        $Scenario6 = @{
            Key      = 'Proxy'
            Ensure   = 'Absent'
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Absent' -QueryXML `$true should return False" -test {
            Test-TargetResource @Scenario6 | Should Be $false
        }

        # throws when ensure present but no value given
        $Scenario7 = @{
            Key      = 'Proxy'
            Ensure   = 'Present'
        }
        It -name "Test-TargetResource -ensure 'Present' should throw" -test {
            {Test-TargetResource @Scenario7} | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }

        # throws when ensure present but no value given (via xml)
        $Scenario8 = @{
            Key       = 'Proxy'
            Ensure    = 'Present'
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Present' -QueryXML `$true should throw" -test {
            {Test-TargetResource @Scenario8} | Should -Throw "Missing parameter 'Value' when ensuring config is present!"
        }
    }
    
    Context -Name "Proxy config is not set" -Fixture {
        Mock -CommandName 'Get-ChocoConfig' -ModuleName 'cChocoConfig' -MockWith {
            return ''
        }

        # returns false if value supplied
        $Scenario1 = @{
            Key    = 'Proxy'
            Ensure = 'Present'
            Value  = $MyProxyUrl
        }
        It -name "Test-TargetResource -ensure 'Present' -Value '$MyProxyUrl' should return False" -test {
            Test-TargetResource @Scenario1 | Should Be $false
        }

        # returns true if value supplied (via xml)
        $Scenario2 = @{
            Key      = 'Proxy'
            Ensure   = 'Present'
            Value    = $MyProxyUrl
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Present' -Value '$MyProxyUrl' -QueryXML `$true should return False" -test {
            Test-TargetResource @Scenario2 | Should Be $false
        }

        # returns true if ensure absent
        $Scenario5 = @{
            Key      = 'Proxy'
            Ensure   = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return True" -test {
            Test-TargetResource @Scenario5 | Should Be $true
        }

        # returns true if ensure absent (via xml)
        $Scenario6 = @{
            Key      = 'Proxy'
            Ensure   = 'Absent'
            QueryXML = $true
        }
        It -name "Test-TargetResource -ensure 'Absent' -QueryXML `$true should return True" -test {
            Test-TargetResource @Scenario6 | Should Be $true
        }
    }
}

#Clean-up
Remove-Module cChocoConfig

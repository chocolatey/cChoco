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

Describe "Testing cChoco DSC Resources against PSScriptAnalyzer rule-set" {
  #---------------------------------#
  # PSScriptAnalyzer tests          #
  #---------------------------------#
  BeforeDiscovery {
    $Rules   = Get-ScriptAnalyzerRule

    # Only run on these for now as they are the only resources that have had code adjustments for PSScriptAnalyzer rules.
    $Modules = Get-ChildItem “$PSScriptRoot\..\DSCResources” -Filter ‘*.psm1’ -Recurse | Where-Object {$_.Name -match '(cChocoInstaller|cChocoPackageInstall|cChocoFeature)\.psm1$'} | ForEach-Object {
      @{
        ModuleName = $_.BaseName
        ModulePath = $_.FullName
        RuleNames  = $Rules.RuleName
      }
    }
  }

  #---------------------------------#
  # Run Module tests (psm1)         #
  #---------------------------------#
  Describe ‘Testing <ModuleName> against default PSScriptAnalyzer rules’ -ForEach $Modules {
    BeforeAll {
      $Failures = Invoke-ScriptAnalyzer -Path $ModulePath -IncludeRule $RuleNames
    }
    It "Passes '<_>'" -ForEach $RuleNames {
      ($RuleFailures = $Failures | Where-Object RuleName -eq $_).ForEach{
        throw (
          [Management.Automation.ErrorRecord]::new(
            ([Exception]::new(($RuleFailures.ForEach{$_.ScriptName + ":" + $_.Line + " " + $_.Message} -join "`n"))),
            "ScriptAnalyzerViolation",
            "SyntaxError",
            $RuleFailures
          )
        )
      }
    }
  }
}
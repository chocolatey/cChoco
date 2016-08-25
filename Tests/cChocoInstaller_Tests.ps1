#---------------------------------# 
# PSScriptAnalyzer tests          # 
#---------------------------------# 
$Modules = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.psm1’ -Recurse | Where-Object {$_.FullName -match 'cChocoInstaller.psm1$'}
#$Scripts = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.ps1’ -Recurse | Where-Object {$_.name -NotMatch ‘Tests.ps1’}
$Rules   = Get-ScriptAnalyzerRule

if ($Modules.count -gt 0) {
  Describe ‘Testing all Modules against default PSScriptAnalyzer rule-set’ {
    foreach ($module in $modules) {
      Context “Testing Module '$($module.FullName)'” {
        foreach ($rule in $rules) {
          It “passes the PSScriptAnalyzer Rule $rule“ {
            (Invoke-ScriptAnalyzer -Path $module.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
          }
        }
      }
    }
  }
}
if ($Scripts.count -gt 0) {
  Describe ‘Testing all Script against default PSScriptAnalyzer rule-set’ {
    foreach ($Script in $scripts) {
      Context “Testing Script '$($script.FullName)'” {
        foreach ($rule in $rules) {
          It “passes the PSScriptAnalyzer Rule $rule“ {
            if (-not ($module.BaseName -match 'AppVeyor') -and -not ($rule.Rulename -eq 'PSAvoidUsingWriteHost') ) {
              (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
            }
          }
        }
      }
    }
  }
}
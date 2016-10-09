#---------------------------------# 
# PSScriptAnalyzer tests          # 
#---------------------------------# 
$Rules   = Get-ScriptAnalyzerRule | Where-Object {$_.RuleName -notmatch 'PSUseShouldProcessForStateChangingFunctions|PSUseDeclaredVarsMoreThanAssignments|PSShouldProcess'}

#Only run on cChocoInstaller.psm1 for now as this is the only resource that has had code adjustments for PSScriptAnalyzer rules.
$Modules = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.psm1’ -Recurse | Where-Object {$_.FullName -match 'cChocoInstaller.psm1$'}
#$Scripts = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.ps1’ -Recurse | Where-Object {$_.name -NotMatch ‘Tests.ps1’}

#---------------------------------# 
# Run Module tests (psm1)         # 
#---------------------------------# 
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

#---------------------------------# 
# Run Script tests (ps1)          # 
#---------------------------------# 
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
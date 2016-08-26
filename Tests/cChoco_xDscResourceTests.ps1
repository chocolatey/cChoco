#---------------------------------# 
# Pester tests for cChocoInstaller# 
#---------------------------------#
$DSC = Get-DscResource | Where-Object {$_.Module.Name -eq 'cChoco'}


foreach ($Resource in $DSC)
{ 
  if (-not ($Resource.ImplementedAs -eq 'Composite') ) {
    $ResourceName = $Resource.ResourceType
    $Mof          = Get-ChildItem “$PSScriptRoot\..\” -Filter "$resourcename.schema.mof" -Recurse 

    Describe "Testing $ResourceName" {
      Context “Testing DscResource '$ResourceName.psm1' using Test-xDscResource” {
        It 'Test-xDscResource should return $true' {
          Test-xDscResource -Name $ResourceName | Should Be $true
        }    
      }

      Context “Testing DscSchema '$ResourceName.psm1' using Test-xDscSchema” {
        It 'Test-xDscSchema should return true' {
          Test-xDscSchema -Path $Mof.FullName | Should Be $true
        }    
      }
    }
  }
}
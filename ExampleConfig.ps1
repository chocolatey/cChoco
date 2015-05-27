Configuration myChocoConfig
{
   Import-DscResource -Module cChoco  
   Node "localhost"
   {
      LocalConfigurationManager
      {
          DebugMode = 'ForceModuleImport'
      }
      cChocoInstaller installChoco
      {
        InstallDir = "c:\choco"
      }
      cChocoPackageInstaller installChrome
      {
        Name = "googlechrome"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller installAtomSpecificVersion
      {
        Name = "atom"
        Version = "0.155.0"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller installGit
      {
         Name = "git"
         Params = "/Someparam "
         DependsOn = "[cChocoInstaller]installChoco"
      }
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose -force
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
      cChocoPackageInstaller installSkypeWithChocoParams
      {
        Name                 = 'skype'
        chocoParams          = '--allowdowngrade --allowemptychecksum --allowemptychecksumsecure'
        Ensure               = 'Present'
        Version              = '7.25.0.106'
        DependsOn            = '[cChocoInstaller]installChoco'
      }
      cChocoPackageInstaller installAtomSpecificVersion
      {
        Name = "atom"
        Version = "0.155.0"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller installGit
      {
         Ensure = 'Present'
         Name = "git"
         Params = "/Someparam-passed-to-installer " 
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller noFlashAllowed
      {
         Ensure = 'Absent'
         Name = "flashplayerplugin"
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstallerSet installSomeStuff
      {
         Ensure = 'Present'
         Name = @(
			"git",
			"7zip"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstallerSet stuffToBeRemoved
      {
         Ensure = 'Absent'
         Name = @(
			"vlc",
			"ruby",
			"adobeair"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose -force

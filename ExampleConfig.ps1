﻿Configuration myChocoConfig
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
         Ensure = 'Present'
         Name = "git"
         Params = "/Someparam "
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller installGitChocoEmptyChecksum
      {
          Ensure = 'Present'
          Name = 'git'
          AllowEmptyChecksums = $true #This property is only valid for chocolatey v0.10.0 or later.
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
			"git"
			"skype"
			"7zip"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstallerSet stuffToBeRemoved
      {
         Ensure = 'Absent'
         Name = @(
			"vlc"
			"ruby"
			"adobeair"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose -force
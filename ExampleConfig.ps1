Configuration myChocoConfig
{
   Import-DscResource -Module cChoco  
   Node "localhost"
   {
      LocalConfigurationManager
      {
          ConfigurationMode = "ApplyAndAutoCorrect"
          ConfigurationModeFrequencyMins = 30 #must be a multiple of the RefreshFrequency and how often configuration is checked
      }
      cChocoInstaller installChoco
      {
        InstallDir = "c:\choco"
      }
      cChocoPackageInstaller installChrome
      {
        Name = "google-chrome-x64"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose
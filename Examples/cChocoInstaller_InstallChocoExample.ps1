Configuration InstallChoco
{
   Import-DscResource -Module cChoco  
   Node "localhost"
   {
      cChocoInstaller InstallChoco
      {
        InstallDir = "c:\choco"
      }
   }
} 

$config = InstallChoco

Start-DscConfiguration -Path $config.psparentpath -Wait -Verbose -Force
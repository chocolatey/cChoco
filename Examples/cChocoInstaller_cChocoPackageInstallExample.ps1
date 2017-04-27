Configuration InstallChoco
{
    Import-DscResource -Module cChoco  
    Node "localhost"
    {
        cChocoPackageInstaller installSkypeWithChocoParams
        {
            Name                 = 'skype'
            Ensure               = 'Present'
            AutoUpgrade          = $True       
            Version              = 7.35.0.101
        }
    }
} 

$config = InstallChoco

Start-DscConfiguration -Path $config.psparentpath -Wait -Verbose -Force

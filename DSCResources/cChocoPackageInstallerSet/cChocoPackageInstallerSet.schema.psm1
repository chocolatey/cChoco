Configuration cChocoPackageInstallerSet
{
<#
.SYNOPSIS
Composite DSC Resource allowing you to specify multiple choco packages in a single resource block.
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present',
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    foreach ($pName in $Name) {
        cChocoPackageInstaller "cChocoPackageInstaller_$($Ensure)_$($pName)" {
            Ensure = $Ensure
            Name = $pName
            Source = $Source
        }
    }
}

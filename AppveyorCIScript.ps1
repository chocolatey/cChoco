$ErrorActionPreference = "Stop"

##Function used to output PSON - http://stackoverflow.com/questions/15139552/save-hash-table-in-powershell-object-notation-pson
Function ConvertTo-PSON($Object, [Int]$Depth = 9, [Int]$Layers = 1, [Switch]$Strict, [Version]$Version = $PSVersionTable.PSVersion) {
    $Format = $Null
    $Quote = If ($Depth -le 0) {""} Else {""""}
    $Space = If ($Layers -le 0) {""} Else {" "}
    If ($Object -eq $Null) {"`$Null"} Else {
        $Type = "[" + $Object.GetType().Name + "]"
        $PSON = If ($Object -is "Array") {
            $Format = "@(", ",$Space", ")"
            If ($Depth -gt 1) {For ($i = 0; $i -lt $Object.Count; $i++) {ConvertTo-PSON $Object[$i] ($Depth - 1) ($Layers - 1) -Strict:$Strict}}
        } ElseIf ($Object -is "Xml") {
            $Type = "[Xml]"
            $String = New-Object System.IO.StringWriter
            $Object.Save($String)
            $Xml = "'" + ([String]$String).Replace("`'", "&apos;") + "'"
            If ($Layers -le 0) {($Xml -Replace "\r\n\s*", "") -Replace "\s+", " "} ElseIf ($Layers -eq 1) {$Xml} Else {$Xml.Replace("`r`n", "`r`n`t")}
            $String.Dispose()
        } ElseIf ($Object -is "DateTime") {
            "$Quote$($Object.ToString('s'))$Quote"
        } ElseIf ($Object -is "String") {
            0..11 | ForEach {$Object = $Object.Replace([String]"```'""`0`a`b`f`n`r`t`v`$"[$_], ('`' + '`''"0abfnrtv$'[$_]))}; "$Quote$Object$Quote"
        } ElseIf ($Object -is "Boolean") {
            If ($Object) {"`$True"} Else {"`$False"}
        } ElseIf ($Object -is "Char") {
            If ($Strict) {[Int]$Object} Else {"$Quote$Object$Quote"}
        } ElseIf ($Object -is "ValueType") {
            $Object
        } ElseIf ($Object.Keys -ne $Null) {
            If ($Type -eq "[OrderedDictionary]") {$Type = "[Ordered]"}
            $Format = "@{", ";$Space", "}"
            If ($Depth -gt 1) {$Object.GetEnumerator() | ForEach {$_.Name + "$Space=$Space" + (ConvertTo-PSON $_.Value ($Depth - 1) ($Layers - 1) -Strict:$Strict)}}
        } ElseIf ($Object -is "Object") {
            If ($Version -le [Version]"2.0") {$Type = "New-Object PSObject -Property "}
            $Format = "@{", ";$Space", "}"
            If ($Depth -gt 1) {$Object.PSObject.Properties | ForEach {$_.Name + "$Space=$Space" + (ConvertTo-PSON $_.Value ($Depth - 1) ($Layers - 1) -Strict:$Strict)}}
        } Else {$Object}
        If ($Format) {
            $PSON = $Format[0] + (&{
                If (($Layers -le 1) -or ($PSON.Count -le 0)) {
                    $PSON -Join $Format[1]
                } Else {
                    ("`r`n" + ($PSON -Join "$($Format[1])`r`n")).Replace("`r`n", "`r`n`t") + "`r`n"
                }
            }) + $Format[2]
        }
        If ($Strict) {"$Type$PSON"} Else {"$PSON"}
    }
} Set-Alias PSON ConvertTo-PSON -Description "Convert variable to PSON"

##Variables
$ModuleName = $env:ModuleName
$ModuleLocation = $env:APPVEYOR_BUILD_FOLDER
$PublishingNugetKey = $env:nugetKey
$Psd1Path = "./$ModuleName.psd1"
$BuildNumber = $env:APPVEYOR_BUILD_NUMBER

##Setup
#Add current directory to ps modules path so module is available 
$env:psmodulepath = $env:psmodulepath + ";" + $ModuleLocation
#Install dsc resource designer to make tests available
Install-Module -Name xDSCResourceDesigner -force

##Test the resource
$DSC = Get-DscResource
write-host `n
write-host " Testing each resource in module: " -NoNewline
write-host "$ModuleName" -ForegroundColor blue -BackgroundColor darkyellow
write-host `n

##Check module exists
if (-not ($DSC | ? {$_.Module.Name -eq $ModuleName}))
{
    Write-Error "Module not found: $ModuleName"
}

$ExportedDSCResources = @()
##Test the modules resources
foreach ($Resource in ($DSC | ? {$_.Module.Name -eq $ModuleName})) 
{
    write-host "Running Tests against $($Resource.Name) resource" -ForegroundColor Yellow
    try 
    {
        $Result = Test-xDscResource -Name $Resource.Name
        switch ($Result) 
        {
            $True 
            {
                write-host "All tests passed for $($Resource.Name)." -ForegroundColor Green
                #Add resource to array of strings, later used to update the manifest
                $ExportedDSCResources += $Resource.Name
            }
            $False 
            {
                Write-Error "One or more tests failed for $($Resource.Name)." -ForegroundColor Red
                exit 1
            }
        }
        write-host `n

    }
    catch 
    {
        Write-Warning "The test for $($Resource.Name) failed due to an error"
        Write-Error $_.Exception.Message
        exit 1
    }
}

#If it's a pull request call it a day, we just wanted to run the tests
if ($env:APPVEYOR_PULL_REQUEST_TITLE)
{
    Write-Host "Finished testing of PR: $env:APPVEYOR_PULL_REQUEST_TITLE - Build Ending"
    exit;
}

##Checkout git master branch
#& git checkout master 2>$null
Start-Process -FilePath git -ArgumentList "checkout master" -Wait -NoNewWindow

#Update the manifest with included DSC Resources
#Disabled for now as only supported in Powershell5
#Update-ModuleManifest -Path $Psd1Path -DscResourcesToExport $ExportedDSCResources

##Increment version number of the module

write-host "Incrementing Module version, current version: " -NoNewline

#Load file content
$ModuleDefinitionContent = Get-Content -Path $Psd1Path | Out-String
#Invoke the contents to create hashttable we can edit. 
$ModuleDefinition = Invoke-Expression $ModuleDefinitionContent
#Get current version number from hashtable
$CurrentVersion = [version]$ModuleDefinition.ModuleVersion

write-host "$CurrentVersion" -ForegroundColor blue -BackgroundColor darkyellow

#Increment the revision number
$ModuleDefinition.ModuleVersion = (New-Object -TypeName System.Version -ArgumentList $CurrentVersion.Major, $CurrentVersion.Minor, ($CurrentVersion.Build+1), $BuildNumber).ToString()

write-host "New version: " -NoNewline
write-host "$($ModuleDefinition.ModuleVersion)" -ForegroundColor blue -BackgroundColor darkyellow

#Update the module with the new version
#Todo - Find out why this isn't working in Appveyor 
#$NewVersion = New-Object -TypeName System.Version -ArgumentList $CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build, ($CurrentVersion.Revision + 1)
#Update-ModuleManifest -Path $Psd1Path -ModuleVersion $NewVersion

#Workaround for Update-ModuleManifest issue
#Convert ht back to pson and write out to file
ConvertTo-PSON $ModuleDefinition -Layers 3 | Set-Content -Path $Psd1Path


##Publish the resource
write-host `n
write-host "Publishing module to Powershell Gallery: " -NoNewline
write-host "$ModuleName" -ForegroundColor blue -BackgroundColor darkyellow
write-host `n

Publish-Module -Name $ModuleName -NuGetApiKey $PublishingNugetKey

##Commit updated version back to github
$GitUpdatedFile = "$ModuleName.psd1"
git config --global credential.helper store
Add-Content "$env:USERPROFILE\.git-credentials" "https://$($env:github_access_token):x-oauth-basic@github.com`n"
git config --global user.email "cibuild@withappveyor.com"
git config --global user.name "AutomatedCI Build"
git config --global push.default simple
git add $GitUpdatedFile
git commit -m "Pushed to PSGallery with updated version number: $($ModuleDefinition.ModuleVersion)"
#Workaround for stderror redirect on appveyor causing build error. 
Start-Process -FilePath git -ArgumentList "push" -Wait -NoNewWindow


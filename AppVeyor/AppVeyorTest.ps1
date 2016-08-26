#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host "Current working directory: $pwd"

#---------------------------------# 
# Run Pester Tests                # 
#---------------------------------# 
$resultsFile = '.\TestsResults.xml'
$testFiles   = Get-ChildItem | Select-Object -ExpandProperty FullName
$results     = Invoke-Pester -Script $testFiles -OutputFormat NUnitXml -OutputFile $resultsultsFile -PassThru

Write-Host 'Uploading results'
(New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $resultsFile))

#---------------------------------# 
# Validate                        # 
#---------------------------------# 
if (($results.FailedCount -gt 0) -or ($results.PassedCount -eq 0)) { 
  throw "$($results.FailedCount) tests failed."
} else {
  Write-Host 'All tests passed' -ForegroundColor Green
}
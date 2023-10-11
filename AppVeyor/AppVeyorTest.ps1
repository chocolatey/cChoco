﻿# Copyright (c) 2017 Chocolatey Software, Inc.
# Copyright (c) 2013 - 2017 Lawrence Gripper & original authors/contributors from https://github.com/chocolatey/cChoco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#---------------------------------#
# Header                          #
#---------------------------------#
Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host "Current working directory: $pwd"

#---------------------------------#
# Run Pester Tests                #
#---------------------------------#
$resultsFile = '.\TestsResults.xml'
$PesterConfiguration = New-PesterConfiguration @{
  Run = @{
    Path     = "$PSScriptRoot\..\tests"
    PassThru = $true
  }
  TestResult = @{
    Enabled = $true
    OutputFormat = "NUnitXml"
    OutputPath = $resultsFile
  }
  Output = @{
    Verbosity = "Detailed"
  }
}
$results = Invoke-Pester -Configuration $PesterConfiguration

Write-Host 'Uploading results'
try {
  if ($env:APPVEYOR_JOB_ID) {
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $resultsFile))
  }
} catch {
  throw "Upload failed."
}

#---------------------------------#
# Validate                        #
#---------------------------------#
if (($results.FailedCount -gt 0) -or ($results.PassedCount -eq 0) -or ($null -eq $results)) {
  throw "$($results.FailedCount) tests failed."
} else {
  Write-Host 'All tests passed' -ForegroundColor Green
}

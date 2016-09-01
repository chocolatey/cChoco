#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor build script' -ForegroundColor Yellow
Write-Host "ModuleName    : $env:ModuleName"
Write-Host "Build version : $env:APPVEYOR_BUILD_VERSION"
Write-Host "Author        : $env:APPVEYOR_REPO_COMMIT_AUTHOR"
Write-Host "Branch        : $env:APPVEYOR_REPO_BRANCH"

#---------------------------------# 
# BuildScript                     # 
#---------------------------------# 
Write-Host 'Nothing to build, skipping.....'
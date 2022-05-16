# Copyright (c) 2017 Chocolatey Software, Inc.
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

Configuration InstallChoco
{
    Import-DscResource -Module cChoco
    Node "localhost"
    {
        # If you are building many servers at once, Chocolatey's public nuget feed will rate limit you.
        # To avoid HTTP 429 errors, it is worthwhile to host your own proxy nuget feed.
        Environment chocolateyDownloadUrl
        {
            # this environment variable is used by the install.ps1 script from https://community.chocolatey.org/install.ps1
            # it allows you to specify an alternate download location for the Chocolatey CLI .nupkg
            Name = "chocolateyDownloadUrl"
            Path = $false
            Value = "https://your-custom-nuget-feed.mycompany.com/some_url/chocolatey.1.1.0.nupkg"
            Ensure = "Present"
        }
        cChocoInstaller InstallChoco
        {
            InstallDir = "c:\choco"
            DependsOn = "[Environment]chocolateyDownloadUrl"
        }
        cChocoPackageInstaller installSkypeWithChocoParams
        {
            Name                 = 'skype'
            Ensure               = 'Present'
            DependsOn            = '[cChocoInstaller]installChoco'
        }
    }
}

$config = InstallChoco

Start-DscConfiguration -Path $config.psparentpath -Wait -Verbose -Force

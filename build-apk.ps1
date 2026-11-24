$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$env:TEMP = 'D:\QuizQuest\work\temp'
$env:TMP = $env:TEMP
$env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot'
$env:GRADLE_USER_HOME = 'D:\QuizQuest\work\gradle'
$env:ANDROID_USER_HOME = 'D:\QuizQuest\work\android-user'
$env:ANDROID_HOME = 'D:\Android\Sdk\Sdk'
$env:PUB_CACHE = 'D:\QuizQuest\work\pub-cache'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
# Keep a separate symbol directory for each build so crash traces remain usable.
$symbolPath = Join-Path $PSScriptRoot ('work\release-symbols\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $symbolPath -Force | Out-Null
Push-Location -LiteralPath (Join-Path $PSScriptRoot 'android')
try {
    & .\gradlew.bat assembleRelease --console=plain "-Pdart-obfuscation=true" "-Psplit-debug-info=$symbolPath"
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
} finally {
    Pop-Location
}
$apkPath = Join-Path $PSScriptRoot 'build\app\outputs\apk\release\app-release.apk'
New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'deliverables') -Force | Out-Null
Copy-Item -LiteralPath $apkPath -Destination (Join-Path $PSScriptRoot 'deliverables\LearnCodz-v1.0.11.apk') -Force
Write-Output 'APK: D:\QuizQuest\deliverables\LearnCodz-v1.0.11.apk'

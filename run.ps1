$env:TEMP = 'D:\QuizQuest\work\temp'
$env:TMP = $env:TEMP
$env:PUB_CACHE = 'D:\QuizQuest\work\pub-cache'
$env:GRADLE_USER_HOME = 'D:\QuizQuest\work\gradle'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Set-Location -LiteralPath $PSScriptRoot
flutter pub get
if ($LASTEXITCODE -eq 0) { flutter run -d chrome --web-port=52731 }

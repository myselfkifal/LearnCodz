$env:TEMP = 'D:\QuizQuest\work\temp'
$env:TMP = $env:TEMP
$env:PUB_CACHE = 'D:\QuizQuest\work\pub-cache'
$env:GRADLE_USER_HOME = 'D:\QuizQuest\work\gradle'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Set-Location -LiteralPath $PSScriptRoot

# Keep a fixed origin so browser progress is preserved between runs.
$previewPort = 52731
$previewUrl = "http://localhost:$previewPort"
$listener = Get-NetTCPConnection -LocalPort $previewPort -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $isLearnCodz = $false
    try {
        $response = Invoke-WebRequest -Uri $previewUrl -UseBasicParsing -TimeoutSec 5
        $isLearnCodz = $response.Content -match '<title>\s*LearnCodz'
    } catch {}
    if ($isLearnCodz) {
        Write-Host "LearnCodz is already running: $previewUrl" -ForegroundColor Green
        Write-Host 'Open that address in Chrome. To load source changes, press R in the original Flutter terminal.'
        Write-Host 'To restart instead, press q in that terminal, then run this launcher again.'
    } else {
        Write-Host "Port $previewPort is occupied by another server. Stop it before starting LearnCodz." -ForegroundColor Yellow
        Write-Host 'The launcher keeps the same port to preserve your browser progress.'
    }
    return
}

flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "Open LearnCodz in Chrome: $previewUrl" -ForegroundColor Green
    Write-Host 'Keep this terminal open. Press R here after editing source, or q to stop.'
    flutter run -d web-server --web-hostname=localhost --web-port=$previewPort --no-web-resources-cdn
}

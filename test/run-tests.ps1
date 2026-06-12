param(
    [string]$Group  # 可选：指定测试组，如 "test-text"
)

$MYVIM = "vim"
$ScriptDir = (Get-Location).Path
$ExitCode = 0

function Run-TestFile($vimFile) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($vimFile)
    $testDir = [System.IO.Path]::GetDirectoryName($vimFile)
    Write-Host "  $name ... " -NoNewline
    $args = "-es", "-T", "dumb", "--not-a-term", "--noplugin", "-n", "-u", $vimFile, "+qall"
    $proc = Start-Process $MYVIM -ArgumentList $args -NoNewWindow -Wait -PassThru -WorkingDirectory $testDir
    if ($proc.ExitCode -ne 0) {
        Write-Host "FAILED" -ForegroundColor Red
        return 1
    }
    Write-Host "OK" -ForegroundColor Green
    return 0
}

if (![string]::IsNullOrEmpty($Group)) {
    # 运行指定测试组
    $groupDir = "$ScriptDir\$Group"
    if (!(Test-Path $groupDir)) {
        Write-Host "Test group not found: $Group" -ForegroundColor Red
        exit 1
    }
    Write-Host "Running: $Group"
    Get-ChildItem $groupDir -Filter "test-*.vim" | ForEach-Object {
        $ExitCode += Run-TestFile $_.FullName
    }
} else {
    # 运行所有测试组
    Write-Host "Running all tests"
    Get-ChildItem $ScriptDir -Directory -Filter "test-*" | ForEach-Object {
        Write-Host "Group: $($_.Name)"
        Get-ChildItem $_.FullName -Filter "test-*.vim" | ForEach-Object {
            $ExitCode += Run-TestFile $_.FullName
        }
    }
}

if ($ExitCode -gt 0) {
    Write-Host "`n$ExitCode test(s) failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll tests passed" -ForegroundColor Green
    exit 0
}

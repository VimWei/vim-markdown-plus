param(
    [string]$Group  # 可选：指定测试组，如 "test-text"
)

$MYVIM = "vim"
$MYVIM_ARGS = "-es", "-T", "dumb", "--not-a-term", "--noplugin", "-n"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExitCode = 0

function Run-TestFile($vimFile) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($vimFile)
    Write-Host "  $name ... " -NoNewline
    $proc = Start-Process $MYVIM -ArgumentList @($MYVIM_ARGS, "-u", $vimFile, "+qall") -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "FAILED" -ForegroundColor Red
        return 1
    }
    Write-Host "OK" -ForegroundColor Green
    return 0
}

if ($Group -ne '') {
    # 运行指定测试组
    $groupDir = Join-Path $ScriptDir $Group
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

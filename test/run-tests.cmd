@echo off
setlocal
set MYVIM=vim
set MYVIM_ARGS=-es -T dumb --not-a-term --noplugin -n
set EXIT_CODE=0

for /d %%D in (test-*) do (
    echo Group: %%D
    for %%F in (%%D\test-*.vim) do (
        echo   %%~nF ...
        %MYVIM% %MYVIM_ARGS% -u "%%F" +qall
        if errorlevel 1 (
            echo     FAILED
            set /a EXIT_CODE+=1
        ) else (
            echo     OK
        )
    )
)

if %EXIT_CODE% gtr 0 (
    echo %EXIT_CODE% test(s) failed
    exit /b 1
) else (
    echo All tests passed
    exit /b 0
)

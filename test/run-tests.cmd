@echo off
setlocal
set MYVIM=vim
set MYVIM_ARGS=-es -T dumb --not-a-term --noplugin -n
set EXIT_CODE=0
set FOUND_TESTS=0

for /d %%D in (test-*) do (
    if exist "%%D\" (
        echo Group: %%D
        for %%F in (%%D\test-*.vim) do (
            if exist "%%F" (
                set FOUND_TESTS=1
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
    )
)

if %FOUND_TESTS%==0 (
    echo No test files found.
    exit /b 0
)

if %EXIT_CODE% gtr 0 (
    echo %EXIT_CODE% test(s) failed
    exit /b 1
) else (
    echo All tests passed
    exit /b 0
)

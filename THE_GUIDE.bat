@echo off
setlocal EnableExtensions EnableDelayedExpansion
title AI Pendrive - Setup Wizard ^& System Check
color 0A

rem ============================================================================
rem CLICK-ME.BAT - AI Pendrive Setup Wizard and System Requirement Checker
rem ============================================================================
rem This script:
rem   1. Validates the folder structure and required files.
rem   2. Checks the Windows version, CPU cores, RAM, and GPU availability.
rem   3. Verifies the llamafile runtime is present.
rem   4. Verifies the model files for each hardware tier are present.
rem   5. Guides the user step by step to fix any missing requirement.
rem   6. Confirms the user followed each instruction before moving on.
rem   7. Offers to launch the recommended launcher when setup is complete.
rem
rem Run by double-clicking this file. Admin rights are NOT required.
rem ============================================================================

set "ROOT=%~dp0"
pushd "%ROOT%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Could not enter the project directory.
    pause
    exit /b 1
)

set "LOG=%~dp0setup_report.txt"
set "PASS=0"
set "FAIL=0"
set "WARN=0"
set "INSTALLED=0"

rem Total counts for progress bar
set "TOTAL_CHECKS=14"
set "CURRENT_CHECK=0"

rem ============================================================================
rem HELPER FUNCTIONS
rem ============================================================================

rem ---- Draw a section header ----
call :DrawHeader "AI PENDRIVE - SETUP WIZARD AND SYSTEM CHECK"

rem ---- Intro ----
echo.
echo   This wizard will verify that your machine and this folder are ready
echo   to run the local LLM server. It will check every requirement one at a
echo   time and tell you exactly what to do if something is missing.
echo.
echo   Nothing will be downloaded automatically. You stay in control.
echo.
echo   A report will be saved to: setup_report.txt
echo.
echo ============================================================================
echo   PRESS ANY KEY TO BEGIN THE CHECK
echo ============================================================================
pause >nul

rem Start fresh log
>"%LOG%" echo ============================================================================
>>"%LOG%" echo AI PENDRIVE SETUP REPORT
>>"%LOG%" echo Generated: %DATE% %TIME%
>>"%LOG%" echo Root: %ROOT%
>>"%LOG%" echo ============================================================================
>>"%LOG%" echo.

cls
call :DrawHeader "STEP-BY-STEP SYSTEM CHECK"

rem ============================================================================
rem CHECK 1 - WINDOWS VERSION
rem ============================================================================
call :Progress "1" "Windows version"
call :CheckWindows

rem ============================================================================
rem CHECK 2 - CPU CORES
rem ============================================================================
call :Progress "2" "CPU cores"
call :CheckCPU

rem ============================================================================
rem CHECK 3 - SYSTEM RAM
rem ============================================================================
call :Progress "3" "System RAM"
call :CheckRAM

rem ============================================================================
rem CHECK 4 - NVIDIA GPU (optional)
rem ============================================================================
call :Progress "4" "NVIDIA GPU (optional)"
call :CheckGPU

rem ============================================================================
rem CHECK 5 - FOLDER STRUCTURE
rem ============================================================================
call :Progress "5" "Project folder structure"
call :CheckFolders

rem ============================================================================
rem CHECK 6 - LLAMAFILE RUNTIME
rem ============================================================================
call :Progress "6" "Llamafile runtime executable"
call :CheckLlamafile

rem ============================================================================
rem CHECK 7 - MODEL: 4GB TIER
rem ============================================================================
call :Progress "7" "Model for 4 GB GPU profile"
call :CheckModel "4GB" "models\4GB\Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q8_0.gguf"

rem ============================================================================
rem CHECK 8 - MODEL: 6GB TIER
rem ============================================================================
call :Progress "8" "Model for 6 GB GPU profile"
call :CheckModel "6GB" "models\6GB\Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"

rem ============================================================================
rem CHECK 9 - MODEL: 8GB TIER
rem ============================================================================
call :Progress "9" "Model for 8 GB GPU profile"
call :CheckModel "8GB" "models\8GB\Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"

rem ============================================================================
rem CHECK 10 - MODEL: NO GPU TIER
rem ============================================================================
call :Progress "10" "Model for CPU-only profile"
call :CheckModel "no_gpu" "models\no_gpu\Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"

rem ============================================================================
rem CHECK 11 - LAUNCHER SCRIPTS
rem ============================================================================
call :Progress "11" "Launcher and dashboard scripts"
call :CheckScripts

rem ============================================================================
rem CHECK 12 - PORT AVAILABILITY
rem ============================================================================
call :Progress "12" "Port 8080 availability"
call :CheckPort

rem ============================================================================
rem CHECK 13 - DISK SPACE
rem ============================================================================
call :Progress "13" "Free disk space"
call :CheckDisk

rem ============================================================================
rem CHECK 14 - POWERSHELL AVAILABILITY (for status.bat)
rem ============================================================================
call :Progress "14" "PowerShell availability"
call :CheckPowerShell

rem ============================================================================
rem FINAL SUMMARY
rem ============================================================================
call :DrawHeader "CHECK COMPLETE - SUMMARY"
echo.
echo   Passed  : %PASS%
echo   Warnings: %WARN%
echo   Failed  : %FAIL%
echo.
>>"%LOG%" echo.
>>"%LOG%" echo ============================================================================
>>"%LOG%" echo SUMMARY: Passed=%PASS%  Warnings=%WARN%  Failed=%FAIL%
>>"%LOG%" echo ============================================================================

if %FAIL% GTR 0 (
    echo ============================================================================
    echo   RESULT: SETUP INCOMPLETE
    echo ============================================================================
    echo.
    echo   %FAIL% requirement(s) failed. Review the messages above and follow
    echo   the guidance for each failed item.
    echo.
    echo   The full report is saved at:
    echo     %LOG%
    echo.
    echo   Re-run CLICK-ME.bat after fixing the issues.
    echo.
    pause
    goto :End
)

echo ============================================================================
echo   RESULT: SETUP COMPLETE
echo ============================================================================
echo.
echo   All required components are present.
echo.
echo   Full report: %LOG%
echo.
echo ============================================================================
echo   RECOMMENDED LAUNCHER
echo ============================================================================
echo.

rem ---- Recommend based on detected GPU/RAM ----
set "REC=start_no_gpu.bat"
set "REC_REASON=No usable NVIDIA GPU detected. CPU-only profile is safest."

rem Re-query GPU quickly
for /f "tokens=1,2 delims=," %%A in ('nvidia-smi --query-gpu=name,memory.total --format^=csv^,noheader,nounits 2^>nul') do (
    set "GPU_NAME=%%A"
    set "GPU_MEM=%%B"
)

if defined GPU_MEM (
    if !GPU_MEM! GEQ 7500 (
        set "REC=start_8gb_gpu.bat"
        set "REC_REASON=Detected !GPU_NAME! with !GPU_MEM! MiB VRAM. 8 GB profile recommended."
    ) else if !GPU_MEM! GEQ 5500 (
        set "REC=start_6gb_gpu.bat"
        set "REC_REASON=Detected !GPU_NAME! with !GPU_MEM! MiB VRAM. 6 GB profile recommended."
    ) else if !GPU_MEM! GEQ 3500 (
        set "REC=start_4gb_gpu.bat"
        set "REC_REASON=Detected !GPU_NAME! with !GPU_MEM! MiB VRAM. 4 GB profile recommended."
    ) else (
        set "REC=start_no_gpu.bat"
        set "REC_REASON=GPU VRAM is only !GPU_MEM! MiB. CPU-only profile is safer."
    )
)

echo   Recommended launcher : %REC%
echo   Reason               : %REC_REASON%
echo.
echo ============================================================================
echo   WHAT WOULD YOU LIKE TO DO?
echo ============================================================================
echo.
echo   [1] Launch the recommended launcher now (%REC%)
echo   [2] Launch a different launcher (menu)
echo   [3] Open the dashboard (status.bat) in a new window
echo   [4] Exit without launching
echo.
set /p "CHOICE=Enter your choice (1-4): "

if "%CHOICE%"=="1" goto :LaunchRecommended
if "%CHOICE%"=="2" goto :LaunchMenu
if "%CHOICE%"=="3" goto :LaunchDashboard
if "%CHOICE%"=="4" goto :End
echo Invalid choice. Exiting.
goto :End

:LaunchRecommended
echo.
echo Launching %REC% ...
start "" "%ROOT%%REC%"
goto :End

:LaunchMenu
cls
call :DrawHeader "SELECT A LAUNCHER"
echo.
echo   [1] start_4gb_gpu.bat   - 4 GB VRAM profile (Qwen3.5 2B Q8)
echo   [2] start_6gb_gpu.bat   - 6 GB VRAM profile (Qwen3.5 4B Q4)
echo   [3] start_8gb_gpu.bat   - 8 GB VRAM profile (Qwen3.5 9B Q4)
echo   [4] start_no_gpu.bat    - CPU-only profile (Qwen3.5 2B Q4)
echo   [5] Back to main menu
echo.
set /p "LCHOICE=Enter your choice (1-5): "
if "%LCHOICE%"=="1" start "" "%ROOT%start_4gb_gpu.bat" & goto :End
if "%LCHOICE%"=="2" start "" "%ROOT%start_6gb_gpu.bat" & goto :End
if "%LCHOICE%"=="3" start "" "%ROOT%start_8gb_gpu.bat" & goto :End
if "%LCHOICE%"=="4" start "" "%ROOT%start_no_gpu.bat" & goto :End
if "%LCHOICE%"=="5" goto :End
goto :LaunchMenu

:LaunchDashboard
echo.
echo Opening dashboard in a new window...
start "AI Pendrive Dashboard" cmd /k "%ROOT%status.bat"
goto :End

:End
popd >nul 2>&1
endlocal
exit /b 0

rem ============================================================================
rem SUBROUTINES
rem ============================================================================

:DrawHeader
echo.
echo ============================================================================
echo   %~1
echo ============================================================================
exit /b 0

:Progress
set /a CURRENT_CHECK=%~1
echo.
echo ----------------------------------------------------------------------------
echo   [%~1/%TOTAL_CHECKS%] Checking: %~2
echo ----------------------------------------------------------------------------
exit /b 0

:Pass
echo   [PASS] %~1
>>"%LOG%" echo [PASS] %~1
set /a PASS+=1
exit /b 0

:Warn
echo   [WARN] %~1
>>"%LOG%" echo [WARN] %~1
set /a WARN+=1
exit /b 0

:Fail
echo   [FAIL] %~1
>>"%LOG%" echo [FAIL] %~1
set /a FAIL+=1
exit /b 0

rem ---- Check Windows version ----
:CheckWindows
for /f "tokens=4-5 delims=. " %%A in ('ver') do (
    set "WIN_MAJOR=%%A"
    set "WIN_MINOR=%%B"
)
if "%WIN_MAJOR%"=="" (
    call :Warn "Could not determine Windows version."
    exit /b 0
)
if %WIN_MAJOR% GEQ 10 (
    call :Pass "Windows %WIN_MAJOR%.%WIN_MINOR% detected (Windows 10 or 11)."
) else (
    call :Warn "Windows %WIN_MAJOR%.%WIN_MINOR% detected. Windows 10 or 11 is recommended."
)
exit /b 0

rem ---- Check CPU cores ----
:CheckCPU
set "CPU_CORES=%NUMBER_OF_PROCESSORS%"
if not defined CPU_CORES (
    call :Warn "Could not read NUMBER_OF_PROCESSORS."
    exit /b 0
)
if %CPU_CORES% GEQ 4 (
    call :Pass "%CPU_CORES% logical processors detected."
) else (
    call :Warn "Only %CPU_CORES% logical processors detected. 4 or more recommended."
)
exit /b 0

rem ---- Check RAM ----
:CheckRAM
set "RAM_GB=0"
for /f "skip=1 tokens=*" %%A in ('wmic ComputerSystem get TotalPhysicalMemory 2^>nul') do (
    if not "%%A"=="" (
        set "RAM_BYTES=%%A"
        goto :GotRAM
    )
)
:GotRAM
if defined RAM_BYTES (
    set /a RAM_GB=!RAM_BYTES:~0,-6! / 1024
)
if %RAM_GB% GEQ 8 (
    call :Pass "Approximately %RAM_GB% GB system RAM detected."
) else if %RAM_GB% GEQ 4 (
    call :Warn "Only approximately %RAM_GB% GB RAM. 8 GB or more recommended."
) else (
    call :Fail "Only approximately %RAM_GB% GB RAM detected. At least 8 GB required."
)
exit /b 0

rem ---- Check NVIDIA GPU ----
:CheckGPU
set "GPU_FOUND=0"
for /f "tokens=1,2 delims=," %%A in ('nvidia-smi --query-gpu=name,memory.total --format^=csv^,noheader,nounits 2^>nul') do (
    set "GPU_NAME=%%A"
    set "GPU_MEM=%%B"
    set "GPU_FOUND=1"
)
if "%GPU_FOUND%"=="1" (
    call :Pass "NVIDIA GPU: %GPU_NAME% (%GPU_MEM% MiB VRAM)."
    >>"%LOG%" echo        GPU details: %GPU_NAME%, %GPU_MEM% MiB
) else (
    call :Warn "No NVIDIA GPU detected via nvidia-smi. GPU launchers will not work; use start_no_gpu.bat."
)
exit /b 0

rem ---- Check folder structure ----
:CheckFolders
set "MISSING=0"
for %%D in (models models\4GB models\6GB models\8GB models\no_gpu server) do (
    if not exist "%ROOT%%%D\" (
        echo   [FAIL] Missing folder: %%D
        >>"%LOG%" echo [FAIL] Missing folder: %%D
        set /a MISSING+=1
    )
)
if %MISSING%==0 (
    call :Pass "All required folders exist."
) else (
    set /a FAIL+=!MISSING!
    echo.
    echo   The script will create the missing folders for you now.
    echo.
    for %%D in (models models\4GB models\6GB models\8GB models\no_gpu server) do (
        if not exist "%ROOT%%%D\" (
            mkdir "%ROOT%%%D" >nul 2>&1
            echo   [FIXED] Created folder: %%D
        )
    )
)
exit /b 0

rem ---- Check llamafile runtime ----
:CheckLlamafile
set "LLAMA=%ROOT%server\llamafile-0.10.5.exe"
set "LLAMA_ALT=%ROOT%server\llamafile-0.10.5"
if exist "%LLAMA%" (
    for %%F in ("%LLAMA%") do set "LLAMA_SIZE=%%~zF"
    call :Pass "Llamafile runtime found: server\llamafile-0.10.5.exe (!LLAMA_SIZE! bytes)"
    exit /b 0
)
if exist "%LLAMA_ALT%" (
    call :Pass "Llamafile runtime found (extensionless): server\llamafile-0.10.5"
    exit /b 0
)
call :Fail "Llamafile runtime NOT found at server\llamafile-0.10.5.exe"
echo.
echo   ------------------------------------------------------------------------
echo   ACTION REQUIRED: Download the llamafile runtime
echo   ------------------------------------------------------------------------
echo.
echo   Do this now:
echo.
echo     1. Open this URL in your browser:
echo        https://github.com/mozilla-ai/llamafile/releases/tag/0.10.5
echo.
echo     2. Find the file named  llamafile-0.10.5  in the Assets list.
echo.
echo     3. Save it into this folder:
echo        %ROOT%server\
echo.
echo     4. Rename it to:  llamafile-0.10.5.exe
echo.
echo   ------------------------------------------------------------------------
:AskLlamafile
set /p "DONE=Have you downloaded and placed llamafile-0.10.5.exe in server\ ? (Y/N): "
if /i "%DONE%"=="Y" (
    if exist "%LLAMA%" (
        echo   [CONFIRMED] Llamafile found. Continuing.
        set /a FAIL-=1
        call :Pass "Llamafile runtime confirmed present."
        exit /b 0
    ) else (
        echo   [NOT FOUND] The file is still missing at:
        echo     %LLAMA%
        echo   Please complete the download first.
        goto :AskLlamafile
    )
)
if /i "%DONE%"=="N" (
    echo   Please complete the download before continuing.
    goto :AskLlamafile
)
echo   Please answer Y or N.
goto :AskLlamafile

rem ---- Check a model file ----
:CheckModel
set "TIER_NAME=%~1"
set "MODEL_REL=%~2"
set "MODEL_FULL=%ROOT%%MODEL_REL%"
if exist "%MODEL_FULL%" (
    for %%F in ("%MODEL_FULL%") do set "MODEL_SIZE=%%~zF"
    set /a MODEL_MB=!MODEL_SIZE! / 1048576
    call :Pass "Model found for %TIER_NAME% profile: !MODEL_MB! MB"
    exit /b 0
)
call :Fail "Model NOT found for %TIER_NAME% profile"
echo.
echo   ------------------------------------------------------------------------
echo   ACTION REQUIRED: Download the %TIER_NAME% model
echo   ------------------------------------------------------------------------
echo.
echo   Expected path:
echo     %MODEL_REL%
echo.
echo   Option A - Browser download:
if /i "%TIER_NAME%"=="4GB" (
    echo     https://huggingface.co/HauhauCS/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q8_0.gguf
)
if /i "%TIER_NAME%"=="6GB" (
    echo     https://huggingface.co/HauhauCS/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf
)
if /i "%TIER_NAME%"=="8GB" (
    echo     https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf
)
if /i "%TIER_NAME%"=="no_gpu" (
    echo     https://huggingface.co/HauhauCS/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf
)
echo.
echo   Option B - Hugging Face CLI (run from the project root):
if /i "%TIER_NAME%"=="4GB" (
    echo     hf download hf://HauhauCS/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q8_0.gguf --local-dir "models\4GB"
)
if /i "%TIER_NAME%"=="6GB" (
    echo     hf download hf://HauhauCS/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf --local-dir "models\6GB"
)
if /i "%TIER_NAME%"=="8GB" (
    echo     hf download hf://HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf --local-dir "models\8GB"
)
if /i "%TIER_NAME%"=="no_gpu" (
    echo     hf download hf://HauhauCS/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf --local-dir "models\no_gpu"
)
echo.
echo   ------------------------------------------------------------------------
echo.
echo   NOTE: This is a large download. You can skip it if you do not plan to
echo   use the %TIER_NAME% profile. But the matching launcher will refuse to
echo   start without it.
echo.
:AskModel
set /p "DONE=Have you downloaded and placed the %TIER_NAME% model? (Y/N/S to skip): "
if /i "%DONE%"=="Y" (
    if exist "%MODEL_FULL%" (
        echo   [CONFIRMED] Model found. Continuing.
        set /a FAIL-=1
        call :Pass "Model for %TIER_NAME% confirmed present."
        exit /b 0
    ) else (
        echo   [NOT FOUND] The file is still missing at:
        echo     %MODEL_FULL%
        echo   Please complete the download first.
        goto :AskModel
    )
)
if /i "%DONE%"=="N" (
    echo   Please complete the download before continuing.
    goto :AskModel
)
if /i "%DONE%"=="S" (
    echo   [SKIPPED] The %TIER_NAME% launcher will not work until this model is added.
    set /a FAIL-=1
    call :Warn "Skipped %TIER_NAME% model. Launcher for this tier will fail until added."
    exit /b 0
)
echo   Please answer Y, N, or S.
goto :AskModel

rem ---- Check scripts ----
:CheckScripts
set "MISSING_SCRIPTS=0"
for %%F in (start_4gb_gpu.bat start_6gb_gpu.bat start_8gb_gpu.bat start_no_gpu.bat status.bat readme.md) do (
    if not exist "%ROOT%%%F" (
        echo   [FAIL] Missing script: %%F
        >>"%LOG%" echo [FAIL] Missing script: %%F
        set /a MISSING_SCRIPTS+=1
    )
)
if %MISSING_SCRIPTS%==0 (
    call :Pass "All launcher and dashboard scripts present."
) else (
    set /a FAIL+=!MISSING_SCRIPTS!
    echo.
    echo   Re-extract or re-download the project to restore the missing scripts.
)
exit /b 0

rem ---- Check port 8080 ----
:CheckPort
set "PORT_BUSY=0"
for /f "tokens=*" %%A in ('netstat -ano ^| findstr /R /C:":8080 .*LISTENING"') do (
    set "PORT_BUSY=1"
)
if "%PORT_BUSY%"=="1" (
    call :Warn "Port 8080 is already in use. Stop the other program or edit PORT in the launcher."
    echo        Run this to see what is using it:
    echo          netstat -ano ^| findstr :8080
) else (
    call :Pass "Port 8080 is free."
)
exit /b 0

rem ---- Check disk space ----
:CheckDisk
set "FREE_MB=0"
for /f "tokens=3" %%A in ('dir /-c "%ROOT%." 2^>nul ^| findstr /R /C:"bytes free"') do (
    set "FREE_BYTES=%%A"
)
rem Fallback: use wmic
for /f "skip=1 tokens=*" %%A in ('wmic LogicalDisk where "DeviceID='%~d0'" get FreeSpace 2^>nul') do (
    if not "%%A"=="" set "FREE_BYTES=%%A"
)
if defined FREE_BYTES (
    set /a FREE_GB=!FREE_BYTES:~0,-6! / 1024
    if !FREE_GB! GEQ 10 (
        call :Pass "Approximately !FREE_GB! GB free on this drive."
    ) else if !FREE_GB! GEQ 3 (
        call :Warn "Only approximately !FREE_GB! GB free. Models may need more space."
    ) else (
        call :Fail "Only approximately !FREE_GB! GB free. At least 10 GB recommended."
    )
) else (
    call :Warn "Could not determine free disk space."
)
exit /b 0

rem ---- Check PowerShell ----
:CheckPowerShell
where powershell >nul 2>&1
if errorlevel 1 (
    call :Fail "PowerShell not found. status.bat and the browser watcher need it."
) else (
    for /f "tokens=*" %%A in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major" 2^>nul') do set "PS_VER=%%A"
    if defined PS_VER (
        call :Pass "PowerShell %PS_VER% detected."
    ) else (
        call :Warn "PowerShell found but version could not be read."
    )
)
exit /b 0
@echo off
setlocal

REM Define the directory to scan
set "directory=C:\Users\pd\Desktop\watch\SaleDataModExtracted"

REM Loop through all files in the directory and its subdirectories
for /r "%directory%" %%f in (*) do (
    REM Get the MD5 hash of the file using certutil
    certutil -hashfile "%%f" MD5 | findstr /v "certutil"
    
    REM Print the file path
    echo File: %%f
    echo ---------------------------
)

pause


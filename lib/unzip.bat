@echo off
setlocal

REM Define file paths
set "originalExcel=C:\Users\pd\Desktop\watch\largedocument.docx"
set "updatedExcel=C:\Users\pd\Desktop\watch\largedocumentcopy.docx"
set "zipOriginal=C:\Users\pd\Desktop\watch\SaleData.zip"
set "zipUpdated=C:\Users\pd\Desktop\watch\SaleDataMod.zip"
set "extractDirOriginal=C:\Users\pd\Desktop\watch\SaleDataExtracted"
set "extractDirUpdated=C:\Users\pd\Desktop\watch\SaleDataModExtracted"
set "compareTool=C:\path\to\compare\tool.exe"

REM Copy the original Excel files and change the extension to .zip
copy "%originalExcel%" "%zipOriginal%"
copy "%updatedExcel%" "%zipUpdated%"

REM Extract the ZIP files to temporary directories
echo Extracting ZIP archives...
powershell -command "Expand-Archive -Path '%zipOriginal%' -DestinationPath '%extractDirOriginal%'"
powershell -command "Expand-Archive -Path '%zipUpdated%' -DestinationPath '%extractDirUpdated%'"

REM Compare the contents of the extracted directories
echo Comparing extracted directories...
%compareTool% "%extractDirOriginal%" "%extractDirUpdated%"

REM Clean up
REM echo Cleaning up...
REM rmdir /s /q "%extractDirOriginal%"
REM rmdir /s /q "%extractDirUpdated%"

echo Done.
pause

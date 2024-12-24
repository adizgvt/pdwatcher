$WordFilePath = "C:\Users\user\Desktop\watch\New Microsoft Word Document.docx"

# Try to open the file with exclusive access to check if it's in use
try {
    $file = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    # If successful, the file is not in use
    $file.Close()
    Write-Host "The file is not in use."
} catch {
    # If an error occurs, the file is in use by another process
    Write-Host "The file is currently in use by another process."
}
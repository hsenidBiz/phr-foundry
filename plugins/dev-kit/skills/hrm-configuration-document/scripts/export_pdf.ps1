# Export a built configuration document .docx to PDF with Microsoft Word,
# refreshing the Table of Contents, List of Figures and page-number fields first.
# Usage: powershell -ExecutionPolicy Bypass -File export_pdf.ps1 -Docx "<path>.docx"
# Leaves any Word windows the user already has open untouched.
param([Parameter(Mandatory = $true)][string]$Docx)

$src = (Resolve-Path $Docx).Path
$pdf = [System.IO.Path]::ChangeExtension($src, ".pdf")
try {
    $word = New-Object -ComObject Word.Application -ErrorAction Stop
} catch {
    Write-Error "Microsoft Word is not available. Open the .docx in Word, update fields (Ctrl+A, F9) and Save As PDF manually."
    exit 1
}
$preexisting = $word.Documents.Count
$word.DisplayAlerts = 0
$doc = $null
try {
    $doc = $word.Documents.Open($src, $false, $false, $false)
    $doc.Fields.Update() | Out-Null
    foreach ($t in $doc.TablesOfContents) { $t.Update() }
    foreach ($f in $doc.TablesOfFigures) { $f.Update() }
    $doc.Save()                        # keep refreshed fields in the .docx
    $doc.ExportAsFixedFormat($pdf, 17) # 17 = wdExportFormatPDF
    Write-Output "PDF: $pdf"
}
catch {
    Write-Error "Export failed: $($_.Exception.Message). Is the .docx open in Word? Close it and retry."
    exit 1
}
finally {
    if ($doc) { $doc.Close(0) }
    if ($preexisting -eq 0 -and $word.Documents.Count -eq 0) { $word.Quit() }
}

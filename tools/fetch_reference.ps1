<#
.SYNOPSIS
    Fetches the reference texts for the Manifiesto fragments into reference\.

.DESCRIPTION
    The Manifiesto fragments are CONTENT: they are quotations from the 1605
    first part, not translations. That means the project needs the 1605 text,
    and - because DLC 1 is "El Segundo Libro (1615)" - it needs to be able to
    tell the two editions apart.

    Three files land in reference\ (which is gitignored: they are reference
    material, not sources):

      quijote_1605_parte1.txt     the 1605 first part, all 52 chapters, with
                                  the interpolated tales (the Novela del
                                  Curioso Impertinente is chapters
                                  XLVIII-LII, which is the numbering the
                                  Manifiesto fragments use).

                                  From Project Gutenberg #2000, which is the
                                  standard Spanish text of the 1605 first
                                  part - the same edition the Real Academia
                                  Española published in 1905. It carries the
                                  1605 wording: the incipit here reads
                                  "adarga antigua, rocin flaco y galgo
                                  corredor", NOT the 1615 "galera en coraza y
                                  bacia en el casco".

                                  THIS IS THE READING COPY AND THE COPY THE
                                  FRAGMENTS ARE QUOTED FROM.

      quijote_1615_parte2.txt     the 1615 second part and the Persiles. This
                                  is the book the world rewrites itself into,
                                  and it is DLC 1's material.

      quijote_1605_facsimil_ocr.txt
                                  OCR of the actual 1605 printing (Juan de
                                  Cuesta, Madrid, 1605) from the Internet
                                  Archive. NOISY: the long s and many other
                                  glyphs are misread, so it is a VARIANT
                                  reference, not a text to quote from. Use it
                                  to check a wording against the printing.

    Run from the repository root:
      powershell -ExecutionPolicy Bypass -File tools\fetch_reference.ps1

.NOTES
    *** THIS FILE IS ASCII ONLY, ON PURPOSE. ***

    Windows PowerShell 5.1 reads a .ps1 WITHOUT A BOM as Windows-1252, not
    as UTF-8. One accented character in a string literal or a regular
    expression is then silently mangled, and the script quietly matches
    nothing instead of failing. That is how this file lost an afternoon
    once already: a regex with an accented i matched zero chapters and the
    only symptom was an empty output file.

    So: no accents, no em dashes, no box drawing in this file. If you need
    one, use [char]0x00ED and friends, or give the file a UTF-8 BOM.

    WHY NOT WIKISOURCE? Its transcription of the 1905 edition loses the
    first letter of every word set in small capitals - about 190 lines, all
    of them the opening word of a paragraph. The information is gone from
    the source, so it cannot be repaired from the source. Project Gutenberg
    has the same edition, clean.

    The 1605 / 1615 difference is not academic. The 1605 incipit is:
      "...de los de lanza en astillero, adarga antigua, rocin flaco y galgo
       corredor."
    and the 1615 revision replaces that with:
      "...de los de lanza en astillero, galera en coraza y bacia en el casco."
    A fragment quoted from the wrong edition is a fragment from the wrong
    book.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$out = Join-Path $repo 'reference'
$enc = New-Object System.Text.UTF8Encoding($false)

$headers = @{ 'User-Agent' = 'FielAlLibro/0.1 (reference fetch; https://github.com/mariodod/fiel-al-libro)' }

New-Item -ItemType Directory -Force -Path $out | Out-Null


## Gutenberg hard-wraps its text at about seventy characters. Reading that
## is miserable and searching it is worse, because a phrase can straddle a
## line break. Join the wrapped lines back into paragraphs.
function Unwrap-Text([string]$text) {
    $lines = $text -split "`r?`n"
    $out = @()
    $buffer = ''
    foreach ($line in $lines) {
        $trimmed = $line.TrimEnd()
        if ($trimmed.Trim() -eq '') {
            if ($buffer) { $out += $buffer; $buffer = '' }
            continue
        }
        # A heading stands on its own.
        $isHeading = ($trimmed -match '^\s*(Cap.tulo|Parte|Parte [A-Z]|PARTE|PRIMERA|SEGUNDA|TERCERA|Aparte|Del |De la |De los |De las )')
        if ($isHeading -and $buffer) { $out += $buffer; $buffer = '' }
        if ($buffer) { $buffer += ' ' }
        $buffer += $trimmed.Trim()
        if ($isHeading) { $out += $buffer; $buffer = '' }
    }
    if ($buffer) { $out += $buffer }
    return ($out -join "`n")
}


# -- 1. Project Gutenberg: the whole novel ---------------------------------
Write-Host "[fetch] Project Gutenberg #2000, Don Quijote (Spanish)..."
$gutenberg = 'https://www.gutenberg.org/cache/epub/2000/pg2000.txt'
$raw = (Invoke-WebRequest -Uri $gutenberg -UseBasicParsing -Headers $headers).Content
$raw = $raw -replace "`r`n", "`n"

# Project Gutenberg's licence header and footer are not the book.
#
# The book's own part titles are NOT reliable boundaries: the printed text
# carries running heads, and "parte del ingenioso hidalgo don Quijote de la
# Mancha" turns up all over the place. The two boundaries that ARE unique
# are the first chapter and the famous closing line of the first part.
$start = $raw.IndexOf('Primera parte del ingenioso hidalgo')
$endPart1 = $raw.IndexOf('Dejamos en la primera parte')
$end = $raw.IndexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
if ($start -lt 0) { Write-Error "Could not find the start of the first part."; exit 1 }
if ($endPart1 -lt 0) { Write-Error "Could not find the end of the first part."; exit 1 }
if ($end -lt 0) { $end = $raw.Length }

# The second part starts at the 1615 TASA - "Yo, Hernando de Vallejo,
# escribano de Camara del Rey nuestro senor" - which is the only place in
# the book where the second volume announces itself as a new volume.
$startPart2 = $raw.IndexOf('Hernando de Vallejo')
if ($startPart2 -lt 0) { Write-Error "Could not find the start of the second part."; exit 1 }
# And it starts a few hundred characters earlier, at the volume's title page.
$volumeTitle = $raw.LastIndexOf('Segunda parte del ingenioso', $startPart2)
if ($volumeTitle -gt $endPart1) { $startPart2 = $volumeTitle }

$part1 = Unwrap-Text $raw.Substring($start, $startPart2 - $start)
$part2 = Unwrap-Text $raw.Substring($startPart2, $end - $startPart2)

[System.IO.File]::WriteAllText((Join-Path $out 'quijote_1605_parte1.txt'), $part1, $enc)
[System.IO.File]::WriteAllText((Join-Path $out 'quijote_1615_parte2.txt'), $part2, $enc)
Write-Host ("[fetch] wrote parte1 ({0} chars), parte2 ({1} chars)" -f $part1.Length, $part2.Length)

# -- 2. The 1605 printing itself (OCR) -------------------------------------
Write-Host "[fetch] 1605 printing, OCR from the Internet Archive..."
$facsimile = 'https://archive.org/download/elingeniosohi00cerv/elingeniosohi00cerv_djvu.txt'
try {
    $response = Invoke-WebRequest -Uri $facsimile -UseBasicParsing -Headers $headers
    [System.IO.File]::WriteAllText((Join-Path $out 'quijote_1605_facsimil_ocr.txt'), $response.Content, $enc)
    Write-Host ("[fetch] wrote quijote_1605_facsimil_ocr.txt ({0} chars)" -f $response.Content.Length)
} catch {
    Write-Warning "[fetch] could not fetch the facsimile OCR: $_"
}

# -- Report -----------------------------------------------------------------
Write-Host ""
Write-Host "[fetch] done. Which edition is where?"
foreach ($file in @('quijote_1605_parte1.txt', 'quijote_1615_parte2.txt', 'quijote_1605_facsimil_ocr.txt')) {
    $path = Join-Path $out $file
    if (-not (Test-Path $path)) { continue }
    $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $w1605 = if ($text -match 'adarga antigua') { 'yes' } else { 'no ' }
    $w1615 = if ($text -match 'galera en coraza') { 'yes' } else { 'no ' }
    $curioso = if ($text -match 'Curioso Impertinente') { 'yes' } else { 'no ' }
    Write-Host ("  {0}: 1605 wording={1}  1615 wording={2}  1605 structure={3}" -f $file, $w1605, $w1615, $curioso)
}
Write-Host ""
Write-Host "[fetch] reference\ is gitignored: these are reference texts, not sources."
exit 0

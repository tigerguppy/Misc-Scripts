function Convert-ChromeBookmarksToHtml {
    <#
    .SYNOPSIS
        Converts a Chrome Bookmarks JSON file to HTML (Netscape format) for browser import.
    .PARAMETER JsonPath
        Path to the Chrome Bookmarks JSON file.
    .PARAMETER OutputPath
        Path to save the resulting HTML file.
    .EXAMPLE
        Convert-ChromeBookmarksToHtml -JsonPath "chrome-bookmarks.json" -OutputPath "bookmarks.html"
    .NOTES
        Bookmark file can be found here: C:\Users\<username>\AppData\Local\Google\Chrome\User Data\Default\
        Additional profiles can be found here: C:\Users\<username>\AppData\Local\Google\Chrome\User Data\Profile 1\
        Subsiquent profiles will increment the Profile number.
        The bookmark file is named Bookmarks (no extension)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    function Write-BookmarkHtml {
        param (
            [Parameter(Mandatory = $true)]$Bookmark,
            [Parameter(Mandatory = $true)]$Writer,
            [int]$Indent = 2
        )
        $pad = ' ' * $Indent
        if ($Bookmark.children) {
            $name = $Bookmark.name
            if (-not $name) { $name = 'Bookmarks' }
            $Writer.WriteLine("$pad<DT><H3>$name</H3>")
            $Writer.WriteLine("$pad<DL><p>")
            foreach ($child in $Bookmark.children) {
                Write-BookmarkHtml -Bookmark $child -Writer $Writer -Indent ($Indent + 2)
            }
            $Writer.WriteLine("$pad</DL><p>")
        } elseif ($Bookmark.url) {
            $name = $Bookmark.name
            if (-not $name) { $name = $Bookmark.url }
            $Writer.WriteLine("$pad<DT><A HREF=""$($Bookmark.url)"">$name</A>")
        }
    }

    # Read and parse JSON
    $jsonRaw = Get-Content -Path $JsonPath -Raw
    $bookmarks = $null
    try {
        $bookmarks = $jsonRaw | ConvertFrom-Json
    } catch {
        Write-Error 'Error parsing JSON. Make sure the file is valid.'
        return
    }

    # Open output file
    $Writer = New-Object System.IO.StreamWriter($OutputPath, $false, [System.Text.Encoding]::UTF8)
    $Writer.WriteLine('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
    $Writer.WriteLine('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
    $Writer.WriteLine('<TITLE>Bookmarks</TITLE>')
    $Writer.WriteLine('<H1>Bookmarks</H1>')
    $Writer.WriteLine('<DL><p>')

    # Write each main root
    foreach ($Root in @('bookmark_bar', 'other', 'synced')) {
        if ($bookmarks.roots.$Root) {
            Write-BookmarkHtml -Bookmark $bookmarks.roots.$Root -Writer $Writer -Indent 2
        }
    }

    $Writer.WriteLine('</DL><p>')
    $Writer.Close()
    Write-Host "Conversion complete. Output: $OutputPath"
}

function Convert-ChromeBookmarksToHtmlGui {
    <#
    .SYNOPSIS
        Prompts user with file dialogs to select a Chrome Bookmarks JSON file and output HTML path.
    .DESCRIPTION
        Uses Windows Forms dialogs for file selection. Calls Convert-ChromeBookmarksToHtml.
    .EXAMPLE
        Convert-ChromeBookmarksToHtmlGui
    #>
    
    Add-Type -AssemblyName System.Windows.Forms

    # Open File Dialog for selecting the Chrome Bookmarks JSON file
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = 'Select Chrome Bookmarks JSON file'
    $openFileDialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
    $openFileDialog.FileName = 'Bookmarks'

    if ($openFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host 'Operation cancelled.'
        return
    }
    $jsonPath = $openFileDialog.FileName

    # Save File Dialog for output HTML
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = 'Save Bookmarks HTML file as'
    $saveFileDialog.Filter = 'HTML files (*.html)|*.html|All files (*.*)|*.*'
    $saveFileDialog.FileName = 'bookmarks.html'
    if ($saveFileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host 'Operation cancelled.'
        return
    }
    $outputPath = $saveFileDialog.FileName

    # Call the main function
    Convert-ChromeBookmarksToHtml -JsonPath $jsonPath -OutputPath $outputPath
}

Convert-ChromeBookmarksToHtmlGui

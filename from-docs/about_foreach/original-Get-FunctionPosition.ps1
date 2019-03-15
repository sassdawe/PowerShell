
# source https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_foreach?view=powershell-5.1

function Get-FunctionPosition {
    [CmdletBinding()]
    [OutputType('FunctionPosition')]
    param(
        [Parameter(Position = 0, Mandatory,
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [System.String[]]
        $Path
    )

    process {
        try {
            $filesToProcess = if ($_ -is [System.IO.FileSystemInfo]) {
                $_
            }
            else {
                $filesToProcess = Get-Item -Path $Path
            }
            $parser = [System.Management.Automation.Language.Parser]
            foreach ($item in $filesToProcess) {
                if ($item.PSIsContainer -or
                    $item.Extension -notin @('.ps1', '.psm1')) {
                    continue
                }
                $tokens = $errors = $null
                $ast = $parser::ParseFile($item.FullName, ([REF]$tokens),
                    ([REF]$errors))
                if ($errors) {
                    $msg = "File '{0}' has {1} parser errors." -f $item.FullName,
                    $errors.Count
                    Write-Warning $msg
                }
                :tokenLoop foreach ($token in $tokens) {
                    if ($token.Kind -ne 'Function') {
                        continue
                    }
                    $position = $token.Extent.StartLineNumber
                    do {
                        if (-not $foreach.MoveNext()) {
                            break tokenLoop
                        }
                        $token = $foreach.Current
                    } until ($token.Kind -in @('Generic', 'Identifier'))
                    $functionPosition = [pscustomobject]@{
                        Name       = $token.Text
                        LineNumber = $position
                        Path       = $item.FullName
                    }
                    Add-Member -InputObject $functionPosition `
                        -TypeName FunctionPosition -PassThru
                }
            }
        }
        catch {
            throw
        }
    }
}
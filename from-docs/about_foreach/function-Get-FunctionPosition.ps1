
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
                Write-Verbose "From pipeline"
                $_
            }
            else {
                Write-Verbose "From parameter, $Path"
                Get-Item -Path $Path
            }
            $parser = [System.Management.Automation.Language.Parser]
            Write-Verbose "lets start the foreach loop on `$filesToProcess with $($filesToProcess.count) as count"
            foreach ($item in $filesToProcess) {
                Write-Verbose "in the loop"
                Write-Verbose "$item"
                if ($item.PSIsContainer -or
                    $item.Extension -notin @('.ps1', '.psm1')) {
                    continue
                }
                $tokens = $errors = $null
                $parser::ParseFile($item.FullName, ([REF]$tokens),
                    ([REF]$errors)) | Out-Null
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


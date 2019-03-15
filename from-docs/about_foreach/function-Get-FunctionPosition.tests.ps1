

$currentFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$testName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$functionFile = $testName.Replace(".tests.",".")

$functionName = ((($testName.Split("-") | Select-Object -Skip 1 ) -join "-").Split("."))[0]


Describe "Main Test of $functionName" -Fixture {
    Context "Script file validation" -Fixture {
        It "$functionFile should exist" -test {
            "$currentFolder\$functionFile" | Should -Exist
        }
        It "$functionFile should contain the $functionName function" -test {
            "$currentFolder\$functionFile" | Should -FileContentMatch "function $functionName"
        }
        It "$functionFile should contain an advanced function" -test {
            "$currentFolder\$functionFile" | Should -FileContentMatch "CmdletBinding()"
        }
    }

    Context "Functional tests" {

        . "$currentFolder\$functionFile"
        It "$functionName should return something" {
            $result = Invoke-Expression "$functionName $currentFolder\$functionFile"
            $result.Name | Should -Be $functionName
            $result.LineNumber | Should -Be 1
            $result.Path | Should -Be "$currentFolder\$functionFile"
        }
        It "$functionName should return something with multiple inputs" {
            $result = Invoke-Expression "$functionName $currentFolder\$functionFile,$currentFolder\$functionFile"
            $result[0].Name | Should -Be $functionName
            $result[0].LineNumber | Should -Be 1
            $result[0].Path | Should -Be "$currentFolder\$functionFile"
            $result[1].Name | Should -Be $functionName
            $result[1].LineNumber | Should -Be 1
            $result[1].Path | Should -Be "$currentFolder\$functionFile"
        }
    }
}
 $baseUri = 'https://github.com/PowerShell/PowerShell/releases/download'
    $files = @(
        @{
            Uri = "$baseUri/v7.3.0-preview.5/PowerShell-7.3.0-preview.5-win-x64.msi"
            OutFile = 'PowerShell-7.3.0-preview.5-win-x64.msi'
        },
        @{
            Uri = "$baseUri/v7.3.0-preview.5/PowerShell-7.3.0-preview.5-win-x64.zip"
            OutFile = 'PowerShell-7.3.0-preview.5-win-x64.zip'
        },
        @{
            Uri = "$baseUri/v7.2.5/PowerShell-7.2.5-win-x64.msi"
            OutFile = 'PowerShell-7.2.5-win-x64.msi'
        },
        @{
            Uri = "$baseUri/v7.2.5/PowerShell-7.2.5-win-x64.zip"
            OutFile = 'PowerShell-7.2.5-win-x64.zip'
        }
    )

    $jobs = @()

    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            Invoke-WebRequest @params
        }
    }

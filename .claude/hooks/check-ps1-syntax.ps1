$raw = [Console]::In.ReadToEnd()
$json = $raw | ConvertFrom-Json
$f = $json.tool_input.file_path
if (-not ($f -and $f -match '\.ps1$')) { exit 0 }

# Syntax check (blocking)
try {
    [void][scriptblock]::Create([IO.File]::ReadAllText($f))
} catch {
    @{ systemMessage = "PS1 syntax error: $($_.Exception.Message)" } | ConvertTo-Json -Compress
    exit 1
}

# PSScriptAnalyzer (informational, never blocks)
$exclude = @(
    'PSReviewUnusedParameter',
    'PSUseShouldProcessForStateChangingFunctions',
    'PSUseBOMForUnicodeEncodedFile',
    'PSAvoidAssignmentToAutomaticVariable'  # event handler params like $sender
)
$issues = Invoke-ScriptAnalyzer -Path $f -Severity Error,Warning -ExcludeRule $exclude 2>$null
if ($issues) {
    $lines = $issues | ForEach-Object { "  Line $($_.Line): [$($_.Severity)] $($_.Message)" }
    $msg = "PSScriptAnalyzer ($($issues.Count) issue(s)):`n" + ($lines -join "`n")
    @{ systemMessage = $msg } | ConvertTo-Json -Compress
}

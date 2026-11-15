#!/usr/bin/env pwsh
# Safety Gate Hook - PreToolUse
# Megvédi a rendszert veszélyes parancsok automatikus végrehajtásától

$input_json = $input | ConvertFrom-Json
$tool_name = $input_json.toolCall.name
$args = $input_json.toolCall.args

# Veszélyes parancs minták
$DANGEROUS_PATTERNS = @(
    'rm\s+-rf',
    'Remove-Item.*-Recurse.*-Force',
    'format\s+[a-zA-Z]:',
    'del\s+/[sS]',
    'DROP\s+TABLE',
    'DROP\s+DATABASE',
    'TRUNCATE\s+TABLE',
    '--no-backup',
    'git\s+push\s+.*--force(?!\s*-with-lease)',
    'curl.*\|\s*(sh|bash|pwsh)',
    'Invoke-Expression.*\(.*Invoke-WebRequest',
    'iex\s+\('
)

# Gyanús hálózati minták (exfiltráció jelei)
$SUSPICIOUS_NETWORK = @(
    '0\.0\.0\.0',
    'ngrok',
    'requestbin',
    'webhook\.site',
    'burpcollaborator'
)

$command_line = ""
if ($args.CommandLine) {
    $command_line = $args.CommandLine
} elseif ($args.command) {
    $command_line = $args.command
}

# Ellenőrzés
foreach ($pattern in $DANGEROUS_PATTERNS) {
    if ($command_line -match $pattern) {
        @{
            decision = "ask"
            reason = "⚠️ SAFETY GATE: Veszélyes mintát detektáltam a parancsban: '$pattern'. Kérlek erősítsd meg, hogy valóban ezt szeretnéd futtatni."
        } | ConvertTo-Json
        exit 0
    }
}

foreach ($pattern in $SUSPICIOUS_NETWORK) {
    if ($command_line -match $pattern) {
        @{
            decision = "ask"
            reason = "⚠️ SAFETY GATE: Gyanús hálózati célpontot detektáltam: '$pattern'. Megerősítés szükséges."
        } | ConvertTo-Json
        exit 0
    }
}

# Biztonságos - engedélyezés
@{
    decision = "allow"
} | ConvertTo-Json

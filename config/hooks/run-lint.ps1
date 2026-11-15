#!/usr/bin/env pwsh
# Lint + Syntax Check Hook - PostToolUse (write_file / edit_file után)
# Automatikus visszacsatolás az ágensnek

$input_json = $input | ConvertFrom-Json
$tool_name = $input_json.toolCall.name
$args = $input_json.toolCall.args

$file_path = ""
if ($args.Path) { $file_path = $args.Path }

if (-not $file_path -or -not (Test-Path $file_path)) {
    @{} | ConvertTo-Json
    exit 0
}

$ext = [System.IO.Path]::GetExtension($file_path).ToLower()
$issues = @()

switch ($ext) {
    ".py" {
        # Python syntax check
        $result = python -c "import ast, sys; ast.parse(open('$file_path').read())" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $issues += "Python szintaxis hiba: $result"
        }
    }
    ".js" {
        # Node.js syntax check
        if (Get-Command node -ErrorAction SilentlyContinue) {
            $result = node --check $file_path 2>&1
            if ($LASTEXITCODE -ne 0) {
                $issues += "JavaScript szintaxis hiba: $result"
            }
        }
    }
    ".ts" {
        # TypeScript check (ha elérhető)
        if (Get-Command tsc -ErrorAction SilentlyContinue) {
            $result = tsc --noEmit $file_path 2>&1
            if ($LASTEXITCODE -ne 0) {
                $issues += "TypeScript hiba: $result"
            }
        }
    }
    ".json" {
        # JSON validáció
        try {
            Get-Content $file_path | ConvertFrom-Json | Out-Null
        } catch {
            $issues += "JSON szintaxis hiba: $_"
        }
    }
    ".ps1" {
        # PowerShell szintaxis ellenőrzés
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file_path, [ref]$null, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) {
            $issues += "PowerShell szintaxis hiba: $($errors | Select-Object -First 3 | ForEach-Object { $_.Message })"
        }
    }
}

# Visszajelzés (PostToolUse-ban csak üres {} kell)
@{} | ConvertTo-Json

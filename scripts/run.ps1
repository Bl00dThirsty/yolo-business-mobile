param(
  [ValidateSet('live','demo')][string]$Mode = 'live',
  [string]$Device = 'chrome'
)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  if ($Mode -eq 'demo') { flutter run -d $Device --dart-define=DEMO=true }
  else {
    if (-not (Test-Path -LiteralPath 'config/local.json')) {
      throw 'Copiez config/example.json vers config/local.json et renseignez la configuration publique Supabase.'
    }
    flutter run -d $Device --dart-define-from-file=config/local.json
  }
} finally { Pop-Location }

param(
    [Parameter(Mandatory = $true)] [string] $WebConfigPath,
    [string] $OutputPath = 'firebase_config.json'
)
$ErrorActionPreference = 'Stop'
$config = Get-Content -Raw -LiteralPath $WebConfigPath | ConvertFrom-Json
$required = @('apiKey', 'appId', 'messagingSenderId', 'projectId', 'storageBucket', 'authDomain')
foreach ($key in $required) {
    if ([string]::IsNullOrWhiteSpace($config.$key)) {
        throw "Missing $key. Provide JSON containing the Web app firebaseConfig from your Firebase Console."
    }
}
if ($config.projectId.StartsWith('demo-')) {
    throw 'demo-* IDs are reserved for Emulator use, not real Cloud deployment.'
}
if ($config.appId -notmatch ':web:') {
    throw 'This script expects a Firebase WEB application configuration.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent -and !(Test-Path -LiteralPath $parent -PathType Container)) {
    throw "Output directory does not exist: $parent"
}
if (Test-Path -LiteralPath $OutputPath) {
    throw "$OutputPath already exists. Select another OutputPath or review and replace it manually."
}
[ordered]@{
    FIREBASE_API_KEY = $config.apiKey
    FIREBASE_APP_ID = $config.appId
    FIREBASE_MESSAGING_SENDER_ID = $config.messagingSenderId
    FIREBASE_PROJECT_ID = $config.projectId
    FIREBASE_STORAGE_BUCKET = $config.storageBucket
    FIREBASE_AUTH_DOMAIN = $config.authDomain
    GOOGLE_SERVER_CLIENT_ID = ''
} | ConvertTo-Json | Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM
"Created $OutputPath for project $($config.projectId)."
'Review Google Auth, Firestore, Storage billing and Security Rules in YOUR project before running the demo.'
"flutter run -d chrome --web-port=7357 --dart-define-from-file=$OutputPath"

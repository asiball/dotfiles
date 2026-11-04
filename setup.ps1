#!/usr/bin/env pwsh
# Windows 用。home/claude/ を ~/.claude に symlink で展開し、settings.shared.json を settings.json に合成する。
# 対象は Claude Code の設定だけ(シェル・tmux・パッケージは Windows では扱わない)。Unix 側は setup.sh。
#   pwsh -File setup.ps1 install   展開する(既存ファイルは <元のパス>.backup.<時刻> に退避。symlink の作成には開発者モードが必要)
#   pwsh -File setup.ps1 status    各ファイルが repo を指しているか
param([ValidateSet('install', 'status', 'help')][string]$Command = 'help')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)   # node の出力(日本語を含む)を正しく受け取る

$Pkg = Join-Path $PSScriptRoot 'home\claude'
$Ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backups = @()

function Pkg-Files { Get-ChildItem $Pkg -Recurse -File | ForEach-Object { $_.FullName.Substring($Pkg.Length + 1) } }
function Linked($rel) {
    $item = Get-Item (Join-Path $HOME $rel) -Force -ErrorAction SilentlyContinue
    $item -and $item.LinkType -eq 'SymbolicLink' -and (@($item.Target) -contains (Join-Path $Pkg $rel))
}
function Backup($path) {
    Move-Item $path "$path.backup.$Ts"
    $script:Backups += $path
    Write-Host "  退避: $path -> $path.backup.$Ts"
}

function Install-Claude {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host 'node が必要です(statusline.mjs と settings の合成に使う)'; exit 1 }
    Write-Host 'これから行うこと:'
    Write-Host "  - ~/.claude に symlink: $((Pkg-Files) -join ', ')"
    Write-Host "    衝突する既存ファイルは <元のパス>.backup.$Ts に退避"
    Write-Host '  - settings.shared.json を ~/.claude/settings.json に合成(node。変更時は退避)'
    $ans = Read-Host '続行しますか? [y/N]'
    if ($ans -notmatch '^[Yy]$') { Write-Host '中止しました'; exit 1 }

    foreach ($rel in Pkg-Files) {
        if (Linked $rel) { continue }
        $target = Join-Path $HOME $rel
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        if (Get-Item $target -Force -ErrorAction SilentlyContinue) { Backup $target }
        try {
            New-Item -ItemType SymbolicLink -Path $target -Target (Join-Path $Pkg $rel) | Out-Null
        } catch {
            Write-Host "symlink を作れませんでした: $target"
            Write-Host '  設定 > システム > 開発者向け で開発者モードを有効にするか、管理者の PowerShell で実行してください'
            exit 1
        }
    }
    Write-Host '  ~/.claude に展開しました'

    # settings.shared.json を合成する。tmux 連携の hooks(settings.shared.tmux.json)は tmux があるときだけ
    $dir = Join-Path $HOME '.claude'
    $settings = Join-Path $dir 'settings.json'
    $shared = @((Join-Path $dir 'settings.shared.json'))
    if (Get-Command tmux -ErrorAction SilentlyContinue) { $shared += Join-Path $dir 'settings.shared.tmux.json' }
    $merged = (& node (Join-Path $dir 'merge-settings.mjs') $settings @shared) -join "`n"
    if (Test-Path $settings) {
        if ($merged -eq ((& node (Join-Path $dir 'merge-settings.mjs') $settings) -join "`n")) { return }
        Backup $settings
    }
    [IO.File]::WriteAllText($settings, $merged + "`n")
    Write-Host "  ~/.claude/settings.json に $(($shared | Split-Path -Leaf) -join ', ') を合成しました"
}

function Show-Status {
    $ok = 0; $files = @(Pkg-Files)
    foreach ($rel in $files) {
        if (Linked $rel) { Write-Host "  OK   $rel"; $ok++ }
        elseif (Get-Item (Join-Path $HOME $rel) -Force -ErrorAction SilentlyContinue) { Write-Host "  WARN $rel (存在するが repo を指していない)" }
        else { Write-Host "  --   $rel (未展開)" }
    }
    Write-Host "  同期: $ok/$($files.Count)"
}

switch ($Command) {
    'install' {
        Install-Claude
        Write-Host ''; Write-Host '==== セットアップ完了 ===='
        if ($Backups.Count -gt 0) {
            Write-Host "既存ファイルを退避しました($($Backups.Count) 件。戻すには Move-Item <退避先> <元のパス>):"
            $Backups | ForEach-Object { Write-Host "  $_ -> $_.backup.$Ts" }
        } else { Write-Host '退避したファイルはありません' }
        Show-Status
    }
    'status' { Show-Status }
    default { Get-Content $PSCommandPath -TotalCount 5 | Select-Object -Skip 1 | ForEach-Object { $_ -replace '^# ?', '' } }
}

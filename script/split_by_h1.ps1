# split_by_h1.ps1 — 按一级标题（# Title）切分 Markdown 文件（PowerShell 版）
#
# 用法：
#   .\split_by_h1.ps1 -InputPath <输入文件路径（相对于本脚本的路径）>
#   .\split_by_h1.ps1 ..\agents\Eigen_zh.agent.md
#
# 编码：UTF-8（BOM-less）
# 兼容：PowerShell 5.1+ / PowerShell 7+

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------- 工具函数 ----------

function Sanitize-Filename {
    param([string]$Name)
    # 替换 Windows 文件名非法字符
    $illegal = '[<>:"/\\|?*\x00-\x1f]'
    $safe = [regex]::Replace($Name.Trim(), $illegal, '_')
    return $safe.Trim('.').Trim()
}

# ---------- 路径解析 ----------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AbsInput  = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir $InputPath))

if (-not (Test-Path $AbsInput -PathType Leaf)) {
    Write-Error "找不到文件：$AbsInput"
    exit 1
}

$BaseName  = [System.IO.Path]::GetFileNameWithoutExtension($AbsInput)
$InputDir  = Split-Path -Parent $AbsInput
$OutputDir = Join-Path $InputDir $BaseName

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# ---------- 读取文件（UTF-8） ----------

$lines = [System.IO.File]::ReadAllLines($AbsInput, [System.Text.Encoding]::UTF8)

# ---------- 核心切分逻辑 ----------

$preamble      = [System.Text.StringBuilder]::new()
$currentHeading = $null
$currentBody    = [System.Text.StringBuilder]::new()
$sectionCount   = 0
$inPreamble     = $true

function Write-Section {
    param([string]$OutDir, [string]$Heading, [string]$Body, [int]$Index)

    $titleText = $Heading.Substring(2).Trim()   # 去掉 "# "
    $filename  = Sanitize-Filename $titleText

    # 若标题不含扩展名，则补充 .md
    if ([System.IO.Path]::GetExtension($filename) -eq '') {
        $filename = "$filename.md"
    }

    $outPath = Join-Path $OutDir $filename

    # 防止同名冲突：加序号
    if (Test-Path $outPath) {
        $nameOnly = [System.IO.Path]::GetFileNameWithoutExtension($filename)
        $ext      = [System.IO.Path]::GetExtension($filename)
        $filename = "${nameOnly}_${Index}${ext}"
        $outPath  = Join-Path $OutDir $filename
    }

    $content = "$Heading`n$Body"
    [System.IO.File]::WriteAllText($outPath, $content, [System.Text.Encoding]::UTF8)
    Write-Host "已写入：$outPath"
}

foreach ($line in $lines) {
    if ($line -match '^# .+') {
        if ($inPreamble) {
            $preText = $preamble.ToString()
            if ($preText.Trim().Length -gt 0) {
                $prePath = Join-Path $OutputDir '_preamble.md'
                [System.IO.File]::WriteAllText($prePath, $preText, [System.Text.Encoding]::UTF8)
                Write-Host "已写入：$prePath"
            }
            $inPreamble = $false
        } else {
            if ($null -ne $currentHeading) {
                $sectionCount++
                Write-Section -OutDir $OutputDir -Heading $currentHeading -Body $currentBody.ToString() -Index $sectionCount
                $currentBody = [System.Text.StringBuilder]::new()
            }
        }
        $currentHeading = $line
    } else {
        if ($inPreamble) {
            [void]$preamble.AppendLine($line)
        } else {
            [void]$currentBody.AppendLine($line)
        }
    }
}

# 写入最后一个片段
if ($null -ne $currentHeading) {
    $sectionCount++
    Write-Section -OutDir $OutputDir -Heading $currentHeading -Body $currentBody.ToString() -Index $sectionCount
}

# 处理全文无 H1 的情况（也保存 preamble）
if ($inPreamble) {
    $preText = $preamble.ToString()
    if ($preText.Trim().Length -gt 0) {
        $prePath = Join-Path $OutputDir '_preamble.md'
        [System.IO.File]::WriteAllText($prePath, $preText, [System.Text.Encoding]::UTF8)
        Write-Host "已写入：$prePath"
    }
}

Write-Host "`n完成。共输出 $sectionCount 个片段到目录：$OutputDir"

#!/usr/bin/env zsh
# fast_paste.zsh — 按一级标题（# Title）切分 Markdown 文件（macOS / zsh 版）
#
# 用法：
#   zsh fast_paste.zsh <输入文件路径（相对于本脚本的路径）>
#
# 示例：
#   zsh fast_paste.zsh ../agents/Eigen_zh.agent.md
#
# 依赖：macOS 内建的 zsh + awk（macOS 自带 nawk/gawk 均可）
# 编码：UTF-8（确保终端 LC_ALL 已包含 UTF-8，如 en_US.UTF-8）

set -euo pipefail

# ---------- 工具函数 ----------

die() { print -u2 "错误：$*"; exit 1 }

# macOS realpath 命令在旧版中不存在，用 Python 回退
resolve_path() {
    local base="$1" rel="$2"
    if command -v realpath &>/dev/null; then
        realpath -m -- "$base/$rel" 2>/dev/null || \
            python3 -c "import os; print(os.path.normpath(os.path.join('$base','$rel')))"
    else
        python3 -c "import os; print(os.path.normpath(os.path.join('$base','$rel')))"
    fi
}

# ---------- 参数检查 ----------

if [[ $# -ne 1 ]]; then
    print "用法：zsh fast_paste.zsh <输入文件路径（相对于本脚本）>"
    print "示例：zsh fast_paste.zsh ../agents/Eigen_zh.agent.md"
    exit 1
fi

SCRIPT_DIR="${0:A:h}"
INPUT_REL="$1"
INPUT_ABS="$(resolve_path "$SCRIPT_DIR" "$INPUT_REL")"

[[ -f "$INPUT_ABS" ]] || die "找不到文件 \"$INPUT_ABS\""

BASE_NAME="${INPUT_ABS:t}"         # 文件名（含扩展名）
NO_EXT="${BASE_NAME:r}"            # 去掉扩展名
DIR_NAME="${INPUT_ABS:h}"          # 所在目录
OUTPUT_DIR="$DIR_NAME/$NO_EXT"

mkdir -p "$OUTPUT_DIR"

# ---------- 核心切分逻辑（awk） ----------
# macOS 默认 awk 为 nawk，兼容性写法

awk -v outdir="$OUTPUT_DIR" '
BEGIN {
    section   = 0
    preamble  = ""
    heading   = ""
    body      = ""
    in_preamble = 1
}

/^# / {
    if (in_preamble) {
        if (length(preamble) > 0) {
            fname = outdir "/_preamble.md"
            printf "%s", preamble > fname
            close(fname)
            print "已写入：" fname
        }
        in_preamble = 0
    } else {
        if (length(heading) > 0) {
            write_section(outdir, heading, body, section)
        }
    }
    section++
    heading = $0
    body    = ""
    next
}

{
    if (in_preamble) {
        preamble = preamble $0 "\n"
    } else {
        body = body $0 "\n"
    }
}

END {
    if (in_preamble && length(preamble) > 0) {
        fname = outdir "/_preamble.md"
        printf "%s", preamble > fname
        close(fname)
        print "已写入：" fname
    }
    if (length(heading) > 0) {
        write_section(outdir, heading, body, section)
    }
    print "\n完成。共输出 " section " 个片段到目录：" outdir
}

function write_section(outdir, heading, body, idx,    title, fname, path) {
    title = substr(heading, 3)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
    gsub(/[<>:"\/\\|?*]/, "_", title)
    if (index(title, ".") == 0) {
        fname = title ".md"
    } else {
        fname = title
    }
    path = outdir "/" fname
    printf "%s\n%s", heading, body > path
    close(path)
    print "已写入：" path
}
' "$INPUT_ABS"

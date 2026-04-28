#!/usr/bin/env bash
# split_by_h1.sh — 按一级标题（# Title）切分 Markdown 文件（Bash 版）
#
# 用法：
#   bash split_by_h1.sh <输入文件路径（相对于本脚本的路径）>
#
# 示例：
#   bash split_by_h1.sh ../agents/Eigen_zh.agent.md
#
# 依赖：bash 4+、awk、sed（GNU 或 BSD 均可）
# 编码：UTF-8（确保终端已设置 LANG=en_US.UTF-8 或 zh_CN.UTF-8）

set -euo pipefail

# ---------- 工具函数 ----------

die() { echo "错误：$*" >&2; exit 1; }

sanitize_filename() {
    # 替换非法字符为下划线，去除首尾空格
    echo "$1" | sed 's/[<>:"/\\|?*]/_/g' | sed 's/^[[:space:].]*//;s/[[:space:].]*$//'
}

# ---------- 参数检查 ----------

[[ $# -ne 1 ]] && {
    echo "用法：bash split_by_h1.sh <输入文件路径（相对于本脚本）>"
    echo "示例：bash split_by_h1.sh ../agents/Eigen_zh.agent.md"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_REL="$1"
INPUT_ABS="$(cd "$SCRIPT_DIR" && realpath -m "$INPUT_REL" 2>/dev/null || python3 -c "import os,sys; print(os.path.normpath(os.path.join('$SCRIPT_DIR','$INPUT_REL')))")"

[[ -f "$INPUT_ABS" ]] || die "找不到文件 \"$INPUT_ABS\""

BASE_NAME="$(basename "$INPUT_ABS")"
DIR_NAME="$(dirname "$INPUT_ABS")"
# 去掉最后一个点及其后的扩展名
NO_EXT="${BASE_NAME%.*}"
OUTPUT_DIR="$DIR_NAME/$NO_EXT"

mkdir -p "$OUTPUT_DIR"

# ---------- 核心切分逻辑（awk） ----------

awk -v outdir="$OUTPUT_DIR" '
BEGIN {
    section = 0
    preamble = ""
    heading = ""
    body = ""
    in_preamble = 1
}

# 匹配一级标题
/^# / {
    if (in_preamble) {
        # 保存 preamble
        if (length(preamble) > 0) {
            fname = outdir "/_preamble.md"
            printf "%s", preamble > fname
            close(fname)
            print "已写入：" fname
        }
        in_preamble = 0
    } else {
        # 保存上一个片段
        if (length(heading) > 0) {
            write_section(outdir, heading, body, section)
        }
    }
    section++
    heading = $0
    body = ""
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
    # 提取 "# " 之后的标题文本
    title = substr(heading, 3)
    # 去除首尾空白
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
    # 替换非法字符
    gsub(/[<>:"\/\\|?*]/, "_", title)
    # 若标题不含点，则补充 .md
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

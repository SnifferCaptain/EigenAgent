#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
split_by_h1.py — 按一级标题（# Title）切分 Markdown 文件

用法：
    python split_by_h1.py <输入文件路径（相对于本脚本的路径）>

示例：
    python split_by_h1.py ../agents/Eigen_zh.agent.md

输出：
    在输入文件所在目录下，创建一个与输入文件同名（无后缀）的子目录，
    并将每个一级标题对应的内容分别写入单独的文件。
    若文件开头存在一级标题之前的内容（如 YAML Front Matter），
    将保存为 _preamble.md。
"""

import sys
import os
import re


def sanitize_filename(name: str) -> str:
    """将标题字符串转换为合法的文件名。"""
    name = name.strip()
    # 替换 Windows/Unix 均不允许的字符
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', name)
    # 去除首尾空格与点
    name = name.strip('. ')
    return name or '_untitled'


def split_by_h1(input_relative_path: str) -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    abs_input = os.path.normpath(os.path.join(script_dir, input_relative_path))

    if not os.path.isfile(abs_input):
        print(f'错误：找不到文件 "{abs_input}"', file=sys.stderr)
        sys.exit(1)

    with open(abs_input, 'r', encoding='utf-8') as f:
        content = f.read()

    # 用一级标题作为分隔符切分，保留标题本身
    parts = re.split(r'^(# .+)$', content, flags=re.MULTILINE)

    base_name = os.path.splitext(os.path.basename(abs_input))[0]
    output_dir = os.path.join(os.path.dirname(abs_input), base_name)
    os.makedirs(output_dir, exist_ok=True)

    # parts[0] 为第一个 H1 之前的内容（如 YAML Front Matter）
    preamble = parts[0]
    if preamble.strip():
        preamble_path = os.path.join(output_dir, '_preamble.md')
        with open(preamble_path, 'w', encoding='utf-8') as f:
            f.write(preamble)
        print(f'已写入：{preamble_path}')

    # 逐对处理（标题, 正文）
    i = 1
    section_index = 1
    while i < len(parts):
        heading = parts[i]
        body = parts[i + 1] if i + 1 < len(parts) else ''

        # 取 "# " 之后的文本作为文件名
        title_text = heading[2:].strip()
        filename = sanitize_filename(title_text)

        # 若标题本身不含扩展名，则补充 .md
        if '.' not in os.path.splitext(filename)[1]:
            filename = filename + '.md'

        # 防止同名冲突：加上序号前缀
        candidate = os.path.join(output_dir, filename)
        if os.path.exists(candidate):
            name_part, ext = os.path.splitext(filename)
            filename = f'{name_part}_{section_index}{ext}'

        output_path = os.path.join(output_dir, filename)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(heading + '\n' + body)

        print(f'已写入：{output_path}')
        section_index += 1
        i += 2

    print(f'\n完成。共输出 {section_index - 1} 个片段到目录：{output_dir}')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('用法：python split_by_h1.py <输入文件路径（相对于本脚本）>')
        print('示例：python split_by_h1.py ../agents/Eigen_zh.agent.md')
        sys.exit(1)

    split_by_h1(sys.argv[1])

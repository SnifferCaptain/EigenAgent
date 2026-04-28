# script — 一键切分工具

本目录提供跨平台脚本，用于将包含多个一级标题的 Markdown 文件**按一级标题切分为独立文件**。

## 使用背景

EigenAgent 的 agent 文件（如 `agents/Eigen_zh.agent.md`）内嵌了多个逻辑文档（`Eigen.md`、`Example.md`、`Principles.md` 等），以一级标题（`# Title`）分隔。  
在初始化工作区时，AI agent 需要将这些内容逐一复制到 `.agent/` 目录，耗费大量 token。  
运行本目录中的脚本，可在本地提前完成切分，直接生成独立文件，从而显著减少 agent 初始化的 token 消耗。

---

## 快速开始

> **推荐优先使用 Python 脚本**，跨平台且最可靠。

### Python（推荐，跨平台）

```bash
python split_by_h1.py ../agents/Eigen_zh.agent.md
```

### Bash（Linux / Git Bash on Windows）

```bash
bash split_by_h1.sh ../agents/Eigen_zh.agent.md
```

### PowerShell（Windows）

```powershell
.\split_by_h1.ps1 ..\agents\Eigen_zh.agent.md
```

### zsh（macOS 原生）

```zsh
zsh split_by_h1_mac.sh ../agents/Eigen_zh.agent.md
```

---

## 脚本行为说明

| 脚本文件 | 适用平台 | 依赖 |
|---|---|---|
| `split_by_h1.py` | 全平台 | Python 3.6+ |
| `split_by_h1.sh` | Linux / Git Bash | bash 4+、awk |
| `split_by_h1.ps1` | Windows | PowerShell 5.1+ 或 7+ |
| `split_by_h1_mac.sh` | macOS | zsh（系统自带）、awk |

**输入：** 相对于脚本文件自身的路径，指向待切分的 Markdown 文件。  
**输出：** 在输入文件同级目录下，创建与输入文件同名（无后缀）的子目录，每个一级标题对应一个文件。  
若文件开头存在一级标题之前的内容（如 YAML Front Matter），将保存为 `_preamble.md`。

**示例（以中文 agent 文件为例）：**

```
输入：agents/Eigen_zh.agent.md
输出：
  agents/Eigen_zh/
    _preamble.md      ← YAML Front Matter
    Eigen.md
    Example.md
    Principles.md
    Plan.md
    Init.md
```

所有文件均以 **UTF-8** 编码写入。

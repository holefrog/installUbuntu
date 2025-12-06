#!/usr/bin/env bash

# 如果不是 git 仓库则初始化
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init
fi

# 统一设置远程仓库（不管是否存在，都重置）
git remote remove origin 2>/dev/null
git remote add origin https://github.com/holefrog/installubuntu.git

# 使用 orphan 分支彻底覆盖 main
git checkout --orphan temp_branch
git add .
git commit -m "Full overwrite"
git branch -M main

# 强制推送到 GitHub
git push origin main --force


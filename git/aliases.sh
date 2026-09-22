#!/usr/bin/env bash
# 常用 git 别名，source 后生效：source git/aliases.sh
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --decorate -10"
git config --global alias.unstage "reset HEAD --"
echo "git 别名已设置：co/br/st/lg/unstage"

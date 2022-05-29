# Dotfiles
Dotfiles management entirely within a bare git repo, with [git-crypt](https://github.com/AGWA/git-crypt) for transparent GPG-based file encryption.

## Installation
```shell
git clone --bare git@github.com:Foltik/dotfiles $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME config --local status.showUntrackedFiles no
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout
git-crypt unlock
```

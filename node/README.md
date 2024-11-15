# NVM on Fish shell on macOS


NVM doesn't support fish by default. So, prefer fnm going forwards (from Nov 2024). You may still use nvm on clients' servers that mostly use bash.

---

## FNM

By default, fnm is installed at `~/Libarary/Application Support` and fnm assumes we use homebrew! So, let's tweak the default options while running the install script...

`curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "~/.fnm" --force-no-brew`

`fnm install --lts`

### Uninstalling fnm ...

`rm ~/.config/fish/conf.d/fnm.fish`
`rm -rf ~/.fnm`

---

## Volta

Or use [Volta](https://volta.sh/)

Volta has straightforward install and uninstall script for fish.

---

## NVM on fish shell on macOS

### Install

https://github.com/nvm-sh/nvm/issues/303#issuecomment-2361844546

Create those three functions (in the same file). See `nvm.fish` available in this repo.

Then type

`nvm install node`

`node version`

### Uninstalling NVM in fish...

`rm ~/.config/fish/functions/nvm.fish`
`rm -rf ~/.nvm`

---



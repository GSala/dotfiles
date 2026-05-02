# dotfiles

Personal machine configuration managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap a new machine

Install Homebrew, then install chezmoi and mise:

```sh
brew install chezmoi mise
```

Initialize this repository:

```sh
chezmoi init <repo-url>
```

Preview and apply the managed files:

```sh
chezmoi diff
chezmoi apply
```

Install pinned global runtimes from `~/.config/mise/config.toml`:

```sh
mise install
mise doctor
```

Open a new shell and verify:

```sh
mise ls --current
java -version
python --version
node --version
```

## 1Password

chezmoi supports 1Password through the `op` CLI. Prefer storing secrets in
1Password and referencing them from chezmoi templates instead of committing
plaintext secrets.

Use `onepasswordRead` for individual fields:

```gotemplate
{{ onepasswordRead "op://Personal/item-name/field-name" }}
```

Use `onepassword` when a template needs structured item data:

```gotemplate
{{ (onepassword "item-uuid").fields.password.value }}
```

Before applying templates that reference 1Password, make sure the 1Password app
is running and CLI integration is enabled, then verify:

```sh
op account list
```

## Daily use

Edit managed files through chezmoi:

```sh
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

Add a new file:

```sh
chezmoi add ~/.some-config
```

Commit changes from the source directory:

```sh
chezmoi cd
git status
git add .
git commit -m "Update dotfiles"
```

# Roadmap

## Completed

- [x] Multi-platform architecture (directory structure for linux-amd64, linux-arm64, darwin)
- [x] Profile system (desktop, server, work)
- [x] New module interface (check, install, update, config)
- [x] Dry-run mode
- [x] Update mode
- [x] Logging to ~/.config/kdub.settings.log
- [x] Interactive config merge (per-file prompts)
- [x] Single-source module loading (reduced from 5-6 sources to max 2)
- [x] System modules (_system/op.sh for 1Password CLI)
- [x] linux-amd64 modules complete (20 modules)

## In Progress

- [ ] linux-arm64 modules
  - Copy from linux-amd64
  - Adjust architecture-specific downloads (delta, lazygit, lazydocker, bun)
  - Test on ARM server

- [ ] darwin (macOS) modules
  - Create _system/brew.sh (Homebrew)
  - Create _system/op.sh (1Password via brew)
  - Convert all modules to use brew install
  - Test on macOS

## Planned

- [ ] 1Password integration for secrets
  - Use `op` CLI to retrieve API keys
  - Prompt for secrets on first run
  - Store 1Password item references

- [ ] Module dependencies (if needed)
  - Allow modules to declare dependencies
  - Topological sort for install order

- [ ] Status command
  - `./setup.sh --status` to show installed vs available modules

- [ ] Uninstall/rollback
  - Track what was installed
  - Ability to remove modules

## Maybe Later

- [ ] Windows support (modules/windows/)
  - PowerShell profile
  - winget or scoop package manager

- [ ] Plugin system
  - User-defined modules in ~/.config/kdub.settings/modules/
  - Override default modules

- [ ] Version pinning
  - Lock specific versions of tools
  - Reproducible installs

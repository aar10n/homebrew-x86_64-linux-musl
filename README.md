# Homebrew Tap for x86_64-linux-musl Toolchain

This is the official Homebrew tap for the x86_64-linux-musl cross-compilation toolchain.

## Installation

```bash
# Add the tap
brew tap aar10n/x86_64-linux-musl

# Install the official musl variant
brew install x86_64-linux-musl

# Or install the osdev-musl variant
brew install x86_64-linux-musl-osdev
```

## About

This tap provides pre-built bottles for the x86_64-linux-musl cross-compilation toolchain, which allows you to build x86_64 Linux binaries with musl libc on macOS.

For source code, build instructions, and more information, see the main repository:
https://github.com/aar10n/x86_64-linux-musl

## Variants

- **x86_64-linux-musl** - Uses official musl libc
- **x86_64-linux-musl-osdev** - Uses custom osdev-musl fork for OS development

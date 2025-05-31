# Tools

## InstallerBuilder

Usage :

```bash
python ./tools/installer_builder.py
```

## Packer

**Usage** :

```bash
python ./tools/packer.py
```

## Minify

**Requirement** : 

- [luamin](https://github.com/mathiasbynens/luamin) installed and available in your shell paths.

**Usage** :

```bash
luamin -f ccmaze.lua > ccmaze-min.lua
```

## Build

*All of the above, in one go.*

**Requirement** : 

- [luamin](https://github.com/mathiasbynens/luamin) installed and available in your shell paths.

**Usage** :

```bash
python ./tools/build.py
```
# Tools

## InstallerBuilder

*To generate the module downloader to help computercraft users.*

**Usage** :

```bash
python ./tools/installer_builder.py
```

## Packer

*To pack all the submodules in a single file.*

**Usage** :

```bash
python ./tools/packer.py
```

## Minify

*To reduce the size of the packed file.*

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
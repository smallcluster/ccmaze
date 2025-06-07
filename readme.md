# ccmaze

![](imgs/header.webp?raw=true)

A computercraft focussed lua library for generating mazes!

## Installation

The ccmaze library exist in 3 different versions :

- As a **single lua file**: Auto generated from the lua module. Easier to get or share. It's the **recommended version for most user**.
- As a **lua module**: This is the original source code. Recommended when learning ccmaze as its structuration also serves as documentation.
- As a **single minified lua file**: Auto generated from the single file version with [luamin](https://github.com/mathiasbynens/luamin). For when size matter, but debugging doesn't (cryptic obfuscation due to the aggressive minification process).

Here is a quick comparison :

| version              | modular | debuggable | size    |
| -------------------- | ------- | ---------- | ------- |
| single file          | no      | yes        | ~46,8ko |
| lua module           | yes     | yes        | ~46,6ko |
| single minified file | no      | no         | ~12,8ko |

Take a look at the provided demo code to learn how to use ccmaze.

### Single Lua file

Simply download the `ccmaze.lua` :

```shell
wget https://raw.githubusercontent.com/smallcluster/ccmaze/v1.0.1/master/ccmaze.lua
```

### Single minified lua file 

Simply download the `ccmaze-min.lua` as `ccmaze.lua` :

```shell
wget https://raw.githubusercontent.com/smallcluster/ccmaze/v1.0.1/master/ccmaze-min.lua ccmaze.lua
```

### Lua module

Since this version is composed of multiple files, a downloader is provided to easily fetch the library.

```shell
wget https://raw.githubusercontent.com/smallcluster/ccmaze/v1.0.1/master/ccmaze-dl.lua
```

By running `ccmaze-dl.lua`, the module `ccmaze` will be downloaded in your working directory.

## Demo

**Requirements** :

- At least one of the three version of `ccmaze` in its working directory.
- An advanced computer next to a monitor of any size

A demo cycling through all available generator algorithm with visual animation is provided as an example (the animation at the top of this page) :

```shell
wget https://raw.githubusercontent.com/smallcluster/ccmaze/v1.0.1/master/ccmaze-demo.lua
```

## Available generators

- Recursive-Backtracking
- Kruskal
- Origin shift

## Architecture

### Consumer-Producer pattern cycle

![](imgs/pattern.svg?raw=true)

### UML diagram

![](imgs/classes.svg?raw=true)
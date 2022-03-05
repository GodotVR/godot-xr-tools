# Godot XR Tools

![GitHub forks](https://img.shields.io/github/forks/godotvr/godot-xr-tools?style=plastic)
![GitHub Repo stars](https://img.shields.io/github/stars/godotvr/godot-xr-tools?style=plastic)
![GitHub contributors](https://img.shields.io/github/contributors/godotvr/godot-xr-tools?style=plastic)
![GitHub](https://img.shields.io/github/license/godotvr/godot-xr-tools?style=plastic)

This repository contains a number of support files and support scenes that can be used together with the various AR and VR interfaces for the Godot game engine.

## Versions

Official releases are tagged and can be found [here](https://github.com/GodotVR/godot-xr-tools/releases).

The following branches are in active development:
|  Branch   |  Description  |
|-----------|---------------|
|  master   | Godot 3 development branch  |
|  4.0-dev  | Godot 4 development branch  |

## How to Use

Information about how to use this plugin can be found [in our WIKI](https://github.com/GodotVR/godot-xr-tools/wiki).

### Preventing hickups

As many of the functions in this module will hide objects that are later shown as the user performs actions, the user will experience a hickup as Godot compiles the shader used to draw the object on screen.

To combat this you will find a scene in this module called `misc/VR_Common_Shader_Cache.tscn`.
Add this scene as a child node to your ARVRCamera. This will trigger the required shaders being
compiled the first time your main scene loads.

Licensing
---------
This repository is licensed under the MIT license.
See the full license inside of the addons folder.

About this repository
---------------------
This repository was created by and is maintained by Bastiaan Olij a.k.a. Mux213

You can follow me on twitter for regular updates here:
https://twitter.com/mux213

Videos about my work with Godot including tutorials on working with VR in Godot can by found on my youtube page:
https://www.youtube.com/BastiaanOlij

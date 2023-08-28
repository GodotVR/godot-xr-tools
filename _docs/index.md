---
title: Welcome
permalink: /docs/home/
redirect_from: /docs/index.html
---

The Godot XR Tools library was created as a repository of classes to use when building
an AR or VR game or experience using the Godot Game Engine.

The Godot Game Engines AR/VR system exposes a number of key nodes that allow you to 
create a XR game that in theory runs on any device. These nodes however do not implement
any game logic leaving that up to the person implementing their game or experience. This
library provides a number of example implementations that can either be used directly
or used as inspiration to implement your own.

All examples found here make no assumptions of the hardware you are using. Obviously
if you use something that requires positional tracking you need a 6DOF capable headset
but other than that this toolkit attempts to be as agnostic as possible.

Some of the AR/VR plugins available do implement additional logic, OpenVR exposes render
models, the Oculus Quest plugin has all sorts of neat helper objects, etc. This toolkit
ignores those platform specific features but you are obviously free to mix and match.
That is a big goal of the architecture.

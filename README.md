# Godot XR Tools
This repository contains a number of support files and support scenes that can be used together with the various AR and VR interfaces for the Godot game engine.

## How to Use

Note that the below info is a quick write-up to get your started. More detailed information can be found in our WIKI:
https://github.com/GodotVR/godot-xr-tools/wiki

### Preventing hickups

As many of the functions in this module will hide objects that are later shown as the user performs actions, the user will experience a hickup as Godot compiles the shader used to draw the object on screen.

To combat this you will find a scene in this module called `misc/VR_Common_Shader_Cache.tscn`.
Add this scene as a child node to your ARVRCamera. This will trigger the required shaders being
compiled the first time your main scene loads.

### Physics layers

Right now this is only important for the direct movement but the assumption is that all player related collision shapes are in layer 1 and everything else is in the other layers.
If you place environment collision shapes into layer 1 the physics engine goes a little crazy.
This is something we're still looking into making easier.

### Teleportation
- if your scene doesn't have a floor yet:
  - add a `StaticBody` node to the scene root
  - add a `MeshInstance` as a child of the `StaticBody` and set its Mesh to `New PlaneMesh`
  - add a `CollisionShape` a child of the `StaticBody` and set its Shape to `New PlaneShape`
- instance child scene from [the ovr_first_person scene](https://github.com/GodotVR/godot-openvr-asset/blob/master/addons/godot-openvr/scenes/ovr_first_person.tscn) (produces `OVRFirstPerson` node)
- right click `OVRFirstPerson` node in the Scene tab and select `Editable Children` to expand the imported scene
- right click  `Left_Hand`  in the Scene tab and instance child scene [Function_Teleport](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Teleport.tscn)
- right click  `Right_Hand`  in the Scene tab and instance child scene [Function_Teleport](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Teleport.tscn)
- left click each `Function_Teleport` child in the Scene tab and find its Script Variables in the Inspector - assign `Origin` to `OVRFirstPerson` which is an instance of `ARVROrigin`
- start the scene and pull the trigger (button 15) to aim the teleport arc (release to teleport)

_NOTE: Newer versions of Godot will warn you with a yellow triangle that "This node has no children shapes so it can't interact with the space. Consider adding CollisionShape or CollisionPolygon children nodes to define it's shape." If you add a CollisionShape as suggested, that will interfere with the script and cause you to see a capsule rendered directly in front of you with a red indicator (i.e. teleport is blocked by the child collision)_

### Direct Movement
- instance child scene from [the ovr_first_person scene](https://github.com/GodotVR/godot-openvr-asset/blob/master/addons/godot-openvr/scenes/ovr_first_person.tscn) (produces `OVRFirstPerson` node)
- left click `Function_Direct_movement`  in the Scene tab and find its Script Variables in the Inspector: assign `Origin` to `OVRFirstPerson` which is an instance of `ARVROrigin` and `Camera` to `ARVRCamera`
- right click `OVRFirstPerson` node in the Scene tab and select `Editable Children` to expand the imported scene
- right click  `Left_Hand`  in the Scene tab and instance child scene [Function_Direct_movement](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Direct_movement.tscn)
- right click  `Right_Hand`  in the Scene tab and instance child scene [Function_Direct_movement](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Direct_movement.tscn)
- left click each `Function_Direct_movement` child in the Scene tab and find its Script Variables in the Inspector - assign `Origin` to `OVRFirstPerson` which is an instance of `ARVROrigin` and `Camera` to `ARVRCamera`.
- start the scene and move the joystick/trackpad forward/back to slide forward/back and left/right to rotate

### Pointer
- if your scene doesn't have objects with a `CollisionShape`/`CollisionPolygon` attached:
  - add a `StaticBody` node to the scene root
  - add a `MeshInstance` as a child of the `StaticBody` and set its Mesh to `New SpheneMesh`
  - add a `CollisionShape` a child of the `StaticBody` and set its Shape to `New SphereShape`
- to each node that you want to enable pointer interaction (assuming it has a `CollisionShape` child), add a script that contains a `_on_pointer_pressed` function and a `_on_pointer_released` function:
```  
func _on_pointer_pressed(collisionVector3):
    print(str("A pointer pressed me at ", collisionVector3))
    # your awesome effects here

func _on_pointer_released(collisionVector3):
    print(str("A pointer was released at ", collisionVector3))
    # your awesome effects here
```
- instance child scene from [the ovr_first_person scene](https://github.com/GodotVR/godot-openvr-asset/blob/master/addons/godot-openvr/scenes/ovr_first_person.tscn) (produces `OVRFirstPerson` node)
- left click `Function_Pointer`  in the Scene tab and find its Script Variables in the Inspector: assign `Origin` to `OVRFirstPerson` which is an instance of `ARVROrigin` and `Camera` to `ARVRCamera`
- right click `OVRFirstPerson` node in the Scene tab and select `Editable Children` to expand the imported scene
- right click  `Left_Hand`  in the Scene tab and instance child scene [Function_pointer](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Pointer.tscn)
- right click  `Right_Hand`  in the Scene tab and instance child scene [Function_pointer](https://github.com/GodotVR/godot-xr-tools/blob/master/addons/vr-common/functions/Function_Pointer.tscn)
- start the scene, point at an object and pull the trigger (button 15) to call the pressed/released function on each object (it should print to the console output).

_NOTE: If you want to use Teleport and Pointer together you probably need to edit one or both of their scripts since both are mapped to button 15 (the primary trigger for oculus touch). Double click the script icon next to each and search for `is_button_pressed` to make changes._

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

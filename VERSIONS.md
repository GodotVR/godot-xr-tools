# 4.3.3
- Fix Viewport2Din3D property forwarding

# 4.3.2
- Move fade logic into effect
- Added collision fade support
- Added fix for slowly sliding on slopes
- Added fix for ground-control preventing jumping over objects
- Added property forwarding for Viewport2Din3D
- Added fix for open/close poses
- Added rumble manager for haptic feedback
- Fix unreliable wall-walking collision

# 4.3.1
- Fix saving project when using plugin-tools to set physics layers or enable OpenXR
- Fix updating the editor-preview hand-pose
- Fix jumping on slopes
- Fix material warnings by converting binary .material files to .tres files
- Fix staging to use threaded loading while starting the fade
- Fix broken world-grab script

# 4.3.0
- Upgraded project to Godot 4.1 as the new minimum version.
- Added reporting of stage load errors.
- Blend player height changes and prevent the player from standing up under a low ceiling.
- **minor-breakage** Added support for swapping held items between hands.
- Added jog-in-place movement provider.
- Added support for grappling on GridMap instances
- **breakage** Added support for two-handed grabbing.
- Added support for snapping hands to grab-points.
- Added support for world-grab movement.
- Fixed editor errors when using hand physics bones.
- Added support for climbable grab-points.
- Added control of keyboard or gamepad inputs to Viewport2Din3D instances.

# 4.2.1
- Fixed snap-zones showing highlight when disabled.
- Fixed pickup leaving target highlighted after picking up.
- Fixed collision hands getting stuck too far from the real hands.

# 4.2.0
- Environments can now be set normally in scenes loaded through the staging system.
- Fixed issue with not being able to push rigid bodies when colliding with them.
- Fixed player movement on slopes.
- Fixed lag in finger-poke.
- Added initial collision hand support.
- Added support for custom materials for 2D in 3D viewport
- Updated pointer to support visibility properties and events
- Modified virtual keyboard to expose viewport controls and default to unshaded
- Cleaned up teleport and added more properties for customization
- Modified pickup highlighting to support pickables in snap-zones
- Added "UI Objects" layer 23 for viewports to support interaction by pointer and poking
- Fixed player scaling issues with crouching and poke
- **minor-breakage** Added support for passing user data between staged scenes with default handling for spawn-points
- Moved teleport logic to player and added teleport area node
- Change pointer event dispatching
- Added multi-touch on 2D in 3D viewports and virtual-keyboard
- Added option to disable laser-pointers when close to specific bodies/areas

# 4.1.0
- Enhanced grappling to support collision and target layers
- Added Godot Editor XR Tools menu for layers and openxr configuration
- Improved gliding to support roll-turning while flapping
- Added render_target_size_multiplier to StartXR (requires Godot 4.1+)

# 4.0.0
- Conversion to Godot 4
- Fixed footstep resource leak and added jump sounds and footstep signal
- Added grab-point switching to pickable objects
- Added return-to-snap-zone feature

# 3.4.0
- Fixed footstep resource leak and added jump sounds and footstep signal
- Added grab-point switching to pickable objects
- Added return-to-snap-zone feature

# 3.3.0
- Added reset-scene and scene-control functions to scene-base
- Fixed snap-zones stealing objects picked out of other near-by snap-zones
- Improved player body so it can be used to child objects to
- Updated scene/script default physics layers to match recommendations on website

# 3.2.0
- Minimum supported Godot version set to 3.5
- Added glide option for turning with arm-roll
- Added physics gravity effects on the player so they can walk around a planet
- Added wall-walking movement provider
- Cleaned the code to pass gdlint code checks
- Modified to work with both WebXR and OpenXR
- Added enable property to pickable objects
- Added support for snap-on-drop to snap-zones
- Added glide options for gaining altitude when flapping arms
- Added option to disable snap-turn repeating by setting the delay to 0
- Added capability for pointer function to auto-switch between controllers

# 3.1.0
- Improvements to our 2D in 3D viewport for filtering, unshaded, and transparency options
- Fixed editor preview system for our 2D in 3D viewport
- Use value based grip input with threshold
- Improved pointer demo supporting left hand with switching
- Enhanced pointer laser visibility options for colliding with targets
- Implement poke feature (finger interaction)
- Improvements to snap turning
- Moved staging solution into plugin so it can be re-used
- Allow setting different animations for hands
- Added enable/disable to snap-zones
- Added XR settings as Godot editor plugin and the ability to load and save the settings
- Added crouching movement provider
- Modified climbing to use the hand which most recently grabbed the climbing object
- Added enable/disable to pickup function
- Added ability to override hand material
- Added realistic hand models and textures
- Added ability to override hand animations
- Added additional search functions to find nodes
- Added support for viewport 2D in 3D to support 2D scenes instanced in the tree
- Added sprinting movement provider
- Added support for setting hand-poses when the hand enters an area
- Added support for setting grab-points on objects, and the grab-points supporting different hand-poses

# 3.0.0
- Included demo project with test scenes to evaluate features
- Standardized class naming convention for all scripts to "XRTools<PascalCaseName>"
- Standardized file naming convention to "snake_case_name.ext"
- Added many explicit type specifiers in preparation for GDScript 2.0
- Renamed some functions to avoid name-collisions with Godot 4.0

# 2.6.0
- Fixed enforcement of direct-movement maximum speed
- Added editor icons for all nodes
- Added collision bouncing to PlayerBody

# 2.5.0
- Added advanced player height control
- Modified climbing to collapse player to a sphere to allow mounting climbed objects
- Added crouch movement provider
- Added example fall damage detection
- Added moving platform support to player body
- Fixed player height-clamping to work in player-units
- Fixed glide T-pose detection to work in player-units
- Fixed jump detection to work in player-units
- Added valid-layer checking to teleport movement
- Modified hand meshes (blend and glb) to be scaled, so the hand scenes can be 1:1 scaled
- Modified hands to scale with world_scale (required for godot-openxr 1.3.0 and later)
- Added physics hands with PhysicsBody bones
- Fixed disabling of `_process` in XRToolsPickable script

# 2.4.1
- Fixed grab distance
- Fixed snap-zone instance drop and free issue
- Movement provides react properly when disabled
- Hiding grapple target when disabled

# 2.4.0
- Added configuration setting for head height in player body.
- Added Function_JumpDetect_movement to detect jumping via the players body and/or arms
- Improved responsiveness of snap-turning
- Moved flight logic from Function_Direct_movement to Function_Flight_movement
- Added option to disable player sliding on slopes
- Added support for remote grabbing
- Moved turning logic from Function_Direct_movement to Function_Turn_movement
- Fixed movement provider servicing so disabled/bypassed providers can report their finished events
- Added grappling movement provider
- Added snap-zones

# 2.3.0
- Added vignette
- Moved player physics into new PlayerBody asset (breaking change)
- Moved Function_Direct_movement settings for player physics into PlayerBody
- Added Function_Glide_movement to allow the player to glide
- Added Function_Jump_movement to allow the player to jump
- Added Function_Climb_movement to allow the player to climb
- Redid the setup of the hands to make it easier to extend to other gestures
- Improved pickup and throwing logic

# 2.2
- Changed default physics layers to make more sense (minor breaking change)
- Replaced Center On Node property with PickupCenter node you can place
- Made Object_pickable script work by itself and registers as class `XRToolsPickable`
- New Object_interactable convenience script that registers as class `XRToolsInteractable` that reacts to our pointer function
- Removed ducktype switch from pointer, pointer will use signals over ducktyping automatically (minor breaking change)

# 2.1
- added option to highlight object that can be picked up
- added option to snap object to given location (if reset transform is true)
- added callback when shader cache has finished
- using proper UI for layers
- added hand controllers that react on trigger and grip input
- fixed delta on move and slide (breaking change!)
- letting go of an object now adds angular velocity

# 2.0
- Renamed add on to **godot-xr-tools**
- Add enums to our export variables
- Add a switch on pickable objects to keep their current positioning when picked up
- Move direct movement player collision slightly backwards based on player radius
- Added switch between step turning and smooth turning
- Fixed sizing issue with teleport
- Added option to change pickup range

# 1.2
- Assign button to teleport function and no longer need to set origin
- Added pickable object support
- Fixed positioning of direct movement collision shape
- Added strafe and fly mode for directional
- Added ability to enable/disable the movement functions
- Added 2D in 3D viewport for UI
- Improved throwing by assigning linear velocity

# 1.1*
- previous versions were not tracked

* Note that version history before 1.2 was not kept and is thus incomplete

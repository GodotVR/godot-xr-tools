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
- Fixed disabling of _process in XRToolsPickable script

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

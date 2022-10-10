# Pickable Demo Scene

This demo scene shows pickable objects and snap-zones.

This scene makes use of the following standard physics layers defined in the project:
 * Layer 1 (static_world) for the static parts of the world environment
 * Layer 2 (dynamic_world) for any moving parts of the world environment
 * Layer 3 (object) for any interactable objects
 * Layer 17 (held_object) for any objects held by the player
 * Layer 18 (player_hand) for the players hands
 * Layer 20 (player_body) for the players main body

## Grab Balls
The grab_ball.tscn scene inherits from Object_pickable.tscn and adds the following:
 * A sphere mesh for the ball
 * A sphere to the collision shape
 * A grab-highlight which shows/hides a yellow highlight sphere

The ball is configured for remote-grabbing so the player can easily pick the balls up.

When the ball is not held by the player it resides on the object layer and will collide with the 
static_world, dynamic_world, object, held_object, player_hand and player_body layers. As such the
object will:
 * Collide with the ground - so it doesn't fall through the world
 * Collide with tables 
 * Collide with other objects
 * Collide with objects held by the player
 * Collide with the players hand - to emulate hitting the ball
 * Collide with the players body - to emulate kicking the ball

## Grab Cube
The grab_cube.tscn scene inherits from Object_pickable.tscn and adds the following:
 * A cube mesh for the cube
 * A cube to the collision shape
 * A highlight-ring indicating when the object can be grabbed

When the ball is not held by the player it resides on the object layer and will collide with the 
static_world, dynamic_world, object, held_object and player_hand layers. As such the
object will:
 * Collide with the ground - so it doesn't fall through the world
 * Collide with tables 
 * Collide with other objects
 * Collide with objects held by the player
 * Collide with the players hand - so the player can push the cubes around

## Snap Tray
The snap_tray.tscn scene inherits from Object_pickable.tscn and adds the following:
 * A mesh for the body
 * A mesh to the collision shape
 * Four snap-zones for snapping different objects to

The snap-tray can be picked up and moved around, and can also have red and yellow test objects
snapped to the snap-zones.

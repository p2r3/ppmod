# ppmod
VScript library for developing Portal 2 mods quickly.

The focus of this project is to provide tools that assist in developing Portal 2 VScript mods under tight time constraints. The goal is not to replace existing tools and SDKs, but rather to make prototyping complicated VScript projects much more comfortable by including lots of common functions for interacting with the world, player and engine.

## Installation

To use ppmod in your project, include the script file before calling any ppmod functions:
```
  IncludeScript("ppmod3.nut");
```
Make sure to do this in an environment that has access to `CEntities`, otherwise most game-related functions will not work.
You can do this by checking if the instance `Entities` exists within `this`:
```
  if("Entities" in this) {
    IncludeScript("ppmod3.nut");
    ...
  }
```

## Functions
### ppmod.fire

More convenient alternative to `EntFire`, `DoEntFire` or `EntFireByHandle`. Most arguments are optional, containing default values similar to the ent_fire console command. This makes entity inputs much shorter and cleaner in code.


```
  ppmod.fire (entity, action = "Use", value = "", delay = 0, activator = null, caller = null)
```

The first argument is the entity to send an input to. This can be either an entity handle or a string. Next is the action, "Use" by default. Then the value, empty by default, the delay in seconds, 0 by default, and finally entity handles for the activator and caller, both null by default. Please note that the caller is only set if the entity is provided as a handle.

### ppmod.addoutput

More versitile alternative to `ConnectOutput` or `EntFire AddOutput`. Other than the entity, it's output and the target entity, every other argument is optional, with a common default placeholder value.

```
  ppmod.addoutput (entity, output, target, input = "Use", value = "", delay = 0, max = -1)
```

Since this function uses ppmod.fire internally, the entity can be specified with a string or handle. Similarly, the target entity can also be a string or handle. However, when provided a handle, it's targetname is used instead. If no targetname is set, one gets randomly generated and applied to the entity. The output is given as a string. The following arguments match their counterparts in `ppmod.fire`, with the exception being max, which sets the total amount of times this output will fire before being exhausted. Setting it to -1 (default) removes this limit.

### ppmod.addscript

Similar to `ppmod.addoutput`, used as a cleaner and more powerful way of attaching VScript code to entity outputs.

```
  ppmod.addscript (entity, output, script, delay = 0, max = -1)
```

The arguments are almost the same as the ones in `ppmod.addoutput`, except instead of specifying a target entity and input values, a script is required instead. This can be code within either a string or a function. Below is an example of attaching a local function to an entity output:

```
  ppmod.addscript("prop_button", "OnPressed", function() {
    printl("Button pressed!");
  });
```

### ppmod.keyval

Shorter, more convenient alternative to `__KeyValueFrom...` functions. Automatically selects the approperiate function for the specified entity and keyvalue type.

```
  ppmod.keyval (entity, key, value)
```

The entity can be provided as a handle or string. However, when provided a string, `EntFire AddOutput` is used for applying the keyvalue. This might cause issues with asynchronous operations, as entity inputs are processed on a different thread. The key is expected to be a string, while the value may be an integer, boolean, float, string or Vector.

### ppmod.wait

Simple way of delaying the execution of a function. Creates a dummy `logic_relay` entity with an attached script. The timing is enforced by a delayed EntFire.

```
  ppmod.wait (script, delay)
```

The first argument is the script to run, either as a string or function. The second argument is the delay in seconds. Returns a handle to the `logic_relay` entity, in case the timer needs to be aborted by destroying this entity. After the script is executed, the `logic_relay` is automatically destroyed.

### ppmod.interval

Runs the specified script in regular intervals. Creates a `logic_timer` entity and configures it to run the script at an interval.

```
  ppmod.interval (script, delay = 0, name = "")
```

The first argument is the script to run, either as a string or function. The second argument is the interval of the loop, in seconds. When set to 0 (default), the function is called once every tick. The third argument sets the targetname for the `logic_timer` entity. This is provided mostly for backwards compatibility and for an alternative way of accessing the timer. Returns a handle to the `logic_timer` entity, which can then be used to stop or modify the loop.

### ppmod.once

Ensures that the specified script is run only once, even if this function is called multiple times. Creates a dummy `logic_relay` entity and uses it's targetname as a reference for duplicates. Or, if no name is provided, uses the script itself as a name.

```
  ppmod.once (script, name = null)
```

The first argument is the script to run, either as a string or function. The second argument is the targetname of the `logic_relay` entity. If no name is provided and the script is in the form of a string, the entire script gets used as a name. If the script provided is a function, it uses a pointer to the function as a name.

### ppmod.get

More convenient way of getting entity handles, replacing `CEntities` methods like `FindByName` or `FindByClassnameNearest`, instead automatically searching using multiple of these methods back to back. Also provides a way to get entities by their entity ID.

```
  ppmod.get (key, entity = null, argument = 1)
```

The first argument accepts a string, Vector, integer or instance. Different searches are performed depending on the type of key provided:
- If a string is provided, the function first searches for an entity with a matching targetname, then a matching classname, and finally a matching model. This is probably the most common type of search.
- If a vector is provided and the second argument is a string, the function attempts to find an entity with a matching classname around the vector's coordinates within the radius set by the third argument.
- If a vector is provided and the second argument isn't a string, the function returns an entity near the given vector in a radius set by the third argument.
- If an integer is provided, the function iterates through all entities, searching for an entity with an ID that matches the integer.
- If an instance is provided, the next entity in the list of entities is returned, similar to `Entities.Next`.

Please note that, if used excessively, this function may impact performance more than the native `CEntities` methods.

### ppmod.prev

Reverses iteration over a list of entities, finding the previous entity to match the given criteria. Similar to `ppmod.get`, but in reverse.

```
  ppmod.prev (key, entity = null, argument = 1)
```

The arguments and types of searches are nearly identical to ppmod.get, with the only exception being no support for a radius search by classname. Reversed iteration is performed by iterating forwards, then returning the last entity to not match the second argument. Because of the complexity and performance impact, this is not an efficient way of iterating backwards in most cases. Rather, iterate through your search once and use a table to then traverse backwards in. This function can, however, be used for conveniently finding the last matching element of a search if the second argument is set to null.

### ppmod.player

Provides more information about the player, as well as new ways of listening to the player's actions. Things like eye angles and jump, land, duck and unduck outputs are included.

```
  ppmod.player {
    enable   ()
    eyes
    eyes_vec ()
    jump     (script)
    land     (script)
    duck     (script)
    unduck   (script)
  }
```

#### ppmod.player.enable

Calling this function creates the entities required for other `ppmod.player` functions to work. Please note that, in most cases, this is performed asynchronously. It might take an extra tick to enable all functions. Accepts no arguments. Calling this function more than once per map may cause unexpected behavior.

#### ppmod.player.eyes

Entity handle for a `logic_measure_movement` entity set to track the player's eyes. Using methods like `GetAngles` or `GetOrigin` lets you retrieve the player's eye angles and position.

```
  ppmod.player.enable();
  
  // Waiting for two ticks to ensure that the entities have been created
  ppmod.wait(function() {
  
    printl( ppmod.player.eyes.GetAngles() );
    printl( ppmod.player.eyes.GetOrigin() );
    
  }, FrameTime() * 2);
```

However, for getting the position, it is suggested to use the native `CBaseEntity` method `EyePosition()` instead, as the position of `ppmod.eyes` might not always be accurate.

#### ppmod.player.eyes_vec

Returns a normalized vector pointing in the direction that the player is looking in. Accepts no arguments.

```
  ppmod.player.enable();
  
  ppmod.wait("printl( ppmod.player.eyes_vec() )", FrameTime() * 2);
```

When combined with `TraceLine`, for example, this vector can be used for things like simulating weapon hitscan:

```
  ppmod.player.enable();

  ppmod.wait(function() {

    
    local dist = 2048;
    local start = ppmod.player.eyes.GetOrigin();
    local vec = ppmod.player.eyes_vec() * dist;

    local frac = TraceLine(start, start + vec, GetPlayer());
    printl( "Hit point: " + ( start + vec * frac ) );

  }, FrameTime() * 2);
```

#### ppmod.player.[jump, land, duck, unduck]

Set of functions for adding scripts to player movement actions. Accepts one argument - the script to attach, either a string or function.
- `ppmod.player.jump` triggers when the player performs the jump input. This is true even for when the player is already in the air or crouching.
- `ppmod.player.land` triggers when the player changes the surface they're standing on. This will trigger when landing from previously being in air, or when walking from, for example, a concrete surface to a metal one.
- `ppmod.player.duck` triggers when the player begins crouching. This will not fire if the player is unable to crouch, for example, when in the air following a jump.
- `ppmod.player.unduck` triggers when the player begins to uncrouch. This will fire regardless of how crouched the player was before beginning to stand up.

### ppmod.create

Creates an entity using console commands and retrieves it's handle. Some entities cannot be fully created with `CEntities` methods alone, as this often leaves some crucial entity code unloaded. This function can also be used for preloading models through the `prop_dynamic_create` console command.

```
  ppmod.create (command, function, key = null)
```

The first argument is the command to run for creating the entity. This argument also accepts a model assuming the `models/` directory, in which case it is automatically prefaced by `prop_dynamic_create`. If an entity classname is provided, it is prefaced by `ent_create`. Portal-specific commands like `ent_create_portal_weighted_cube` are also supported.

The second argument is the function to run after the entity has been created and found. This function is provided with one argument - the handle of the created entity. The function can be provided as a string or as a local or global function. Keep in mind that, instead of being referenced directly, this function is cloned and stored in a table so that it can be called by a console command.

The third argument is the key by which the entity is searched. In most cases, this can be left unchanged, as the key will be generated automatically based on the command. Internally, this uses the `ppmod.prev` function to search for the last (therefore newest) entity with a matching key. Because of this, it is suggested to use as descriptive of a key as possible in order to avoid accidentally finding a different entity that was created at the same time on a different thread. For example, instead of using `prop_weighted_cube` as the command, use `ent_create_portal_weighted_cube` instead, as this gives the entity a distinct "cube" targetname.

Here is an example of using `ppmod.create` to spawn a red cube at the player's feet:

```
  ppmod.create("ent_create_portal_weighted_cube", function(cube) {
    
    cube.SetOrigin( GetPlayer().GetOrigin() );
    cube.SetAngles( 0, 0, 0 );
    
    ppmod.fire(cube, "Color", "255 0 0");
    
  });
```

### ppmod.brush

Creates a brush entity of the specified type, returns a handle to it.

```
  ppmod.brush (position, size, type = "func_brush", angles = Vector())
```

The first argument is a vector to the center of the brush entity. The second argument is a vector containing the half-width of the brush on each respective axis. The third argument is the classname for the brush entity, "func_brush" by default. The last argument is a vector of the entity's angles - pitch, yaw and roll, respectively. Textures cannot be set, so the brush will remain invisible. Due to the limitations of creating entities with `CEntities` methods, some brush entity types might not function properly. To work around this, you can try using `ppmod.create` for creating the entity, then handling it with a code snippet from the `ppmod.brush` function:

```
  ppmod.create("func_movelinear", function(brush) {
  
    brush.SetOrigin( Vector(0, 0, 0) );
    brush.SetSize( Vector(-10, -10, -10), Vector(10, 10, 10) );
    
    ppmod.keyval(brush, "Solid", 3);
    
  });
```

### ppmod.trigger

Creates a brush entity that acts as a trigger of the specified type, returns a handle to it.

```
  ppmod.trigger (position, size, type = "once", angles = Vector())
```

The arguments are nearly identical to those of `ppmod.brush`, with the only exception being type. This argument is automatically prefaced with "trigger_" and specifies the type of brush entity to create. If the type is set to "once" (default), the trigger is automatically given an output to destroy itself when touched.

To add outputs to this trigger, you can store the handle returned by the function to then use `ppmod.addoutput` or `ppmod.addscript` on it. Here is an example of using `ppmod.trigger` to create a field that makes you say "Hello World!" in chat:

```
  local trigger = ppmod.trigger(Vector(0, 0, 0), Vector(128, 128, 128), "multiple");
  
  ppmod.addscript(trigger, "OnStartTouch", function() {
    SendToConsole("say Hello World!");
  });
```

### ppmod.texture

Creates an `env_projectedtexture` entity for projecting textures on to existing brushes and entities. Returns this entity.

```
  ppmod.texture (texture = "", position = Vector(), angles = Vector(90), simple = true, farz = 16)
```

The first argument is the path to the texture to apply. The second argument is the position of the `env_projectedtexture` entity. If using the simple projection mode, it is recommended to set this to be a few units away from the brush you're applying the texture to. The third argument is the angle to project the texture towards, facing straight down by default. The fourth argument is a boolean value for whether to use the simple projection mode. Simple projections only project textures on the world, aligning themselves with the shape and orientation of the brush. Keep in mind that this often causes graphical glitches like flickering, especially with high shader detail. If a projection is not simple, it will work similar to a flashlight, projecting and distorting the texture as if it were from a light source. The last argument is the FarZ keyvalue of the entity. This sets the furthest point that the projection can reach.

Every argument is optional. This is in case you need to create an `env_projectedtexture` for later use. Keep in mind that while Portal 2 claims to only support one projected texture at a time, a workaround exists. Since the game only checks for existing projected textures when one recieves a `TurnOn` or `TurnOff` input, multiple can be active as long as they never recieve such an input. One way to do this is by creating a new entity every timez` you wish to turn on the texture, then deleting it to turn it off.

Here is an example of using `ppmod.texture` to project a laser grid on the floor at the end of `sp_a1_intro3` using the simple projection mode:

```
  ppmod.texture("effects/laserplane", Vector(-1378, 3264, -310));
```

### ppmod.decal

Creates an `infodecal` entity for applying decals and textures on to the world, similar to the simple projection mode of `ppmod.texture`. Returns the decal entity.

```
  ppmod.decal (texture, position, angles = Vector(90))
```

The arguments are similar to those of `ppmod.texture`, except that texture and position are no longer optional. The benefits of using decals instead of simple projected textures are that decals cause fewer graphical glitches and stutters (as long as cvar `gpu_level` is under 2) and you can control the position of decals better. The main drawbacks are that decals cannot be moved, removed, or resized.

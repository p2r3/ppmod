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

More convenient alternative to EntFire, DoEntFire or EntFireByHandle. Most arguments are optional, containing default values similar to the ent_fire console command. This makes entity inputs much shorter and cleaner in code.


```
  ppmod.fire (entity, action = "Use", value = "", delay = 0, activator = null, caller = null)
```

The first argument is the entity to send an input to. This can be either an entity handle or a string. Next is the action, "Use" by default. Then the value, empty by default, the delay in seconds, 0 by default, and finally entity handles for the activator and caller, both null by default. Please note that the caller is only set if the entity is provided as a handle.

### ppmod.addoutput

More versitile alternative to ConnectOutput or EntFire AddOutput. Other than the entity, it's output and the target entity, every other argument is optional, with a common default placeholder value.

```
  ppmod.addoutput (entity, output, target, input = "Use", value = "", delay = 0, max = -1)
```

Since this function uses ppmod.fire internally, the entity can be specified with a string or handle. Similarly, the target entity can also be a string or handle. However, when provided a handle, it's targetname is used instead. If no targetname is set, one gets randomly generated and applied to the entity. The output is given as a string. The following arguments match their counterparts in ppmod.fire, with the exception being max, which sets the total amount of times this output will fire before being exhausted. Setting it to -1 (default) removes this limit.

### ppmod.addscript

Similar to ppmod.addoutput, used as a cleaner and more powerful way of attaching VScript code to entity outputs.

```
  ppmod.addscript (entity, output, script, delay = 0, max = -1)
```

The arguments are almost the same as the ones in ppmod.addoutput, except instead of specifying a target entity and input values, a script is required instead. This can be code within either a string or a function. Below is an example of attaching a local function to an entity output:

```
  ppmod.addscript("prop_button", "OnPressed", function() {
    printl("Button pressed!");
  });
```

### ppmod.keyval

Shorter, more convenient alternative to \_\_KeyValueFrom... functions. Automatically selects the approperiate function for the specified entity and keyvalue type.

```
  ppmod.keyval (entity, key, value)
```

The entity can be provided as a handle or string. However, when provided a string, EntFire AddOutput is used for applying the keyvalue. This might cause issues with asynchronous operations, as entity inputs are processed on a different thread. The key is expected to be a string, while the value may be an integer, boolean, float, string or Vector.

### ppmod.wait

Simple way of delaying the execution of a function. Creates a dummy logic_relay entity with an attached script. The timing is enforced by a delayed EntFire.

```
  ppmod.wait (script, delay)
```

The first argument is the script to run, either as a string or function. The second argument is the delay in seconds. Returns a handle to the logic_relay entity, in case the timer needs to be aborted by destroying this entity. After the script is executed, the logic_relay is automatically destroyed.

### ppmod.interval

Runs the specified script in regular intervals. Creates a logic_timer entity and configures it to run the script at an interval.

```
  ppmod.interval (script, delay = 0, name = "")
```

The first argument is the script to run, either as a string or function. The second argument is the interval of the loop, in seconds. When set to 0 (default), the function is called once every tick. The third argument sets the targetname for the logic_timer entity. This is provided mostly for backwards compatibility and for an alternative way of accessing the timer. Returns a handle to the logic_timer entity, which can then be used to stop or modify the loop.

### ppmod.once

Ensures that the specified script is run only once, even if this function is called multiple times. Creates a dummy logic_relay entity and uses it's targetname as a reference for duplicates. Or, if no name is provided, uses the script itself as a name.

```
  ppmod.once (script, name = null)
```

The first argument is the script to run, either as a string or function. The second argument is the targetname of the logic_relay entity. If no name is provided and the script is in the form of a string, the entire script gets used as a name. If the script provided is a function, it uses a pointer to the function as a name.

### ppmod.get

More convenient way of getting entity handles, replacing CEntities methods like FindByName or FindByClassnameNearest, instead automatically searching using multiple of these methods back to back. Also provides a way to get entities by their entity ID.

```
  ppmod.get (key, entity = null, argument = 1)
```

The first argument accepts a string, Vector, integer or instance. Different searches are performed depending on the type of key provided:
- If a string is provided, the function first searches for an entity with a matching targetname, then a matching classname, and finally a matching model. This is probably the most common type of search.
- If a vector is provided and the second argument is a string, the function attempts to find an entity with a matching classname around the vector's coordinates within the radius set by the third argument.
- If a vector is provided and the second argument isn't a string, the function returns an entity near the given vector in a radius set by the third argument.
- If an integer is provided, the function iterates through all entities, searching for an entity with an ID that matches the integer.
- If an instance is provided, the next entity in the list of entities is returned, similar to Entities.Next.

Please note that, if used excessively, this function may impact performance more than the native CEntities methods.

### ppmod.prev

Reverses iteration over a list of entities, finding the previous entity to match the given criteria. Similar to ppmod.get, but in reverse.

```
  ppmod.prev (key, entity = null, argument = 1)
```

The arguments and types of searches are nearly identical to ppmod.get, with the only exception being no support for a radius search by classname. Reversed iteration is performed by iterating forwards, then returning the last entity to not match the second argument. Because of the complexity and performance impact, this is not an efficient way of iterating backwards in most cases. Rather, iterate through your search once and use a table to then traverse backwards in. This function can, however, be used for conveniently finding the last matching element of a search if the second argument is set to null.

### ppmod.player

Provides more information about the player, as well as new ways of listening to the player's actions. Things like eye angles and jump, land, duck and unduck outputs are included.

```
  ppmod.player {
    enable ()
    eyes
    eyes_vec
    jump   (script)
    land   (script)
    duck   (script)
    unduck (script)
  }
```

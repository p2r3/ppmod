# ppmod
VScript library for rapid and comfortable prototyping of Portal 2 mods.

The focus of this project is to provide tools that assist in developing Portal 2 VScript mods faster and much more comfortably than through vanilla VScript. This involves adding syntactic sugar, new features, employing various workarounds for missing features or fixing broken ones through entities often specific to Portal 2. While ppmod strives to be performant, this does not come at the cost of reduced ease of use.

In other words, ppmod makes Portal 2's Squirrel feel less like a cheap hack, and more like a native game interface.

## Installation
Since ppmod version 4, the environment is expected to be as clean as possible, without any instantiated entities or vectors. This can be achieved by placing [ppmod.nut](https://github.com/p2r3/ppmod/blob/main/ppmod.nut) into `scripts/vscripts` and calling it at the very top of `mapspawn.nut`, after making sure that the current scope has server-side control:
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return; // Quit if the script is being loaded client-side
  IncludeScript("ppmod"); // Include ppmod as early as possible
```
Including ppmod in an already populated environment will still work at the cost of additional vector metamethods and entity method abstractions - that's the syntactic sugar mentioned earlier. This will get logged to the console as a warning, but is technically harmless if these features are unused.

## Getting started
Setting up and working with an environment like this for the first time can be overwhelming, so here's some boilerplate to help you get started.

This script will spawn a red cube in front of the player's head, and make it print to the console once it gets fizzled. This should provide a solid example that you can then play around with to get an idea of what it's like to work with ppmod.
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return;
  IncludeScript("ppmod");

  // This function is called whenever a map is fully loaded
  // We wrap it in async() to make it more comfortable to use asynchronous functions inline
  ppmod.onauto(async(function () {

    // Retrieve additional player info, like eye position and angles
    local pplayer = ppmod.player(GetPlayer());
    yield pplayer.init();

    // Props cannot be created with the CreateByClassname method, so we use ppmod.create instead
    yield ppmod.create("prop_weighted_cube");
    local cube = yielded;

    // Teleports the new cube to 64 units in front of the player's eyes
    local pos = pplayer.eyes.GetOrigin() + pplayer.eyes.GetForwardVector() * 64;
    cube.SetOrigin(pos);
    // Colors the cube red with the "Color" input
    cube.Color("255 0 0");
    // Connects a script function to the cube's "OnFizzled" output
    cube.OnFizzled(function () {
      printl("The red cube has been fizzled!");
    });
    // For other inputs/outputs, refer to: https://developer.valvesoftware.com/wiki/prop_weighted_cube

  }));
```

## Global utilities
These are essential utility functions, classes and methods that Portal 2's implementation of Squirrel and VScript should (arguably) have by default. This includes abstractions and shorthands of already existing features.

### min / max
Returns the smallest / largest of two values.
```squirrel
  min(0.5, 2) // Returns 0.5
  max(0.5, 2) // Returns 2
```

### round
Rounds a number to the specified precision in digits after decimal point, 0 by default.
```squirrel
  round(1.2345) // Returns 1.0
  round(1.2345, 2) // Returns 1.23
  round(5.5) // Returns 6
```

### Vector methods
#### Component-wise multiplication
```squirrel
  Vector(1, 2, 3) * Vector(2, 4, 8) // Returns Vector(2, 8, 24)
  Vector(1, 2, 3) * 2 // Still returns Vector(2, 4, 6)
```
#### Component-wise division
```squirrel
  Vector(1, 2, 3) / Vector(2, 4, 8) // Returns Vector(0.5, 0.5, 0.375)
  Vector(1, 2, 3) / 2 // Still returns Vector(0.5, 1, 1.5)
```
#### Equality check
```squirrel
  Vector(1, 2, 3).equals(Vector(1, 2, 3)) // Returns true
  Vector(1, 2, 3).equals(Vector(4, 5, 6)) // Returns false
```
#### More useful string output
```squirrel
  "The vector is: " + Vector(1, 2, 3) // Returns "The vector is: Vector(1, 2, 3)"
```
#### Fixed KV string output
```squirrel
  "The vector values are: " + Vector(1, 2, 3).ToKVString() // Returns "The vector values are: 1 2 3"
```
#### Inline normalization
```squirrel
  Vector(10, 5, 10).Normalize() // Returns Vector(0.666667, 0.333333, 0.666667)
  Vector(10, 5, 10).Normalize2D() // Returns Vector(0.894427, 0.447214, 0)
```

### Extended array class
The `pparray` class implements some additional array features not present in Portal 2's version of Squirrel. It can be initialized by either providing a size for a new array (and optionally a value to fill it with) or an existing array.
```squirrel
  local arr = pparray([1, 2, 3]);
```
#### More useful string output
```squirrel
  printl(arr) // Prints "[1, 2, 3]"
```
#### pparray.join
```squirrel
  arr.join(" - ") // Returns "1 - 2 - 3"
```
#### pparray.indexof
```squirrel
  arr.indexof(2) // Returns 1, which is the index of the first element with value 2.
```
#### pparray.find
```squirrel
  arr.find(function (a) {return a >= 2}) // Returns 1, which is the index of the first element to pass the compare function.
```
#### pparray.includes
```squirrel
  arr.includes(4) // Returns false, because the array does not contain the value 4.
```

### Extended heap class
The `ppheap` class implements a priority queue data structure using a heap. It supports basic heap operations such as inserting elements and retrieving the top element. The heap can be initialized with a maximum size and an optional comparator function. The default comparator constructs a min-heap.
```squirrel
  local heap = ppheap(10, function(a, b) { return a > b }); // Constructs a max-heap
```
#### ppheap.insert
```squirrel
  heap.insert(5)
  heap.insert(3)
  heap.insert(10)
  heap.size // Holds the heap size, which is now 3
```
#### ppheap.gettop
Retrieves the top element of the heap without removing it
```squirrel
  heap.insert(10)
  heap.gettop() // Returns 10
  heap.remove()
  heap.gettop() // Throws "Heap is empty"
```
#### ppheap.remove
```squirrel
  heap.insert(10)
  heap.remove() // Returns 10
  heap.remove() // Throws "Heap is empty"
```
#### ppheap.isempty
```squirrel
  heap.isempty() // Returns true if heap is empty, false otherwise
```
#### ppheap.bubbledown
```squirrel
  heap.insert(5)
  heap.insert(3)
  heap.insert(10)
  heap.bubbledown(2) // Sifts down the element at index 2 (10) to its correct position in the heap
```

### Extended string class
The `ppstring` class implements some additional string features not present in Portal 2's version of Squirrel. It can be initialized without arguments or by providing an existing string.
```squirrel
  local str = ppstring("Hello world!");
```
#### str.split
```squirrel
  str.split(" ") // Returns ["Hello", "world!"]
```
#### str.replace
```squirrel
  str.replace("l", "L") // Returns "HeLLo worLd!"
```
#### str.includes
```squirrel
  str.includes("world") // Returns true
```

### ppromise
Implements a JavaScript-like "promise" system for working with asynchronous operations.
```squirrel
  ppromise(func)
```
In Portal 2, there are numerous mutually unsyncronised threads, which can be a hassle to work with. Namely, console commands and entity actions are the most common offenders in generating asynchronous code. Historically, ppmod has used callback functions to accomodate for this, but since version 4, a "thenable" system was established for clarity and consistency.

Setting up a basic ppromise means wrapping a function with the `ppromise` constructor, which returns a ppromise instance. (Internally, these aren't actually classes or objects due to a workaround for a bug in Portal 2's Squirrel runtime.) Here is an example of a simple promise that resolves in 5 seconds:
```squirrel
  local wait = ppromise(function (resolve, reject) {
    ppmod.wait(function ():(resolve) {
      resolve("5 seconds have passed");
    }, 5);
  });
```

There are several ways of obtaining the result of a ppromise. The simplest by far is to attach a script to the `then`, `except`, or `finally` methods:
```squirrel
  // Prints "5 seconds have passed".
  wait.then(function (result) {
    printl(result);
  });

  // Prints either the value given to reject(), or any errors caught by the ppromise.
  wait.except(function (err) {
    printl(err);
  });

  // Called when the promise resolves, regardless of outcome
  wait.finally(function () {
    // perform cleanup, etc...
  });
```
Any number of functions can be attached to each output. Only one of `then` or `except` gets called (whichever is encountered first), while `finally` gets called regardless.

You can also get the value and state of a ppromise directly, though this isn't recommended:
```squirrrel
  wait.state // One of "pending", "fulfilled", or "rejected"
  wait.value // The value passed to either resolve() or reject()
```

Lastly, the value of a ppromise can be resolved inline via async functions.

### async
To improve code clarity and reduce nesting, ppmod implements JavaScript-like `async` functions, which can resolve `ppromise`s inline using the `yield` keyword, which in this case works similarly to JavaScript's `await`.
```squirrel
  async(func)
```

The simplest way of declaring such a function is to wrap it in `async()`. Here is an example of such a function that waits for `ppmod.create` to spawn an entity:
```squirrel
  local createCube = async(function () {

    yield ppmod.create("prop_weighted_cube");
    local cube = yielded;

    cube.SetOrigin(Vector(...));
    ...

  });

  // Can be called like a normal function
  createCube();
```
There are some important things to note here. Firstly, for context, here `ppmod.create` returns a `ppromise` that resolves to the created entity's handle. Secondly, `yield` on its own does not return this value. These `async` functions work by exploiting Squirrel's generators, which leads to admittedly hacky syntax. The value of the last `yield`ed `ppromise` is instead stored in the `yielded` global.

Due to a bug in how Portal 2 handles restoring the script scope from save files, saving before an `async` function has finished running can lead to game freezes or crashes. It is therefore not recommended to use `async` functions in tick loops, and instead reserve them for one-time events like map loads or entity outputs.

## Entity management
These functions help with the Source entity input/output system. They mostly consist of streamlined versions of existing essential functions.

### ppmod.get
Searches for an entity by various criteria and returns its handle. Searches can be done by:
- Targetname
- Classname
- Model
- Entity index
- Position (more on that later)

Here are some examples of finding the first laser cube on `sp_a2_triple_laser`:
```squirrel
  ppmod.get("new_box") // By targetname
  ppmod.get("prop_weighted_cube") // By classname
  ppmod.get("models/props/reflection_cube.mdl") // By model
  ppmod.get(51) // By entity index (not recommended)
```

Iterating over entities can be done by providing the previous entity's handle as the second argument:
```squirrel
  local first = ppmod.get("prop_testchamber_door"); // First chamber door (usually entrance)
  local second = ppmod.get("prop_testchamber_door", first); // Second chamber door (usually exit)
```

Or, to iterate over every cube in a map:
```squirrel
  local cube = null;
  while (cube = ppmod.get("prop_weighted_cube", cube)) {
    printl("Cube found at: " + cube.GetOrigin());
  }
```

As mentioned before, searches can also be performed by position:
```squirrel
  ppmod.get(Vector(7687, -5863, 18)) // Starting position of the first cube on sp_a2_triple_laser
  ppmod.get(Vector(7687, -5863, 18), 8) // Same search, but narrowed down to a 8 unit radius (default is 32)
```

You can also apply a filter containing any of the previously mentioned search criteria to narrow down a position search:
```squirrel
  local playerPos = GetPlayer().GetOrigin();
  local radius = 1024;

  // Search for a chamber door within 1024 units of the player
  ppmod.get(playerPos, radius, "prop_testchamber_door");
```

### ppmod.validate
Checks whether the input argument is a valid entity handle. Performs a type check, class check, and calls the `IsValid()` method.
```squirrel
  local cube = ppmod.get("prop_weighted_cube");
  ppmod.validate(cube); // Returns true
  cube.Destroy();
  ppmod.validate(cube); // Returns false
```

### ppmod.forent
Runs a callback function for every valid entity that matches the search. First argument is an array of `ppmod.get` arguments, the second argument is the callback function, which is provided each iteration's respective entity.
```squirrel
  ppmod.forent(["prop_weighted_cube"], function (cube) {
    printl("Cube found at: " + cube.GetOrigin());
  });
```

### ppmod.prev
Performs a `ppmod.get` search in reverse. Useful for finding the last entity of a sequence.
```squirrel
  ppmod.prev("prop_testchamber_door"); // Gets the last door in the map (as indexed by the engine)
```

### ppmod.fire
Fires an input to an entity, either by classname, targetname, entity handle, or ppmod.forent query.
```squirrel
  ppmod.fire(target, action, value, delay, activator, caller)
```
This functions very similarly to methods like `DoEntFire` or `EntFireByHandle`, with some additional quality-of-life changes:
- The `target` may be either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Every argument other than the `target` holds a default placeholder value.
- The `value` is automatically converted to a string.

This means that `ppmod.fire` can be used as a universal shorthand for firing inputs to entities. All of the following examples are valid:
```squirrel
  ppmod.fire("prop_weighted_cube", "Dissolve", "", 2, null, null); // Fizzle all cubes in 2 seconds
  ppmod.fire("named_cube", "Dissolve"); // Fizzle a specific cube
  ppmod.fire([Vector(...), 128, "prop_weighted_cube"], "Dissolve"); // Find all cubes within a 128u radius and fizzle them
```

### ppmod.keyval
Sets a keyvalue for an entity provided by either classname, targetname or handle.
```squirrel
  ppmod.keyval(entity, key, value)
```
This functions similarly to `__KeyValueFrom...` methods, or the keyvalue format of the `AddOutput` input. The differences are:
- The `entity` may be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Value types are detected and converted automatically.
- The keyvalue is applied instantly, skipping the entity I/O queue.

Similarly to `ppmod.fire`, this functions as a universal shorthand for keyvalues. Here are some valid examples:
```squirrel
  ppmod.keyval("prop_weighted_cube", "RenderColor", "255 0 0"); // Colors all cubes red
  ppmod.keyval("cube1", "Targetname", "cube2"); // Changes the name of "cube1" to "cube2"
  ppmod.keyval("weapon_portalgun", "CanFirePortal1", false); // Disables the portal gun's blue portal
  ppmod.keyval([Vector(...), 128], "angles", Vector(-90, 0, 0)); // Rotates entities within a 128u radius to face directly upwards
```

### ppmod.flags
Sets an entity's spawnflags. This is really just an abstraction of the "SpawnFlags" keyvalue.
```squirrel
  local trigger = ppmod.get(Vector(...), 32, "trigger_once");
  ppmod.flags(trigger, 1, 2, 8); // Makes a trigger react to clients, NPCs and physics props
```
The flags are provided as a variable number of arguments and are summed up to create the value set as the SpawnFlags keyvalue.

### ppmod.addoutput
Connects an entity output to another entity's input. For more info on entity I/O, [see here](https://developer.valvesoftware.com/wiki/Inputs_and_Outputs).
```squirrel
  ppmod.addoutput(entity, output, target, input, value, delay, max);
```
The arguments of this function are identical to those used in Hammer or those passed to the `AddOutput` input. Note that:
- The `entity` and `target` may be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`.
- Outputs are added instantly, skipping the entity I/O queue.
- Quotes and special characters are safe to use, with the exception of `\x1B`.

### ppmod.addscript
Similar to its sister function `ppmod.addoutput`, but instead of firing an input when an output is received, a script function is called.
```squirrel
  ppmod.addscript(entity, output, script, delay, max)
```
The arguments here are similar to those in `ppmod.addoutput`, except for `script`, which may be either a string of Squirrel code, or a function. The scope of the attached function is provided with handles to `self`, `activator`, and `caller`.

### ppmod.runscript
Runs a script as the specified entity. Nearly identical to `ppmod.fire(entity, "RunScriptCode", script)`, with the exception that the script can be either a string or a script function.
```squirrel
  ppmod.runscript(entity, script)
```

### ppmod.setparent
Sets the parent of the given child entity to a parent entity, joining their movement together.
```squirrel
  ppmod.setparent(child, parent)
```
Both the parent and the child can be provided as either a string, entity handle, or an (array of) argument(s) passed to `ppmod.get`. Setting the parent to a falsy value like `null` will remove any parent from the child. This acts as a cleaner alternative to the `SetParent` and `ClearParent` entity inputs.

### ppmod.hook
Sets an entity's [input hook](https://developer.valvesoftware.com/wiki/VScript_Fundamentals#Input_Hooks).
```squirrel
  ppmod.hook(entity, input, script, max)
```
The given script function gets called whenever the entity receives the specified input. If this function returns `false`, the input is discarded. Otherwise, it gets executed as per usual. This can be used to make specific inputs conditional, or to disable them outright. Note that input names are case sensitive, and _typically_ use the CamelCase format, though that depends on how the input is fired. The scope of the attached function is provided with handles to `self`, `activator`, and `caller`.

## Shorthands for entity management
Many of the functions documented above are also implemented as methods in most entity classes (assuming that ppmod was included before entities were instantiated). This provides some syntactic sugar that makes entity code shorter and cleaner.

### Keyvalue assignment
Keyvalues can be assigned as a property of an entity's handle.
```squirrel
  local pgun = ppmod.get("weapon_portalgun");
  pgun.CanFirePortal1 = false; // Disables the portal gun's blue portal
```
Note that you cannot retrieve keyvalues this way.

### Firing inputs
Inputs can be fired by calling them as a method of an entity's handle. All arguments remain optional, and are ordered just like in `ppmod.fire`.
```squirrel
  local cube = ppmod.get("prop_weighted_cube");
  cube.Color("255 0 0", 2.5); // Colors the cube red after 2.5 seconds
```
Alternatively, you can fire inputs by calling the `Fire` method of the handle.
```squirrel
  cube.Fire("Dissolve"); // Fizzles the cube
```

### Adding outputs
Outputs can be added via the `AddOutput` method of an entity's handle. Arguments remain the same as with `ppmod.addoutput`.
```squirrel
  ent.AddOutput(output, target, input, value, delay, max)
```
Similarly, scripts can be added via the `AddScript` method.
```squirrel
  ent.AddScript(output, scr, delay, max)
```
Scripts can also be added by calling the output as a method of the entity handle and providing a function as the first argument.
```squirrel
  cube.OnFizzled(function, delay, max)
```

### Running scripts
The `RunScript` method acts as a shorthand of `ppmod.runscript`.
```squirrel
  ent.RunScript(script)
```

### Parenting
Entities can be parented via the `SetMoveParent` method. Behavior is the same as with `ppmod.setparent`.
```squirrel
  ent.SetMoveParent(parent)
```
Note that the method `GetMoveParent` exists in Portal 2 by default, and can be used to retrieve the parent entity handle.

### Hooking inputs
Hook functions can be added to inputs via the `SetHook` method. Arguments remain the same as with `ppmod.hook`.
```squirrel
  ent.SetHook(input, script, max)
```

### Sanitized SetOrigin and SetAngles methods
The base `SetOrigin`, `SetAbsOrigin` and `SetAngles` methods are overridden to sanitize input arguments and to allow for seamless switching between component-wise and vector input.

By default, nothing prevents you from accidentally setting a coordinate or angle of an entity to `nan` or `inf`, both of which cause undefined behavior and crashes. These overrides will throw an exception if such values are detected.

Additionally, `SetOrigin` and `SetAbsOrigin` now accept component-wise input, and `SetAngles` now accepts PYR vector input:
```squirrel
  ent.SetOrigin(Vector(x, y, z)) // Still valid
  ent.SetOrigin(x, y, z) // Also valid

  ent.SetAngles(p, y, r) // Still valid
  ent.SetAngles(Vector(p, y, r)) // Also valid
```

### SetVelocity and GetVelocity methods for props
In Portal 2, `GetVelocity` and `SetVelocity` refer to the QPhys velocity values by default. These methods are overridden for props in ppmod to allow for similar behavior to what is expected. These methods remain unchanged for player entities.

The `GetVelocity` method returns a `ppromise` which resolves to a velocity Vector obtained by interpolating the position of the entity over two ticks:
```squirrel
  // Prints the velocity of `ent`
  ent.GetVelocity().then(printl);
```

The `SetVelocity` method first obtains an estimate of the current velocity using the `GetVelocity` override above, computes the difference between that and the input, and then uses `ppmod.push` to apply the new velocity.
```squirrel
  // Sets the velocity of `ent` to 200ups upward
  ent.SetVelocity(Vector(0, 0, 200));
```

## Control flow
These functions implement additional features to VScript's program control flow, like timers and intervals, essential for game programming.

### ppmod.wait
Runs the given script after the specified time.
```squirrel
  ppmod.wait(script, seconds, name)
```
The script may be provided as either a string of VScript or a function. The time is to be provided in seconds, and can be either an integer or a float. The `name` argument is optional. If set, it names the underlying `logic_relay` entity, which can then be found and destroyed, aborting the timer.

Here is an example of using this function to fizzle a cube in 2 seconds, unless the player picks it up before then:
```squirrel
  local cube = ppmod.get("prop_weighted_cube");

  ppmod.wait(function ():(cube) {
    cube.Dissolve();
  }, 2.0, "wait_dissolve");

  ppmod.addoutput(cube, "OnPlayerPickup", "wait_dissolve", "Kill");
```
Note that this function returns a handle for the `logic_relay` entity, which can also be used to destroy the timer without having to give it a name:
```squirrel
  local timer = ppmod.wait(...);
  if (condition) timer.Destroy();
```

### ppmod.interval
Runs the given script repeatedly in the specified time interval.
```squirrel
  ppmod.interval(script, seconds, name)
```
The arguments for this function are nearly identical to those used for `ppmod.wait`, with the only exception being that the time is optional. If the interval time is not set (or if set to 0), the script will get called on every entity tick.

Here is an example of a script that hurts the player every 0.5 seconds if they aren't standing on a cube:
```squirrel
  local player = GetPlayer();

  ppmod.interval(function ():(player) {

    local feetpos = player.GetOrigin() - Vector(0, 0, 18);
    local cube = ppmod.get(feetpos, 8, "prop_weighted_cube");

    if (!cube) {
      player.SetHealth(player.GetHealth() - 20);
    }

  }, 0.5);
```

### ppmod.ontick
Runs the given script for every console tick, or waits the specified amount of ticks to run a script.
```squirrel
  ppmod.ontick(script, pause, timeout)
```
The `script` may be provided as either a string of VScript, or a function. If `pause` is set to `true` (default), the loop will not run while the game is paused. If `timeout` is set to `-1` (default), the loop will run indefinitely for every tick. Otherwise, this function acts as a timer, and will wait for the specified amount of ticks to pass before running the script once.

Here is a simple example that will print "Hello Portal 2!" to the console every tick, even when the game is paused.
```squirrel
  ppmod.ontick(function () {
    printl("Hello Portal 2!");
  }, false);
```
Note that it is generally recommended to use `ppmod.interval` or `ppmod.wait` instead, where applicable. This function will not preserve its ticks through save files, and large scale use of `ppmod.ontick` loops can theoretically cause console buffer overruns. The only recommended usecase for this function is for keeping time during game pauses.

### ppmod.onauto
Runs the given script once the map has fully loaded.
```squirrel
  ppmod.onauto(script, onload)
```
The `script` may be provided as either a string of VScript, or a function. The `onload` argument is optional (`false` by default), and when set to `true`, calls the provided script on not only the initial map load, but also any save file loads.

This function is essential for almost any gameplay modding, and will often appear at the top of many ppmod scripts, as most entities are not accessible until the map has fully loaded. In single-player, this means waiting for the `logic_auto` entity to fire. In networked co-op games, this function also waits for the remote player (P-body) to fully connect before calling the script.

### ppmod.detach
Works around script timeouts by catching the exception they throw.
```squirrel
  ppmod.detach(script, args)
```
In Portal 2's implementation of Squirrel, scripts (queries) are given a limited time to run, so that a simple `while (true)` loop doesn't hang the game. For compute-intensive operations, this can mean that the script is aborted before calculations are finished. When this happens, the VM throws a `Script terminated by SQQuerySuspend` exception. This function catches that exception, and calls the given function again, passing it the arguments from the previous run. If a different exception is caught, ppmod traces it back to the line on which `ppmod.detach` was called. Note that some of the trace data is unfortunately lost this way.

The `script` argument expects a function which is passed one argument - a table. The `args` argument is this table, which is passed back to the function every time it is called. Here is an example of using this function to call a for loop which increments an integer until it overflows:
```squirrel
  ppmod.detach(function (args) {

    while (args.i >= 0) args.i ++;
    printl("i overflowed to " + args.i);

  }, { i = 0 });
```
Note that this will most likely take some time to run, during which the game will freeze. Be careful not to leave infinite loops running like this, since the only other safeguard is, theoretically, a stack overflow.

## Player interface
Provides more information about and ways to interact with a player.
```squirrel
  local pplayer = ppmod.player(player)
  pplayer.init().then(function (pplayer) { ... })
```
The constructor for this class expects one argument - the entity handle of a player. Some of its routines are asynchronous. To test whether the instance has fully initialized, await the `ppromise` returned by `pplayer.init`.

### pplayer.init
Returns a `ppromise` that resolves once the asynchronous routines have finished running.
```squirrel
  local pplayer = ppmod.player(GetPlayer());
  pplayer.init().then(function (pplayer) {
    // Interfaces such as `eyes` and `gravity` are guaranteed to work here
  });
```

### pplayer.ent
Holds the entity handle that was used to instantiate this `pplayer` instance.
```squirrel
  local pplayer = ppmod.player(GetPlayer());
  pplayer.ent == GetPlayer() // true
```

### pplayer.eyes
Provides accurate eye position and angles.
```squirrel
  pplayer.eyes.GetOrigin() // Eye position
  pplayer.eyes.GetAngles() // Eye angles
  pplayer.eyes.GetForwardVector() // Eye facing vector
```
In Portal 2, retrieving the player's angles directly will return the rotation of the player model, which differs significantly from the player's view angles. Instead, `pplayer.eyes` uses a `logic_measure_movement` entity, which can be referenced for accurate eye position.

### pplayer.proxy
Holds the handle of the `logic_playerproxy` used for listening to jumping/ducking
```squirrel
  // Changes the portalgun bodygroup to show PotatOS
  ppmod.fire(pplayer.proxy, "AddPotatosToPortalgun");
```

### pplayer.gameui
Holds the handle of the `game_ui` entity used for listening to player movement inputs
```squirrel
  // Enable the Freeze Player spawnflag
  ppmod.flags(pplayer.gameui, 32);
```

### pplayer.holding
Returns `true` if the player is holding a prop, `false` otherwise.
```squirrel
  pplayer.holding() // Returns true or false
```

### Event listeners
Allows for listening to player actions. Each of these functions expects one argument - a function to attach. Multiple functions can be attached to one event.
- `pplayer.onjump` - Fired when the player issues a jump input.
- `pplayer.onland` - Fired when the player lands from a jump or fall.
- `pplayer.onduck` - Fired when the player starts the crouching animation.
- `pplayer.onunduck` - Fired when the player finishes the uncrouching animation.

Here is an example of using `pplayer.onjump` to listen for jumps:
```squirrel
  local pplayer = ppmod.player(GetPlayer());

  // Note: this will fire for every jump input, including those issued mid-air
  // To listen only for initial jumps, check that pplayer.grounded is true
  pplayer.onjump(function () {
    printl("The player has jumped!");
  });
```

### pplayer.ducking
Returns `true` if the player is in the process of ducking/unducking, `false` otherwise.
```squirrel
  pplayer.ducking() // Returns true or false
```

### pplayer.grounded
Returns `true` if the player is on the ground, `false` otherwise.
```squirrel
  pplayer.grounded() // Returns true or false
```

### pplayer.oninput
Allows for listening to player inputs.
```squirrel
  pplayer.oninput(input, script)
```
The `input` argument expects a string specifying the input command to listen for. The `script` argument can be either a function, or a string of VScript code. Note that only the inputs provided by `game_ui` are supported, namely:
- `+moveleft` and `-moveleft`
- `+moveright` and `-moveright`
- `+forward` and `-forward`
- `+back` and `-back`
- `+attack` and `-attack`
- `+attack2` and `-attack2`

Here is an example of using `pplayer.oninput` to listen for when the player has attempted to shoot a portal:
```squirrel
  local pplayer = ppmod.player(GetPlayer());

  // Note: this will fire for every +attack input, even if the player can't shoot portals
  pplayer.oninput("+attack", function () {
    printl("Portal shot attempted!");
  });
```

### pplayer.gravity
Changes the player's gravity without affecting the gravity of other players or entities.
```squirrel
  pplayer.gravity(gravity)
```
One argument is expected - a multiplier for the strength of the player's gravity. A value of `1` will leave it unchanged, a value of `0` will disable gravity entirely, a value of `2` will make it twice as strong, and so on.

Note: **This will throw if all async routines have not finished.** To ensure this works, wait for `pplayer.init()` to resolve.

### pplayer.friction
Changes the player's friction without affecting the friction of other players or entities.
```squirrel
  pplayer.friction(factor)
```
The `friction` argument holds the same meaning as the `sv_friction` console variable, which is hidden and inaccessible by default in Portal 2.

Here is an example of setting the player's friction to 2, which is half of the default value:
```squirrel
  local pplayer = ppmod.player(GetPlayer());
  pplayer.friction(2.0);
```
Note that the calculations performed expect the value of `sv_friction` to be `4`, which it is by default, and typically cannot be changed without unlocking the console variable via a plugin.

## World interface
These functions provide ways to interact with the world and physical entities.

### ppmod.create
Creates an entity by running the given command and retrieves its handle.
```squirrel
  ppmod.create(command, key)
```
The `command` argument is the console command to run for creating the entity. Provided just an entity classname, the function uses the `ent_create` command. Providing a model path (any string ending with `.mdl`) will use `prop_dynamic_create`. The `key` argument is optional, and can be used to specify the exact criteria by which to search for the newly created entity. If not provided, the `key` is guessed from the input command. The function returns a `ppromise`, which resolves with the handle of the newly created entity.

In Portal 2, creating an entity with methods like `Entities.CreateByClassname` or `CreateProp` can be problematic, especially if the entity is complicated, is a physics prop, or isn't precached in some way. This is because these methods don't run initialization code often required for full functionality of many entities. Console commands are better in this regard, but pose a new issue - after an entity has been created, consistently getting a reference to it in VScript can be hard. This is why `ppmod.create` exists.

Here are a few examples of creating cubes with this function:
```squirrel
  // The simplest method, just providing the classname
  ppmod.create("prop_weighted_cube").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });

  // Using the game-specific command for spawning a companion cube
  ppmod.create("ent_create_portal_companion_cube").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });

  // Using prop_physics_create to spawn a generic physics prop with the reflection cube model
  ppmod.create("prop_physics_create props/reflection_cube.mdl").then(function (cube) {
    cube.SetOrigin(Vector(...));
  });
```

Note that excessive back-to-back use of `ppmod.create` can cause the wrong handle to be returned. For cases where a large number of entities needs to be spawned, it is recommended to either spread the spawns across ticks in batches, or to use `ppmod.give` or `CreateProp` where applicable, assuming in the latter case that the model has been precached.

### ppmod.give
Creates a variable amount of entities under the player's feet.
```squirrel
  ppmod.give(entities)
```
The `entities` argument expects a table, where the slots are entity classnames, and each slot's value represents the amount of that entity to spawn. This function returns a `ppromise` which resolves to an array of entities created by this function.

While this functions a lot like the `give` console command, no console commands are actually used. Instead, the `game_player_equip` entity is spawned temporarily. This function is a great way to spawn many entities in bulk.

Here is an example of spawning a single cube at the player's feet with this function:
```squirrel
  ppmod.give({ prop_weighted_cube = 1 }).then(function (ents) {
    local cube = ents.prop_weighted_cube[0];
    // ... do something with cube
  });
```

### ppmod.brush
Creates a solid, invisible brush entity.
```squirrel
  ppmod.brush(position, size, type, angles, create)
```
The `position` argument is a Vector to the center of the brush. The `size` argument is a Vector containing the half-width of the brush along each axis. The `type` argument is the classname of the brush entity as a string. The `angles` argument (optional) expects a Vector, with the properties being pitch, yaw, and roll for X, Y, and Z, respectively. Lastly, the `create` argument (optional) is a boolean, specifying whether or not to use `ppmod.create` for creating the brush instead of `Entities.CreateByClassname` to work around unloaded entity features. If `create` is `false` (default), this function returns a handle to the newly created brush entity. If `create` is `true`, it creates a `ppromise` which resolves to a handle for the brush entity.

Here is an example of creating an invisible, outlined box at the center of the `sp_a2_triple_laser` chamber:
```squirrel
  local brush = ppmod.brush(Vector(7808, -5629, 64), Vector(32, 32, 32), "func_brush");
  ppmod.keyval(brush, "Targetname", "test_brush");

  SendToConsole("developer 1");
  SendToConsole("ent_bbox test_brush");
```
Note that these brush entities cannot be assigned custom textures or complex shapes, as that requires a model for the brush to be precompiled into the map. Many brush entities may also not function as expected, even with `create` set to `true`.

### ppmod.trigger
Similar to `ppmod.brush`, creates a non-solid trigger volume entity.
```squirrel
  ppmod.trigger(position, size, type, angles, create)
```
The arguments and return values are the exact same as those used for `ppmod.brush`, refer to the documentation of that function.

The primary differences between this function and `ppmod.brush` are the output entity's spawn flags and the lack of collision. Every entity created via this function has its `SpawnFlags` keyvalue set to `1`, which in most cases means that only players can trigger it. This can, of course, later be changed to account for other entities and props. Another notable exception is that if a trigger's `type` is set to `trigger_once`, it will automatically remove itself after being touched.

Here is an example of creating an invisible, outlined trigger at the center of the `sp_a2_triple_laser` chamber, which spawns a cube once the player touches it:
```squirrel
  local trigger = ppmod.trigger(Vector(7808, -5629, 64), Vector(32, 32, 32), "trigger_once");
  ppmod.keyval(trigger, "Targetname", "test_trigger");

  ppmod.addscript(trigger, "OnStartTouch", function () {
    ppmod.create("prop_weighted_cube").then(function (cube) {
      cube.SetOrigin(Vector(7808, -5629, 128));
    });
  });

  SendToConsole("developer 1");
  SendToConsole("ent_bbox test_trigger");
```

### ppmod.project
Creates a projected texture of the given texture and returns its handle.
```squirrel
  ppmod.project(material, position, angles, simple, far)
```
The `material` argument expects a path to the material (texture) to be projected. Self-illuminating textures work best. The `position` argument is a Vector to the origin of the projection. The `angles` argument (optional) expects a Vector containing the orientation of the projection with the properties being pitch, yaw, and roll for X, Y, and Z, respectively. If not provided, the entity will point directly downward (pitch 90). The `simple` argument (optional) is a boolean, denoting whether the projection is "simple" (i.e. applied flat to the nearest brush) or a true projection (`false` by default). The `far` argument (optional) specifies how far out the texture should be projected in Hammer units (128 by default).

Here is an example of projecting a red arrow on a wall in the `sp_a2_triple_laser` chamber entrance:
```squirrel
  // Projections require shadows to be enabled
  SendToConsole("r_shadows 1");

  // Prevent any other lights from turning on (explained in docs)
  ppmod.forent(["env_projectedtexture"], function (light) {
    ppmod.hook(light, "TurnOn", function () { return false });
  });

  // Spawn the arrow projection
  ppmod.project("signage/underground_arrow", Vector(7840, -5200, 81), Vector(0, 180), false, 70);
```
Note that by default, Portal 2 only allows one projected texture to exist at a time. However, this check is only performed when the `TurnOn` input is called on an `env_projectedtexture` entity. By disabling this input via an input hook, we prevent this check from being run by, for example, chamber entrance triggers. Projected textures spawn turned on by default, therefore the input isn't actually necessary in most cases.

### ppmod.decal
Applies decals on world brushes.
```squirrel
  ppmod.decal(material, position, angles, far)
```
The `material` argument expects a path to the material (texture) for the decal. The `position` argument is a Vector to some point on the brush where the decal should be applied. The `angles` argument (optional) expects a Vector containing the orientation of the projection with the properties being pitch, yaw, and roll for X, Y, and Z, respectively. If not provided, the entity will point directly downward (pitch 90). However, in practice, the angle seems to affect very little. The `far` argument (optional) limits how far away the decal can be cast. If not provided, set to 8 units by default.

While projected textures are best used for dynamically overlaying light projections on surfaces, decals can be useful for either their intended purpose (i.e. bullet holes, explosion dust), or for essentially changing the textures of entire brushes. Here is an example of making the back wall of the `sp_a2_triple_laser` chamber non-portalable:
```squirrel
  // Ensuring decals are enabled
  SendToConsole("r_drawdecals 1");
  // This is required for making large decals less glitchy
  SendToConsole("gpu_level 1");

  // Create the decal to color the wall black
  ppmod.decal("metal/black_wall_metal_002b", Vector(7968, -5440, 128));

  // Create a brush to prevent portal placement
  ppmod.brush(Vector(7968, -5408, 128), Vector(1, 96, 128), "func_brush");
```
Note that if you plan to use materials which aren't intended for use as decals, it is recommended to set `gpu_level` to `1` or `0` (no real difference between these values), as otherwise the normal/bumpmap data of the material can cause the texture to flicker.

### ppmod.ray
Traces a ray between two points, returning points of collision with the world or entities.
```squirrel
  ppmod.ray(start, end, entity, world, portals, ray)
```
The `start` and `end` arguments are Vectors to the start and end points of the ray, respectively.

The `entity` argument (optional), specifies which entities to test for collisions with the ray. This can be either a single entity handle, a non-array `ppmod.foreach` argument, or an array. If an array is provided, it may contain entity handles, `ppmod.foreach` arguments (including arrays), or sequential pairs of Vectors describing the origin and half-width of an arbitrary axis-aligned bounding box. If `null` or not specified, no collision with entities will be calculated.

The `world` argument (optional, `true` by default) is a boolean, denoting whether or not collisions with static world geometry should be considered.

The `portals` argument (optional) can be used to enable tracing rays through portals when provided an array of sequential `prop_portal` handle pairs. If `null` or not specified, rays will not teleport through portals.

The `ray` argument (optional) is mostly intended for use internally, though can also be used to reduce the calculations for multiple consecutive rays. More on this later.

This constructor returns an object with the following attributes:
- `fraction` - a fraction along the line where an intersection occurred;
- `point` - the point of intersection;
- `entity` - the closest intersected entity (`null` if none).

Here is an example of drawing a box at the location where a ray cast 256 units from the player's eyes intersects either the world or a cube each tick:
```squirrel
  // Allow for drawing the intersection box through portals
  SendToConsole("cl_debugoverlaysthroughportals 1");

  ppmod.player(GetPlayer()).init().then(function (pplayer) {
    ppmod.interval(function ():(pplayer) {

      // Cast a ray 256 units forward from the player's eyes
      local start = pplayer.eyes.GetOrigin();
      local end = start + pplayer.eyes.GetForwardVector() * 256;

      // Create an array containing all portals on the current map
      local portal = null, portals = [];
      while (portal = ppmod.get("prop_portal", portal)) portals.push(portal);
      // Don't use portal passthrough if we don't have a full pair
      if (portals.len() % 2 != 0) portals = null;

      // This ray will collide with the static world, cubes, and will pass through portals.
      local ray = ppmod.ray(start, end, "prop_weighted_cube", true, portals);

      // If the ray didn't intersect anything, don't draw a box.
      if (ray.fraction == 1.0) return;

      // If the ray hit a cube, draw a green box. Otherwise, draw a red box.
      if (ray.entity) {
        DebugDrawBox(ray.point, Vector(-2, -2, -2), Vector(2, 2, 2), 0, 255, 0, 100, -1);
      } else {
        DebugDrawBox(ray.point, Vector(-2, -2, -2), Vector(2, 2, 2), 255, 0, 0, 100, -1);
      }

    });
  });
```
Note that only the axis-aligned bounding boxes of entities are checked for intersections, which may lead to slight mismatches with the actual model of some props.

As mentioned before, multiple similar calls to `ppmod.ray` can be optimized using the `ray` argument. Note that this is very situational, and probably won't matter in most cases. Regardless, here's how the value of `ray` is calculated:
```squirrel
  local dir = end - start;
  local len = dir.Norm();
  local div = [1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z];

  local ray = [len, div];
```

### ppmod.inbounds
Checks whether a point is inbounds.
```squirrel
  ppmod.inbounds(point)
```
This function accepts one argument - a Vector to the point which the check is to be performed on. It returns a boolean - `true` if the point is inbounds, and `false` if it isn't. Note that this function can return false positives in super specific cases, but is generally safe to use for any of the campaign maps.

### ppmod.visible
Checks whether a point is within line of sight.
```squirrel
  ppmod.inbounds(eyes, point, fov)
```
The `eyes` argument expects an entity handle to use as the subject for the check. A `ppmod.player` instance's `eyes` handle works well for this if the subject is a player. The `point` argument expects a Vector with absolute coordinates to the target point. If your line-of-sight check needs a range limit, you'll need to enforce that manually. The `fov` argument expects a number - the field-of-view in which the target is considered visible.

Note that this check performs no ray collision checks with dynamic entities. Additionally, very thin walls like the ones seen in the puzzles in act 3 of the singleplayer campaign may be considered see-through. Limiting the visible range may be a solution.

### ppmod.button
Creates a button prop and fixes common issues associated with spawning buttons dynamically.
```squirrel
  ppmod.button(type, position, angles)
```
The first argument is the classname for the button. All of the Portal 2 floor and pedestal buttons are supported. The `position` argument is a Vector to the spawn position of the new button. The `angles` argument (optional) expects a Vector, with the properties being pitch, yaw, and roll for X, Y, and Z, respectively. If not set, all angles will be 0. This function returns a `ppromise`, which resolves to a table. The contents of this table differ depending on the type of button spawned.

If a pedestal button is spawned, the `ppromise` resolves to this table:
- `GetButton()` - returns the `func_rot_button` entity used for registering `+use` presses;
- `GetProp()` - returns the `prop_dynamic` entity acting as the physical button;
- `SetDelay(delay)` - sets a delay in seconds before the button can be pressed again;
- `SetTimer(enabled)` - enables or disables the ticking timer sound, expects a boolean, doesn't actually delay the output;
- `SetPermanent(enabled)` - enables or disables locking the button down, expects a boolean;
- `OnPressed(script)` - attaches the given script string or function to the button's `OnPressed` event.

If a floor button is spawned, the `ppromise` resolves to this table:
- `GetTrigger()` - returns the `trigger_multiple` entity used for detecting collisions;
- `GetProp()` - returns the `prop_dynamic` entity acting as the physical button;
- `GetCount()` - returns the amount of entities currently holding down the button;
- `OnPressed(script)` - attaches the given script string or function to the event of the button being pressed.
- `OnUnpressed(script)` - attaches the given script string or function to the event of the button being released.

The reason this entity exists is that buttons created dynamically, even when using commands like `ent_create`, are broken in several ways by default. Instead, `ppmod.button` reconstructs the button from the ground up and simulates its behavior in VScript.

Here is an example of creating a button that opens the exit door on `sp_a2_triple_laser`:
```squirrel
  ppmod.button("prop_button", Vector(7200, -5280, 0)).then(function (button) {

    button.OnPressed(function () {
      ppmod.fire("@exit_door-door_open_relay", "Trigger");
    });
    button.SetPermanent(true);

  });
```

### ppmod.catapult
Launches a physics prop in the given direction.
```squirrel
  ppmod.catapult(entity, vector)
```
The first argument is the entity to launch. The second argument is a Vector, the direction of which is used to control the launch trajectory and the length of which is used to set the launch speed.

Here is an example of launching every cube on the current map directly upwards:
```squirrel
  ppmod.catapult("prop_weighted_cube", Vector(0, 0, 400));
```
Note that you might first have to ensure that the prop you're launching is not asleep. In most cases, this can be done via the `Wake` input.

### ppmod.push
Applies a directional force to a prop, similar to what `SetVelocity` does on a player.
```squirrel
  ppmod.push(entity, vector)
```
The first argument is the entity to push. The second argument is a Vector, the direction of which is used to control the push direction and the length of which is used to set the push force in units per second.

Here is an example of adding a ~400ups upward force to every cube on the current map:
```squirrel
  ppmod.push("prop_weighted_cube", Vector(0, 0, 400));
```
Note: this function is different from `ppmod.catapult`, as the input vector more accurately represents the force applied, and the magnitude of this force is approximately scaled from units per second. This function also calls `Wake` and `EnableMotion` on the input entity, which ensures that the velocity is applied even if the prop is asleep.

Also note: The console variable `portal_pointpush_think_rate` is modified to increase `point_push` reliability.

## Game interface
These functions provide ways to interact with the game and the player's system outside of the world and its physics.

### ppmod.text
Displays text on a player's screen.
```squirrel
  ppmod.text(string, x, y)
```
All arguments for this constructor are optional. The `string` argument sets the string of text to display, while `x` and `y` position it on the screen relatively. These should be float values from `0` to `1`, or `-1` if the text is to be centered on the respective axis. An instance of `ppmod.text` has the following methods:

- `GetEntity()` - returns the `game_text` entity created by the constructor.
- `SetPosition(x, y)` - adjusts the position of the text using the same system as the constructor.
- `SetText(string)` - changes the text to be displayed.
- `SetSize(size)` - expects a value between 0 and 5, with those being the smallest and largest text channels respectively.
- `SetColor(color1, color2)` - both values are strings of form `"R G B"`, with the second one being optional and used only as the transition color for fading, if fading is used.
- `SetFade(in, out, fx)` - sets fade in/out time in seconds. The third argument is an optional boolean - if `true`, the text will fade in letter-by-letter instead of all at once.
- `Display(hold, player)` - displays the text for the specified amount of seconds to the given player. Both arguments are optional - if `hold` is not set, the text will display for one tick, and if `player` is `null` or unset, the text will display for all players simultaneously.

### ppmod.alias
Creates a console command alias for calling a script function
```squirrel
  ppmod.alias(command, script)
```
The first argument is the command to alias - this can be any arbitrary string, or an existing command. The second argument is the script function or string to execute whenever the alias is called. Note: **aliases cannot be cleared, only overwritten by other aliases**.

Here is an example that aliases the `+mouse_menu` bind (the F key by default) to toggle between zero/normal player gravity:
```squirrel
  local data = {
    pplayer = ppmod.player(GetPlayer()),
    factor = 1.0
  };
  ppmod.alias("+mouse_menu", function ():(data) {
    data.factor = fabs(factor - 1.0);
    data.pplayer.gravity(data.factor);
  });
```

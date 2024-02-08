# ppmod
VScript library for rapid prototyping of Portal 2 mods.

The focus of this project is to provide tools that assist in developing Portal 2 VScript mods faster and much more comfortably than through vanilla VScript. This involves employing various hacks and adding missing features or fixing broken ones through entities often specific to Portal 2. While ppmod strives to be performant, this does not come at the cost of ease of use.

## Installation
Since ppmod4, the environment is expected to be as clean as possible, without any instantiated entities or vectors. This can be achieved by placing the script file in `scripts/vscripts` and calling it at the very top of `mapspawn.nut`, after making sure that the current scope has server-side control:
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return; // Quit if the script is being loaded client-side
  IncludeScript("ppmod4"); // Include ppmod4 as early as possible
```
Including ppmod4 in an already populated environment will still work at the cost of additional vector metamethods and entity method abstractions. This will get logged to the console as a warning, but is technically harmless if these features are unused.

## Getting started
Setting up and working with an environment like this for the first time can be overwhelming, so here's some boilerplate to help you get started. This script will spawn a red cube in front of the player's head, and make it print to the console once it gets fizzled. This should provide a solid example that you can then play around with to get an idea of what it's like to work with ppmod.
```squirrel
  // File: "scripts/vscripts/mapspawn.nut"

  if (!("Entities" in this)) return;
  IncludeScript("ppmod4");

  // This function is called whenever a map is fully loaded
  // We wrap it in async() to make it more comfortable to use asynchronous functions inline
  ppmod.onauto(async(function () {

    // Provides us with additional player info, like eye position and angles
    yield ppmod.player(GetPlayer());
    local pplayer = ::syncnext;

    // Props cannot be created with the CreateByClassname method, so we use ppmod.create instead
    yield ppmod.create("prop_weighted_cube");
    local cube = ::syncnext;

    // Teleports the new cube to 64 units in front of the player's eyes
    local pos = pplayer.eyes.GetOrigin() + pplayer.eyes.GetForwardVector() * 64;
    cube.SetOrigin(pos);
    // Colors the cube red with the "Color" input
    ppmod.fire(cube, "Color", "255 0 0");
    // Connects a script function to the cube's "OnFizzled" output
    ppmod.addscript(cube, "OnFizzled", function () {
      printl("The red cube has been fizzled!");
    });

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
#### pparray.find
```squirrel
  arr.find(2) // Returns 1, which is the index of the first element with value 2.
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

### ppmod.getall
Runs a callback function for every entity that matches the search. Mostly intended for use internally. First argument is an array of `ppmod.get` arguments, the second argument is the callback function, which is provided each iteration's respective entity.
```squirrel
  ppmod.getall(["prop_weighted_cube"], function (cube) {
    printl("Cube found at: " + cube.GetOrigin());
  });
```

### ppmod.prev
Performs a `ppmod.get` search in reverse. Useful for finding the last entity of a sequence.
```squirrel
  ppmod.prev("prop_testchamber_door") // Gets the last door in the map
```

### ppmod.fire
Fires an input to an entity, either by classname, targetname or entity handle.
```squirrel
  ppmod.fire(target, action, value, delay, activator, caller)
```

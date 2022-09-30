if("ppmod" in this) return;
::ppmod <- {};
::min <- function(a, b) return a > b ? b : a;
::max <- function(a, b) return a < b ? b : a;
::round <- function(a, b = 0) return floor(a * (b = pow(10, b)) + 0.5) / b;

function Vector::_mul (other) {
  if (typeof other == "Vector") {
    return Vector(this.x * other.x, this.y * other.y, this.z * other.z);
  } else {
    return Vector(this.x * other, this.y * other, this.z * other);
  }
}

function Vector::_div (other) {
  if (typeof other == "Vector") {
    return Vector(this.x / other.x, this.y / other.y, this.z / other.z);
  } else {
    return Vector(this.x / other, this.y / other, this.z / other);
  }
}

function Vector::_tostring () {
  return "Vector(" + this.x + ", " + this.y + ", " + this.z + ")";
}

ppmod.fire <- function(ent, action = "Use", value = "", delay = 0, activator = null, caller = null) {
  if(typeof ent == "string") EntFire(ent, action, value, delay, activator);
  else EntFireByHandle(ent, action, value.tostring(), delay, activator, caller);
}

ppmod.keyval <- function(ent, key, val) {
  if(typeof ent == "string") {
    for(local curr = ppmod.get(ent); curr; curr = ppmod.get(ent, curr)) {
      ppmod.keyval(curr, key, val);
    }
  } else switch (typeof val) {
    case "integer":
    case "bool":
      ent.__KeyValueFromInt(key, val.tointeger());
      break;
    case "float":
      ent.__KeyValueFromFloat(key, val);
      break;
    case "Vector":
      ent.__KeyValueFromVector(key, val);
      break;
    default:
      ent.__KeyValueFromString(key, val.tostring());
  }
}

ppmod.addoutput <- function(ent, output, target, input = "Use", value = "", delay = 0, max = -1) {
  if(typeof target == "instance") {
    if(!target.GetName().len()) target.__KeyValueFromString("Targetname", UniqueString("noname"));
    target = target.GetName();
  }
  ppmod.keyval(ent, output, target+"\x1B"+input+"\x1B"+value+"\x1B"+delay+"\x1B"+max);
}

ppmod.scrq <- {};
ppmod.scrq_add <- function(scr) {
  local qid = UniqueString();
  if(typeof scr == "string") scr = compilestring(scr);
  ppmod.scrq[qid] <- scr;
  return { id = qid, name = "ppmod.scrq[\"" + qid + "\"]" };
}

ppmod.addscript <- function(ent, output, scr = "", delay = 0, max = -1, del = false) {
  if(typeof scr == "function")
    if(!del) scr = ppmod.scrq_add(scr).name + "()";
    else scr = "(delete " + ppmod.scrq_add(scr).name + ")()";
  ppmod.keyval(ent, output, "!self\x001BRunScriptCode\x1B"+scr+"\x1B"+delay+"\x1B"+max);
}

ppmod.wait <- function(scr, sec, name = null) {
  local relay = Entities.CreateByClassname("logic_relay");
  if(name) relay.__KeyValueFromString("Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  EntFireByHandle(relay, "Trigger", "", sec, null, null);
  relay.__KeyValueFromInt("SpawnFlags", 1);
  return relay;
}

ppmod.interval <- function(scr, sec = 0, name = null) {
  if(!name) name = scr.tostring();
  local timer = Entities.CreateByClassname("logic_timer");
  timer.__KeyValueFromString("Targetname", name);
  ppmod.addscript(timer, "OnTimer", scr);
  EntFireByHandle(timer, "RefireTime", sec.tostring(), 0, null, null);
  EntFireByHandle(timer, "Enable", "", 0, null, null);
  return timer;
}

ppmod.once <- function(scr, name = null) {
  if(!name) name = scr.tostring();
  if(Entities.FindByName(null, name)) return;
  local relay = Entities.CreateByClassname("logic_relay");
  relay.__KeyValueFromString("Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  EntFireByHandle(relay, "Trigger", "", 0, null, null);
  return relay;
}

ppmod.get <- function(key, ent = null, arg = 1) {
  local fnd = null;
  switch (typeof key) {
    case "string":
      if(fnd = Entities.FindByName(ent, key)) return fnd;
      if(fnd = Entities.FindByClassname(ent, key)) return fnd;
      return Entities.FindByModel(ent, key);
    case "Vector":
      if(typeof ent != "string") return Entities.FindInSphere(ent, key, arg);
      if(fnd = Entities.FindByClassnameNearest(ent, key, arg)) return fnd;
      return Entities.FindByNameNearest(ent, key, arg);
    case "integer":
      while((ent = Entities.Next(ent)).entindex() != key);
      return ent;
    case "instance":
      return Entities.Next(key);
    default: return null;
  }
}

ppmod.prev <- function(key, ent = null, arg = 1) {
  local curr = null, prev = null;
  while((curr = ppmod.get(key, curr, arg)) != ent) prev = curr;
  return prev;
}

ppmod.player <- {
  enable = function(func = function(){}) {
    proxy <- Entities.FindByClassname(null, "logic_playerproxy");
    if(!proxy) proxy = Entities.CreateByClassname("logic_playerproxy");
    eyes <- Entities.CreateByClassname("logic_measure_movement");
    eyes.__KeyValueFromInt("MeasureType", 1);
    eyes.__KeyValueFromString("Targetname", "ppmod_eyes");
    eyes.__KeyValueFromString("TargetReference", "ppmod_eyes");
    eyes.__KeyValueFromString("Target", "ppmod_eyes");
    EntFireByHandle(eyes, "SetMeasureReference", "ppmod_eyes", 0, null, null);
    EntFireByHandle(eyes, "SetMeasureTarget", "!player", 0, null, null);
    EntFireByHandle(eyes, "Enable", "", 0, null, null);
    eyes_vec <- function() {
      local ang = eyes.GetAngles() * (PI / 180);
      return Vector(cos(ang.y) * cos(ang.x), sin(ang.y) * cos(ang.x), -sin(ang.x));
    }
    landrl <- Entities.CreateByClassname("logic_relay");
    ppmod.player.surface();
    gameui <- Entities.CreateByClassname("game_ui");
    gameui.__KeyValueFromString("Targetname", "ppmod_gameui");
    gameui.__KeyValueFromInt("FieldOfView", -1);
    EntFireByHandle(gameui, "Activate", "", 0, GetPlayer(), null);
    local script = ppmod.scrq_add(func).name;
    EntFireByHandle(proxy, "RunScriptCode", "(delete " + script + ")()", 0, null, null);
  }
  surface = function(ent = null) {
    if(ent == null) {
      EntFire("ppmod_surface", "Kill");
      ppmod.give("env_player_surface_trigger", ppmod.player.surface);
    } else {
      EntFireByHandle(ppmod.player.landrl, "Trigger", "", 0, null, null);
      ent.__KeyValueFromInt("GameMaterial", 0);
      ent.__KeyValueFromString("Targetname", "ppmod_surface");
      ent.__KeyValueFromString("OnSurfaceChangedFromTarget", "!self\x001BRunScriptCode\x001Bppmod.player.surface()\x001B0\x001B-1");
    }
  }
  holding = function(func) {
    local filter = Entities.CreateByClassname("filter_player_held");
    local relay = Entities.CreateByClassname("logic_relay");
    local script = ppmod.scrq_add(func).name;
    local name = UniqueString("ppmod_holding");
    filter.__KeyValueFromString("Targetname", name);
    filter.__KeyValueFromString("OnPass", "!self\x001BRunScriptCode\x001B(delete " + script + ")(true)\x001B0\x001B1");
    filter.__KeyValueFromString("OnPass", "!self\x001BKill\x1B\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser1", name + "\x001BRunScriptCode\x001B(delete " + script + ")(false)\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser1", "!self\x001BOnUser2\x1B\x001B0\x001B1");
    relay.__KeyValueFromString("OnUser2", "!self\x001BKill\x1B\x001B0\x001B1");
    for(local ent = Entities.First(); ent; ent = Entities.Next(ent)) {
      EntFireByHandle(filter, "TestActivator", "", 0, ent, null);
    }
    EntFireByHandle(relay, "FireUser1", "", 0, null, null);
    EntFireByHandle(relay, "Kill", "", 0, null, null);
  }
  jump = function(scr) { ppmod.addscript(proxy, "OnJump", scr) }
  land = function(scr) { ppmod.addscript(landrl, "OnTrigger", scr) }
  duck = function(scr) { ppmod.addscript(proxy, "OnDuck", scr) }
  unduck = function(scr) { ppmod.addscript(proxy, "OnUnDuck", scr) }
  input = function(str, scr) {
    if(str[0] == '+') str = "pressed" + str.slice(1);
    else str = "unpressed" + str.slice(1);
    ppmod.addscript(gameui, str, scr);
  }
  movesim = function(move, ftime = null, accel = 10, fric = 0, ground = Vector(0, 0, -1), grav = Vector(0, 0, -600), eyes = null) {
    if(ftime == null) ftime = FrameTime();
    if(eyes == null) eyes = ppmod.player.eyes;
    local vel = GetPlayer().GetVelocity();
    local mask = Vector(fabs(ground.x), fabs(ground.y), fabs(ground.z));

    if(fric > 0) {
      local veldir = Vector(vel.x, vel.y, vel.z);
      local absvel = veldir.Norm();
      if(absvel >= 100) {
        vel *= 1 - ftime * fric;
      } else if(fric / 0.6 < absvel) {
        vel -= veldir * (ftime * 400);
      } else if(absvel > 0) {
        vel = Vector(vel.x * mask.x, vel.x * mask.y, vel.x * mask.z);
      }
    }

    local forward = eyes.GetForwardVector();
    local left = eyes.GetLeftVector();
    forward -= Vector(forward.x * mask.x, forward.y * mask.y, forward.z * mask.z);
    left -= Vector(left.x * mask.x, left.y * mask.y, left.z * mask.z);

    forward.Norm();
    left.Norm();

    local wishvel = Vector();
    wishvel.x = forward.x * move.x + left.x * move.y;
    wishvel.y = forward.y * move.x + left.y * move.y;
    wishvel.z = forward.z * move.x + left.z * move.y;
    wishvel -= Vector(wishvel.x * mask.x, wishvel.y * mask.y, wishvel.z * mask.z);
    local wishspeed = wishvel.Norm();

    local vertvel = Vector(vel.x * mask.x, vel.y * mask.y, vel.z * mask.z);
    vel -= vertvel;
    local currspeed = vel.Dot(wishvel);

    local addspeed = wishspeed - currspeed;
    local accelspeed = accel * ftime * wishspeed;
    if(accelspeed > addspeed) accelspeed = addspeed;

    local finalvel = vel + wishvel * accelspeed + vertvel + grav * ftime;

    local relay = Entities.FindByName(null, "ppmod_movesim_relay");
    if(relay) {
      GetPlayer().SetVelocity(finalvel);
      EntFireByHandle(relay, "CancelPending", "", 0, null, null);
      EntFireByHandle(relay, "Trigger", "", ftime, null, null);
      local gravtrig = Entities.FindByName(null, "ppmod_movesim_gravtrig");
      gravtrig.SetAbsOrigin(GetPlayer().GetCenter());
    } else {
      ppmod.give("trigger_gravity", function(gravtrig, vel = finalvel, time = ftime + FrameTime()) {
        GetPlayer().SetVelocity(vel);
        ppmod.trigger(GetPlayer().GetCenter() + Vector(256), Vector(64, 64, 64), gravtrig);
        gravtrig.__KeyValueFromString("Targetname", "ppmod_movesim_gravtrig");
        gravtrig.__KeyValueFromFloat("Gravity", 0.000001);
        local relay = Entities.CreateByClassname("logic_relay");
        relay.__KeyValueFromInt("SpawnFlags", 2);
        relay.__KeyValueFromString("Targetname", "ppmod_movesim_relay");
        relay.__KeyValueFromString("OnTrigger", "!self\x001BKill\x1B\x001B"+time+"\x001B-1");
        ppmod.addscript(relay, "OnTrigger", function(gravtrig = gravtrig) {
          gravtrig.SetAbsOrigin(GetPlayer().GetOrigin() + Vector(256));
          EntFire("ppmod_movesim_gravtrig", "Kill", "", FrameTime());
        }, time);
        EntFireByHandle(relay, "Trigger", "", 0, null, null);
      });
    }
  }
}

ppmod.brush <- function(pos, size, type = "func_brush", ang = Vector()) {
  local brush = type;
  if(typeof type == "string") brush = Entities.CreateByClassname(type);
  brush.SetAbsOrigin(pos);
  brush.SetAngles(ang.x, ang.y, ang.z);
  brush.SetSize(Vector() - size, size);
  brush.__KeyValueFromInt("Solid", 3);
  return brush;
}

ppmod.trigger <- function(pos, size, type = "once", ang = Vector()) {
  if(typeof type == "string") type = "trigger_" + type;
  local trigger = ppmod.brush(pos, size, type, ang);
  trigger.__KeyValueFromInt("CollisionGroup", 1);
  trigger.__KeyValueFromInt("SpawnFlags", 1);
  if(type == "trigger_once") trigger.__KeyValueFromString("OnStartTouch", "!self\x001BKill\x1B\x001B0\x001B1");
  EntFireByHandle(trigger, "Enable", "", 0, null, null);
  return trigger;
}

ppmod.texture <- function(tex = "", pos = Vector(), ang = Vector(90), simple = 1, far = 16) {
  local texture = Entities.CreateByClassname("env_projectedtexture");
  texture.SetAbsOrigin(pos);
  texture.SetAngles(ang.x, ang.y, ang.z);
  texture.__KeyValueFromInt("FarZ", far);
  texture.__KeyValueFromInt("SimpleProjection", simple.tointeger());
  texture.__KeyValueFromString("TextureName", tex);
  return texture;
}

ppmod.decal <- function(tex, pos, ang = Vector(90)) {
  local decal = Entities.CreateByClassname("infodecal");
  decal.SetAbsOrigin(pos);
  decal.SetAngles(ang.x, ang.y, ang.z);
  decal.__KeyValueFromString("TextureName", tex);
  EntFireByHandle(decal, "Activate", "", 0, null, null);
  return decal;
}

ppmod.create <- function(cmd, func, key = null) {
  if(!key) switch (cmd.slice(0, min(cmd.len(), 17))) {
    case "ent_create_portal": key = "cube"; break;
    case "ent_create_paint_": key = "prop_paint_bomb"; break;
    default:
      if(cmd.find(" ")) key = cmd.slice(cmd.find(" ")+1);
      else if(cmd.slice(-4) == ".mdl") key = cmd, cmd = "prop_dynamic_create " + cmd;
      else key = cmd, cmd = "ent_create " + cmd;
  }
  SendToConsole(cmd);
  if(key.slice(-4) == ".mdl") key = "models/" + key;
  local getstr = "ppmod.prev(\"" + key + "\")";
  local qstr = scrq_add(func).name;
  SendToConsole("script (delete " + qstr + ")(" + getstr + ")");
}

ppmod.give <- function(key, func, pos = null) {
  if(pos) return ppmod.give("npc_maker", function(e, k = key, f = func, p = pos) {
    e.SetAbsOrigin(p);
    e.__KeyValueFromString("NPCType", k);
    k = UniqueString("ppmod_give");
    e.__KeyValueFromString("NPCTargetname", k);
    local getstr = ")(Entities.FindByName(null, \"" + k + "\"))";
    local script = ppmod.scrq_add(f).name + getstr;
    e.__KeyValueFromString("OnSpawnNPC", k + "\x001BRunScriptCode\x001B(delete " + script + "\x001B0\x001B1");
    e.__KeyValueFromString("OnSpawnNPC", "!self\x001BKill\x1B\x001B0\x001B1");
  });
  local player = Entities.FindByClassname(null, "player");
  local equip = Entities.CreateByClassname("game_player_equip");
  equip.__KeyValueFromInt(key, 1);
  EntFireByHandle(equip, "Use", "", 0, player, null);
  local getstr = ")(ppmod.prev(\"" + key + "\"))";
  local script = "(delete " + scrq_add(func).name + getstr;
  EntFireByHandle(equip, "RunScriptCode", script, 0, null, null);
  EntFireByHandle(equip, "Kill", "", 0, null, null);
}

ppmod.text <- function(text = "", x = -1, y = -1) {
  local ent = Entities.CreateByClassname("game_text");
  ent.__KeyValueFromString("Message", text);
  ent.__KeyValueFromString("Color", "255 255 255");
  ent.__KeyValueFromFloat("X", x);
  ent.__KeyValueFromFloat("Y", y);
  return {
    GetEntity = function(ent = ent) { return ent },
    SetPosition = function(x, y, ent = ent) {
      ent.__KeyValueFromFloat("X", x);
      ent.__KeyValueFromFloat("Y", y);
    },
    SetText = function(text, ent = ent) {
      ent.__KeyValueFromString("Message", text);
    },
    SetChannel = function(ch, ent = ent) {
      ent.__KeyValueFromInt("Channel", ch);
    },
    SetColor = function(c1, c2 = null, ent = ent) {
      ent.__KeyValueFromString("Color", c1);
      if(c2) ent.__KeyValueFromString("Color2", c2);
    },
    SetFade = function(fin, fout, fx = false, ent = ent) {
      ent.__KeyValueFromFloat("FadeIn", fin);
      ent.__KeyValueFromFloat("FXTime", fin);
      ent.__KeyValueFromFloat("FadeOut", fout);
      if(fx) ent.__KeyValueFromInt("Effect", 2);
      else ent.__KeyValueFromInt("Effect", 0);
    },
    Display = function(hold = null, player = null, ent = ent) {
      if(!hold) hold = FrameTime();
      ent.__KeyValueFromFloat("HoldTime", hold);
      if(player) ent.__KeyValueFromInt("SpawnFlags", 0);
      else ent.__KeyValueFromInt("SpawnFlags", 1);
      EntFireByHandle(ent, "Display", "", 0, player, null);
    }
  };
}

ppmod.ray <- function(start, end, ent = null, world = true, ray = null) {

  if(!ent) if(world) return TraceLine(start, end, null);
  else return 1.0;

  local len, div;
  if(!ray) {
    local dir = end - start;
    len = dir.Norm();
    div = [1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z];
  } else {
    len = ray[0];
    div = ray[1];
  }

  if(typeof ent == "array") {
    local lowest = 1.0;
    for(local i = 0; i < ent.len(); i++) {
      local curr = ppmod.ray(start, end, ent[i], false, [len, div]);
      if(curr < lowest) lowest = curr;
    }
    if(world) return min(lowest, TraceLine(start, end, null));
    return lowest;
  } else if(typeof ent == "string") {
    local lowest = 1.0;
    for(local i = ppmod.get(ent); i; i = ppmod.get(ent, i)) {
      local curr = ppmod.ray(start, end, i, false, [len, div]);
      if(curr < lowest) lowest = curr;
    }
    if(world) return min(lowest, TraceLine(start, end, null));
    return lowest;
  }

  local pos = ent.GetOrigin();
  local ang = ent.GetAngles() * (PI / 180);

  local c1 = cos(ang.z);
  local s1 = sin(ang.z);
  local c2 = cos(ang.x);
  local s2 = sin(ang.x);
  local c3 = cos(ang.y);
  local s3 = sin(ang.y);

  local matrix = [
    [c2 * c3, c3 * s1 * s2 - c1 * s3, s1 * s3 + c1 * c3 * s2],
    [c2 * s3, c1 * c3 + s1 * s2 * s3, c1 * s2 * s3 - c3 * s1],
    [-s2, c2 * s1, c1 * c2]
  ];

  local mins = ent.GetBoundingMins();
  local maxs = ent.GetBoundingMaxs();
  mins = [mins.x, mins.y, mins.z];
  maxs = [maxs.x, maxs.y, maxs.z];

  local bmin = [pos.x, pos.y, pos.z];
  local bmax = [pos.x, pos.y, pos.z];
  local a, b;

  for(local i = 0; i < 3; i++) {
    for(local j = 0; j < 3; j++) {
      a = (matrix[i][j] * mins[j]);
      b = (matrix[i][j] * maxs[j]);
      if(a < b) {
        bmin[i] += a;
        bmax[i] += b;
      } else {
        bmin[i] += b;
        bmax[i] += a;
      }
    }
  }

  if (
    start.x > bmin[0] && start.x < bmax[0] &&
    start.y > bmin[1] && start.y < bmax[1] &&
    start.z > bmin[2] && start.z < bmax[2]
  ) return 0;

  start = [start.x, start.y, start.z];

  local tmin = [0.0, 0.0, 0.0];
  local tmax = [0.0, 0.0, 0.0];

  for(local i = 0; i < 3; i++) {
    if(div[i] >= 0) {
      tmin[i] = (bmin[i] - start[i]) * div[i];
      tmax[i] = (bmax[i] - start[i]) * div[i];
    } else {
      tmin[i] = (bmax[i] - start[i]) * div[i];
      tmax[i] = (bmin[i] - start[i]) * div[i];
    }
    if(tmin[0] > tmax[i] || tmin[i] > tmax[0]) return 1.0;
    if(tmin[i] > tmin[0]) tmin[0] = tmin[i];
    if(tmax[i] < tmax[0]) tmax[0] = tmax[i];
  }

  if(tmin[0] < 0) tmin[0] = 1.0;
  else tmin[0] /= len;
  if(world) return min(tmin[0], TraceLine(start, end, null));
  return tmin[0];

}

ppmod.fwrite <- function(path, str) {

  local stall = "";
  for (local i = 195; i > path.len(); i --) stall += "/";

  if (path[0] == "/") path = stall + path;
  else path = "." + stall.slice(1) + path;

  for (local i = 0; i < str.len(); i ++) {
    if (str[i] == '\\') str = str.slice(0, i) + "\\\\" + str.slice(++i);
    if (str[i] == '"') str = str.slice(0, i) + "\\\x22" + str.slice(++i);
  }

  SendToConsole("con_logfile \"" + path + ".log\"");
  SendToConsole("script print(\"" + str + "\")");
  SendToConsole("con_logfile \"\"");

}

if("ppmod" in this) return;
::ppmod <- {};
::min <- function(a, b) { if(a > b) return b; return a }
::max <- function(a, b) { if(a < b) return b; return a }
::round <- function(a, b = 0) return floor(a * (b = pow(10, b)) + 0.5) / b;

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
  ppmod.addoutput(ent, output, "!self", "RunScriptCode", scr, delay, max);
}

ppmod.wait <- function(scr, sec, name = null) {
  local relay = Entities.CreateByClassname("logic_relay");
  if(name) ppmod.keyval(relay, "Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  ppmod.fire(relay, "Trigger", "", sec);
  ppmod.keyval(relay, "SpawnFlags", 1);
  return relay;
}

ppmod.interval <- function(scr, sec = 0, name = null) {
  if(!name) name = scr.tostring();
  local timer = Entities.CreateByClassname("logic_timer");
  ppmod.keyval(timer, "Targetname", name);
  ppmod.fire(timer, "RefireTime", sec);
  ppmod.addscript(timer, "OnTimer", scr);
  ppmod.fire(timer, "Enable");
  return timer;
}

ppmod.once <- function(scr, name = null) {
  if(!name) name = scr.tostring();
  if(Entities.FindByName(null, name)) return;
  local relay = Entities.CreateByClassname("logic_relay");
  ppmod.keyval(relay, "Targetname", name);
  ppmod.addscript(relay, "OnTrigger", scr, 0, -1, true);
  ppmod.fire(relay, "Trigger");
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
    ppmod.keyval(eyes, "MeasureType", 1);
    ppmod.keyval(eyes, "Targetname", "ppmod_eyes");
    ppmod.keyval(eyes, "TargetReference", "ppmod_eyes");
    ppmod.keyval(eyes, "Target", "ppmod_eyes");
    ppmod.fire(eyes, "SetMeasureReference", "ppmod_eyes");
    ppmod.fire(eyes, "SetMeasureTarget", "!player");
    ppmod.fire(eyes, "Enable");
    eyes_vec <- function() {
      local ang = eyes.GetAngles() * (PI / 180);
      return Vector(cos(ang.y) * cos(ang.x), sin(ang.y) * cos(ang.x), -sin(ang.x));
    }
    landrl <- Entities.CreateByClassname("logic_relay");
    ppmod.player.surface();
    gameui <- Entities.CreateByClassname("game_ui");
    ppmod.keyval(gameui, "Targetname", "ppmod_gameui");
    ppmod.keyval(gameui, "FieldOfView", -1);
    ppmod.fire(gameui, "Activate", "", 0, GetPlayer());
    local script = ppmod.scrq_add(func).name;
    ppmod.fire(proxy, "RunScriptCode", "(delete " + script + ")()");
  }
  surface = function(e = null) {
    if(e == null) {
      EntFire("ppmod_surface", "Kill");
      ppmod.give("env_player_surface_trigger", ppmod.player.surface);
    } else {
      ppmod.fire(ppmod.player.landrl, "Trigger");
      ppmod.keyval(e, "GameMaterial", 0);
      ppmod.keyval(e, "Targetname", "ppmod_surface");
      ppmod.addscript(e, "OnSurfaceChangedFromTarget", "ppmod.player.surface()");
    }
  }
  holding = function(func) {
    local filter = Entities.CreateByClassname("filter_player_held");
    local relay = Entities.CreateByClassname("logic_relay");
    local script = "(delete " + ppmod.scrq_add(func).name + ")";
    ppmod.addscript(filter, "OnPass", script + "(true)");
    ppmod.addoutput(filter, "OnPass", "!self", "Kill");
    ppmod.addoutput(relay, "OnUser1", filter, "RunScriptCode", script + "(false)");
    ppmod.addoutput(relay, "OnUser1", "!self", "OnUser2");
    ppmod.addoutput(relay, "OnUser2", filter, "Kill");
    for(local ent = Entities.First(); ent; ent = Entities.Next(ent)) {
      ppmod.fire(filter, "TestActivator", "", 0, ent);
    }
    ppmod.fire(relay, "FireUser1");
    ppmod.fire(relay, "Kill");
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
}

ppmod.brush <- function(pos, size, type = "func_brush", ang = Vector()) {
  local brush = type;
  if(typeof type == "string") brush = Entities.CreateByClassname(type);
  brush.SetAbsOrigin(pos);
  brush.SetAngles(ang.x, ang.y, ang.z);
  brush.SetSize(Vector() - size, size);
  ppmod.keyval(brush, "Solid", 3);
  return brush;
}

ppmod.trigger <- function(pos, size, type = "once", ang = Vector()) {
  if(typeof type == "string") type = "trigger_" + type;
  local trigger = ppmod.brush(pos, size, type, ang);
  ppmod.keyval(trigger, "CollisionGroup", 1);
  ppmod.keyval(trigger, "SpawnFlags", 1);
  if(type == "once") ppmod.addoutput(trigger, "OnStartTouch", "!self", "Kill");
  ppmod.fire(trigger, "Enable");
  return trigger;
}

ppmod.texture <- function(tex = "", pos = Vector(), ang = Vector(90), simple = 1, far = 16) {
  local texture = Entities.CreateByClassname("env_projectedtexture");
  texture.SetAbsOrigin(pos);
  texture.SetAngles(ang.x, ang.y, ang.z);
  ppmod.keyval(texture, "FarZ", far);
  ppmod.keyval(texture, "SimpleProjection", simple.tointeger());
  ppmod.keyval(texture, "TextureName", tex);
  return texture;
}

ppmod.decal <- function(tex, pos, ang = Vector(90)) {
  local decal = Entities.CreateByClassname("infodecal");
  decal.SetAbsOrigin(pos);
  decal.SetAngles(ang.x, ang.y, ang.z);
  ppmod.keyval(decal, "Texture", tex);
  ppmod.keyval(decal, "LowPriority", 0);
  ppmod.fire(decal, "Activate");
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
    ppmod.keyval(e, "NPCType", k);
    k = UniqueString("ppmod_give");
    ppmod.keyval(e, "NPCTargetname", k);
    local getstr = ")(ppmod.get(\"" + k + "\"))";
    local script = "(delete " + ppmod.scrq_add(f).name + getstr;
    ppmod.addoutput(e, "OnSpawnNPC", k, "RunScriptCode", script);
    ppmod.addoutput(e, "OnSpawnNPC", "!self", "Kill");
  });
  local player = Entities.FindByClassname(null, "player");
  local equip = Entities.CreateByClassname("game_player_equip");
  ppmod.keyval(equip, key, 1);
  ppmod.fire(equip, "Use", "", 0, player);
  local getstr = ")(ppmod.prev(\"" + key + "\"))";
  local script = "(delete " + scrq_add(func).name + getstr;
  ppmod.fire(equip, "RunScriptCode", script);
  ppmod.fire(equip, "Kill");
}

ppmod.text <- function(text = "", x = -1, y = -1) {
  local ent = Entities.CreateByClassname("game_text");
  ppmod.keyval(ent, "Message", text);
  ppmod.keyval(ent, "X", x);
  ppmod.keyval(ent, "Y", y);
  ppmod.keyval(ent, "Color", "255 255 255");
  return {
    GetEntity = function(ent = ent) { return ent },
    SetPosition = function(x, y, ent = ent) {
      ppmod.keyval(ent, "X", x);
      ppmod.keyval(ent, "Y", y);
    },
    SetText = function(text, ent = ent) {
      ppmod.keyval(ent, "Message", text);
    },
    SetChannel = function(ch, ent = ent) {
      ppmod.keyval(ent, "Channel", ch);
    },
    SetColor = function(c1, c2 = null, ent = ent) {
      ppmod.keyval(ent, "Color", c1);
      if(c2) ppmod.keyval(ent, "Color2", c2);
    },
    SetFade = function(fin, fout, fx = false, ent = ent) {
      ppmod.keyval(ent, "FadeIn", fin);
      ppmod.keyval(ent, "FXTime", fin);
      ppmod.keyval(ent, "FadeOut", fout);
      if(fx) ppmod.keyval(ent, "Effect", 2);
      else ppmod.keyval(ent, "Effect", 0);
    },
    Display = function(hold = null, player = null, ent = ent) {
      if(!hold) hold = FrameTime();
      ppmod.keyval(ent, "HoldTime", hold);
      if(player) ppmod.keyval(ent, "SpawnFlags", 0);
      else ppmod.keyval(ent, "SpawnFlags", 1);
      ppmod.fire(ent, "Display", "", 0, player);
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

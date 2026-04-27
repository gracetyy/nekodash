extends SceneTree

# -------------------------------------------------------
# self-contained Nekodash level validator + solver
# -------------------------------------------------------
# Usage:
#   godot --headless --script tools/ai_level_helper.gd
#
# Fill in LEVEL_PROPOSALS below.  The script validates every entry,
# runs the BFS solver, and prints a full PASS / FAIL report plus
# ready-to-paste PACK entries for all solvable levels.
#
# -- INPUT FORMAT ----------------------------------------
# Each proposal is a Dictionary with these keys:
#   "id"    : String       -- unique id, e.g. "w2_l3"
#   "world" : int          -- 2=Kitchen | 3=Living Room | 99=Special
#   "index" : int          -- 1-based order within the world
#   "name"  : String       -- display name, e.g. "Kitchen 3"
#   "w"     : int          -- grid width  (>= 5)
#   "h"     : int          -- grid height (>= 5)
#   "obs"   : Array        -- obstacle positions as Vector2i
#
# -- OBSTACLE RULES --------------------------------------
# 1. Interior-edge only:  x in [1, w-2], y in [1, h-2],
#                         AND (x==1 OR x==w-2 OR y==1 OR y==h-2)
# 2. No shared row (y) or column (x) between any two obstacles.
# 3. Density: obstacle_count / ((w-2)*(h-2))  <=  0.15
# 4. No obstacle at (1,1)  -- that is the cat start.
#
# -- INTERIOR-EDGE QUICK REFERENCE -----------------------
# 6x6: valid x in {1,2,3,4}, y in {1,2,3,4}, on x==1|4 or y==1|4
# 7x7: valid x in {1..5},    y in {1..5},    on x==1|5 or y==1|5
# 8x8: valid x in {1..6},    y in {1..6},    on x==1|6 or y==1|6
# 9x9: valid x in {1..7},    y in {1..7},    on x==1|7 or y==1|7
#
# -- DIFFICULTY GUIDE ------------------------------------
# World 2  lvl 1-10: ~8-22 min_moves, grids 6x6 to 8x8, 2-5 obstacles
# World 3  lvl 1-10: ~11-24 min_moves, grids 7x7 to 8x8, 3-5 obstacles
# World 99 lvl 1-10: ~10-24 min_moves, grids 6x6 to 8x8, 3-5 obstacles
# -------------------------------------------------------

# vvv  AI AGENT: fill in proposals here  vvv
const LEVEL_PROPOSALS: Array[Dictionary] = [
	{
		"id": "w2_l1",
		"world": 2,
		"index": 1,
		"name": "Kitchen 1",
		"w": 6,
		"h": 6,
		"obs": [Vector2i(2, 1), Vector2i(4, 2), Vector2i(1, 4)],
	},
]

# -------------------------------------------------------
# Nothing below this line needs to be edited.
# -------------------------------------------------------

const _DIRS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
]
const _MAX_SLIDE: int = 20
const _MAX_WALK_BITS: int = 63

var _last_states: int = 0


func _init() -> void:
	var passed: Array[Dictionary] = []
	var failed: Array[Dictionary] = []

	for proposal in LEVEL_PROPOSALS:
		var report: Dictionary = _validate_proposal(proposal)
		if report["ok"]:
			passed.append(report)
		else:
			failed.append(report)

	print("\n=======================================")
	print("  NEKODASH LEVEL HELPER -- RESULTS")
	print("=======================================")
	print("  PASSED: %d    FAILED: %d" % [passed.size(), failed.size()])
	print("=======================================")

	if passed.size() > 0:
		print("\n[OK] SOLVABLE LEVELS:")
		for r in passed:
			print("  [%s] \"%s\": min_moves=%d  star3<=%d  star2<=%d  star1<=%d  (states=%d)" % [
				r["id"], r["name"],
				r["minimum_moves"], r["star3"], r["star2"], r["star1"],
				r["states_explored"],
			])
			print("         obs=%s  grid=%dx%d  world=%d  index=%d" % [
				_obs_str(r["obs"]), r["w"], r["h"], r["world"], r["index"],
			])
		print("\n  -- Ready-to-paste PACK entries --")
		for r in passed:
			print(_pack_entry(r))

	if failed.size() > 0:
		print("\n[X] REJECTED LEVELS:")
		for r in failed:
			print("  [%s] FAIL -- %s" % [r["id"], r["reason"]])

	print("")
	quit(0)


func _validate_proposal(p: Dictionary) -> Dictionary:
	var id: String     = String(p.get("id", "unknown"))
	var world: int     = int(p.get("world", 0))
	var index: int     = int(p.get("index", 0))
	var dname: String  = String(p.get("name", id))
	var w: int         = int(p.get("w", 0))
	var h: int         = int(p.get("h", 0))
	var raw_obs: Array = p.get("obs", []) as Array

	if w < 5 or h < 5:
		return _fail(id, "Grid too small (%dx%d, minimum is 5x5)" % [w, h])

	var obs: Array[Vector2i] = []
	for item in raw_obs:
		if item is Vector2i:
			obs.append(item as Vector2i)
		else:
			return _fail(id, "obs entry is not Vector2i: %s" % str(item))

	# Rule 1 -- interior edge
	for v in obs:
		var err: String = _check_interior_edge(v, w, h)
		if err != "":
			return _fail(id, "Obstacle %s -- %s" % [str(v), err])

	# Rule 2 -- unique rows and cols
	var rows: Dictionary = {}
	var cols: Dictionary = {}
	for v in obs:
		if rows.has(v.y):
			return _fail(id, "Two obstacles share row y=%d" % v.y)
		if cols.has(v.x):
			return _fail(id, "Two obstacles share column x=%d" % v.x)
		rows[v.y] = true
		cols[v.x] = true

	# Rule 3 -- density
	var interior: int = (w - 2) * (h - 2)
	if float(obs.size()) / float(interior) > 0.15:
		return _fail(id, "Obstacle density %.2f > 0.15 (%d obs / %d interior tiles)" % [
			float(obs.size()) / float(interior), obs.size(), interior,
		])

	# Rule 4 -- no obstacle at cat start
	for v in obs:
		if v == Vector2i(1, 1):
			return _fail(id, "Obstacle placed on cat start (1,1)")

	# Build tile arrays
	var walk: PackedInt32Array = PackedInt32Array()
	walk.resize(w * h)
	for y in range(h):
		for x in range(w):
			walk[x + y * w] = 1 if (x == 0 or y == 0 or x == w - 1 or y == h - 1) else 0

	var ob_tiles: PackedInt32Array = PackedInt32Array()
	ob_tiles.resize(w * h)
	for v in obs:
		ob_tiles[v.x + v.y * w] = 1

	# Solve
	var min_moves: int = _bfs(w, h, walk, ob_tiles, Vector2i(1, 1))
	if min_moves < 0:
		return _fail(id, "Unsolvable -- BFS found no complete path")

	var star3: int = min_moves + 1
	var star2: int = maxi(star3 + 2, min_moves + int(floor(float(min_moves) * 0.4)))
	var star1: int = min_moves + int(floor(float(min_moves) * 1.0))

	return {
		"ok": true,
		"id": id, "world": world, "index": index, "name": dname,
		"w": w, "h": h, "obs": obs,
		"minimum_moves": min_moves,
		"star3": star3, "star2": star2, "star1": star1,
		"states_explored": _last_states,
	}


func _bfs(w: int, h: int, walk: PackedInt32Array, ob: PackedInt32Array, start: Vector2i) -> int:
	var p2b: Dictionary = {}
	var bit: int = 0
	for y in range(h):
		for x in range(w):
			var p: Vector2i = Vector2i(x, y)
			if _is_walk(p, w, h, walk, ob):
				p2b[p] = bit
				bit += 1

	if bit == 0 or bit > _MAX_WALK_BITS or not p2b.has(start):
		_last_states = 0
		return -1

	var goal: int = (1 << bit) - 1
	var init_mask: int = 1 << int(p2b[start])
	if init_mask == goal:
		_last_states = 1
		return 0

	# queue entries: [x, y, mask, depth]
	var queue: Array = [[start.x, start.y, init_mask, 0]]
	var seen: Dictionary = {"%d,%d|%d" % [start.x, start.y, init_mask]: true}
	var head: int = 0
	var explored: int = 0

	while head < queue.size():
		var cur: Array = queue[head]
		head += 1
		explored += 1
		var cp: Vector2i = Vector2i(int(cur[0]), int(cur[1]))
		var cm: int = int(cur[2])
		var cd: int = int(cur[3])

		for d in _DIRS:
			var land: Vector2i = _slide(cp, d, w, h, walk, ob)
			if land == cp:
				continue
			var nm: int = cm
			var step: Vector2i = cp + d
			while step != land + d:
				if p2b.has(step):
					nm |= (1 << int(p2b[step]))
				step += d
			if nm == goal:
				_last_states = explored
				return cd + 1
			var key: String = "%d,%d|%d" % [land.x, land.y, nm]
			if not seen.has(key):
				seen[key] = true
				queue.append([land.x, land.y, nm, cd + 1])

	_last_states = explored
	return -1


func _is_walk(p: Vector2i, w: int, h: int, walk: PackedInt32Array, ob: PackedInt32Array) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
		return false
	var idx: int = p.x + p.y * w
	return walk[idx] == 0 and ob[idx] == 0


func _slide(pos: Vector2i, dir: Vector2i, w: int, h: int, walk: PackedInt32Array, ob: PackedInt32Array) -> Vector2i:
	for _i in range(_MAX_SLIDE):
		if not _is_walk(pos + dir, w, h, walk, ob):
			break
		pos += dir
	return pos


func _check_interior_edge(v: Vector2i, w: int, h: int) -> String:
	if v.x <= 0 or v.y <= 0 or v.x >= w - 1 or v.y >= h - 1:
		return "outside the interior ring (must not be on the border)"
	if not (v.x == 1 or v.x == w - 2 or v.y == 1 or v.y == h - 2):
		return "not on the innermost ring (x must be 1 or %d, or y must be 1 or %d)" % [w - 2, h - 2]
	return ""


func _fail(id: String, reason: String) -> Dictionary:
	return {"ok": false, "id": id, "reason": reason}


func _obs_str(obs: Array[Vector2i]) -> String:
	var parts: Array[String] = []
	for v in obs:
		parts.append("Vector2i(%d,%d)" % [v.x, v.y])
	return "[" + ", ".join(parts) + "]"


func _pack_entry(r: Dictionary) -> String:
	return '\t{"id":"%s", "world":%d, "index":%d, "name":"%s", "w":%d, "h":%d, "obs":%s},' % [
		r["id"], r["world"], r["index"], r["name"], r["w"], r["h"], _obs_str(r["obs"]),
	]

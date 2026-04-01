## LevelSolver — offline BFS tool that computes the minimum number of moves
## to solve any NekoDash level.
## Implements: design/gdd/bfs-minimum-solver.md
## Task: S1-09
##
## Performs breadth-first search over (cat_position × tile_coverage_bitmask)
## state space.  BFS guarantees the first solution found is optimal.
##
## This is a developer tool — never runs on player devices.
##
## Usage (headless CLI):
##   godot --headless --script tools/solve_levels.gd
##
## Usage (from GDScript / tests):
##   var solver := LevelSolver.new()
##   var result := solver.solve(level_data)
##   print(result.minimum_moves)   # -1 if unsolvable
class_name LevelSolver
extends RefCounted


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Maximum walkable tiles supported by bitmask (GDScript int is 64-bit signed;
## bit 63 causes sign issues, so effective limit is 63).
const MAX_WALKABLE_TILES: int = 63

## Cardinal directions: up, down, left, right.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
]

## Safety guard — same as SlidingMovement.MAX_SLIDE_DISTANCE.
const MAX_SLIDE_DISTANCE: int = 20

## States explored threshold for progress warning.
const WARN_STATE_THRESHOLD: int = 1_000_000

## Walkability enum value — matches GridSystem.TileWalkability.WALKABLE.
const TILE_WALKABLE: int = 0


# —————————————————————————————————————————————
# Result container
# —————————————————————————————————————————————

## Returned by solve().  Contains solver output for the caller.
class SolveResult:
	## Minimum moves to cover all walkable tiles.  -1 if unsolvable.
	var minimum_moves: int = -1
	## Number of BFS states explored.
	var states_explored: int = 0
	## Wall-clock solve time in milliseconds.
	var solve_time_msec: int = 0
	## Human-readable error, empty string on success.
	var error: String = ""


# —————————————————————————————————————————————
# BFS state
# —————————————————————————————————————————————

## Internal struct passed through the BFS queue.
class _BFSState:
	var pos: Vector2i
	var mask: int
	var depth: int

	func _init(p_pos: Vector2i, p_mask: int, p_depth: int) -> void:
		pos = p_pos
		mask = p_mask
		depth = p_depth


# —————————————————————————————————————————————
# Private helpers built per-solve
# —————————————————————————————————————————————

## Walkable tile coordinate → bit index.
var _pos_to_index: Dictionary = {}

## Grid width/height copied from LevelData.
var _grid_width: int = 0
var _grid_height: int = 0

## Flat walkability array copied from LevelData.
var _walkability: PackedInt32Array = PackedInt32Array()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Runs BFS on level_data and returns a SolveResult.
## Does NOT modify level_data — the caller decides whether to write back.
func solve(level_data: LevelData) -> SolveResult:
	_reset_state()
	var result := SolveResult.new()
	var start_tick: int = Time.get_ticks_msec()

	# ——— Validate input ———
	if level_data == null:
		result.error = "LevelData is null"
		result.solve_time_msec = Time.get_ticks_msec() - start_tick
		return result

	_grid_width = level_data.grid_width
	_grid_height = level_data.grid_height
	_walkability = level_data.walkability_tiles

	if _walkability.is_empty():
		result.error = "walkability_tiles is empty"
		push_error("[LevelSolver] %s: walkability_tiles is empty" % level_data.level_id)
		result.solve_time_msec = Time.get_ticks_msec() - start_tick
		return result

	# ——— Build tile index (row-major enumeration) ———
	_pos_to_index.clear()
	var bit_index: int = 0
	for row in range(_grid_height):
		for col in range(_grid_width):
			if _is_walkable(Vector2i(col, row)):
				_pos_to_index[Vector2i(col, row)] = bit_index
				bit_index += 1

	var walkable_count: int = bit_index

	if walkable_count == 0:
		result.error = "Level has 0 walkable tiles"
		push_error("[LevelSolver] %s: Level has 0 walkable tiles" % level_data.level_id)
		result.solve_time_msec = Time.get_ticks_msec() - start_tick
		return result

	if walkable_count > MAX_WALKABLE_TILES:
		result.error = "Level has %d walkable tiles (max %d for bitmask)" % [walkable_count, MAX_WALKABLE_TILES]
		push_error("[LevelSolver] %s: Level has %d walkable tiles (max %d for bitmask)"
			% [level_data.level_id, walkable_count, MAX_WALKABLE_TILES])
		result.solve_time_msec = Time.get_ticks_msec() - start_tick
		return result

	# ——— Determine start position ———
	var cat_start: Vector2i = level_data.cat_start
	if not _is_walkable(cat_start):
		# Fallback: first walkable tile in row-major order (per design doc).
		# Iterate grid explicitly rather than relying on Dictionary insertion order.
		for row in range(_grid_height):
			for col in range(_grid_width):
				var coord := Vector2i(col, row)
				if _pos_to_index.has(coord):
					cat_start = coord
					break
			if _is_walkable(cat_start):
				break

	# ——— Goal mask ———
	var goal_mask: int = (1 << walkable_count) - 1

	# ——— Initial state: starting tile already covered ———
	var init_mask: int = 1 << _pos_to_index[cat_start]

	# Trivial case: only 1 walkable tile — already covered
	if init_mask == goal_mask:
		result.minimum_moves = 0
		result.states_explored = 1
		result.solve_time_msec = Time.get_ticks_msec() - start_tick
		return result

	# ——— BFS ———
	var queue: Array[_BFSState] = []
	var visited: Dictionary = {}

	var init_state := _BFSState.new(cat_start, init_mask, 0)
	var init_key: String = _state_key(cat_start, init_mask)
	visited[init_key] = true
	queue.push_back(init_state)

	var head: int = 0 # Queue front pointer (avoids pop_front O(n))
	var states_explored: int = 0

	while head < queue.size():
		var current: _BFSState = queue[head]
		head += 1
		states_explored += 1

		if states_explored == WARN_STATE_THRESHOLD:
			push_warning("[LevelSolver] %s: 1M states explored at depth %d — level may be very large"
				% [level_data.level_id, current.depth])

		# Try all 4 directions
		for dir: Vector2i in DIRECTIONS:
			var landing: Vector2i = _resolve_slide(current.pos, dir)

			# No movement — skip
			if landing == current.pos:
				continue

			# Update coverage mask for all traversed tiles
			var new_mask: int = current.mask
			var step: Vector2i = current.pos + dir
			var end: Vector2i = landing + dir
			while step != end:
				if _pos_to_index.has(step):
					new_mask |= (1 << _pos_to_index[step])
				step += dir

			# Goal check
			if new_mask == goal_mask:
				result.minimum_moves = current.depth + 1
				result.states_explored = states_explored
				result.solve_time_msec = Time.get_ticks_msec() - start_tick
				return result

			# Visited check
			var key: String = _state_key(landing, new_mask)
			if not visited.has(key):
				visited[key] = true
				queue.push_back(_BFSState.new(landing, new_mask, current.depth + 1))

	# Queue exhausted — unsolvable
	result.minimum_moves = -1
	result.states_explored = states_explored
	result.solve_time_msec = Time.get_ticks_msec() - start_tick
	result.error = "Level is unsolvable"
	push_error("[LevelSolver] ERROR: %s is unsolvable!" % level_data.level_id)
	return result


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Clears all per-solve instance state so consecutive calls are independent.
func _reset_state() -> void:
	_pos_to_index.clear()
	_grid_width = 0
	_grid_height = 0
	_walkability = PackedInt32Array()


## Local walkability check operating on LevelData arrays — does not call
## the runtime GridSystem autoload.
func _is_walkable(coord: Vector2i) -> bool:
	if coord.x < 0 or coord.y < 0 or coord.x >= _grid_width or coord.y >= _grid_height:
		return false
	var index: int = coord.x + coord.y * _grid_width
	if index >= _walkability.size():
		return false
	return _walkability[index] == TILE_WALKABLE


## Slide resolution — mirrors SlidingMovement.resolve_slide() but uses
## local _is_walkable() instead of the GridSystem autoload.
func _resolve_slide(start: Vector2i, direction: Vector2i) -> Vector2i:
	var pos: Vector2i = start
	var iterations: int = 0
	while _is_walkable(pos + direction) and iterations < MAX_SLIDE_DISTANCE:
		pos += direction
		iterations += 1
	return pos


## Builds the BFS visited-set key string per design doc specification.
func _state_key(pos: Vector2i, mask: int) -> String:
	return "%d,%d|%d" % [pos.x, pos.y, mask]

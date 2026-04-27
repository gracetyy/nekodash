## HomeTileArt — world-aware gameplay tile art selection and layout packing.
class_name HomeTileArt
extends RefCounted


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const SIMPLE_FLOOR_TEXTURE: Texture2D = preload("res://assets/art/tiles/grids/grid_mint.png")
const SIMPLE_VISITED_TEXTURE: Texture2D = preload("res://assets/art/tiles/grids/grid_yellow.png")
const SIMPLE_BLOCKING_TEXTURE: Texture2D = preload("res://assets/art/tiles/grids/grid_purple.png")

const HOME_TILE_ROOT: String = "res://assets/art/tiles/home"
const HKU_TILE_ROOT: String = "res://assets/art/tiles/hku"
const COMMON_FOLDER: String = "common"
const WORLD_TILE_SOURCES: Dictionary = {
	1: {"root": HOME_TILE_ROOT, "folder": "bedroom", "include_common": true},
	2: {"root": HOME_TILE_ROOT, "folder": "kitchen", "include_common": true},
	3: {"root": HOME_TILE_ROOT, "folder": "living_room", "include_common": true},
	99: {"root": HKU_TILE_ROOT, "folder": "", "include_common": false},
}


# —————————————————————————————————————————————
# Static cache
# —————————————————————————————————————————————

static var _asset_cache: Dictionary = {}


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

static func is_simple_ui_enabled(settings_ref: Node = null) -> bool:
	if settings_ref == null:
		settings_ref = _get_app_settings_node()
	if settings_ref == null:
		return false
	if not settings_ref.has_method("get_simple_ui"):
		return false
	return settings_ref.call("get_simple_ui") as bool


static func get_floor_texture(world_id: int, visited: bool, use_simple_ui: bool = false) -> Texture2D:
	if visited:
		return get_trail_texture(world_id, use_simple_ui)

	var floor_entry: Dictionary = _get_floor_entry_by_key(world_id, "normal", use_simple_ui)
	var texture: Texture2D = floor_entry.get("texture", null) as Texture2D
	if texture != null:
		return texture
	return SIMPLE_FLOOR_TEXTURE


static func get_trail_texture(world_id: int, use_simple_ui: bool = false) -> Texture2D:
	var trail_entry: Dictionary = _get_floor_entry_by_key(
		world_id,
		"visited_paw",
		use_simple_ui,
		["visited"]
	)
	var texture: Texture2D = trail_entry.get("texture", null) as Texture2D
	if texture != null:
		return texture
	return SIMPLE_VISITED_TEXTURE


static func build_layout(level_data: LevelData, use_simple_ui: bool = false) -> Dictionary:
	var world_id: int = _get_world_id(level_data)
	var floor_entry: Dictionary = _get_floor_entry_by_key(world_id, "normal", use_simple_ui)
	var visited_entry: Dictionary = _get_floor_entry_by_key(
		world_id,
		"visited",
		use_simple_ui,
		["visited_paw"]
	)
	var trail_entry: Dictionary = _get_floor_entry_by_key(
		world_id,
		"visited_paw",
		use_simple_ui,
		["visited"]
	)
	var layout: Dictionary = {
		"simple_ui": use_simple_ui,
		"floor_texture": floor_entry.get("texture", SIMPLE_FLOOR_TEXTURE),
		"floor_path": floor_entry.get("path", "res://assets/art/tiles/grids/grid_mint.png"),
		"visited_texture": visited_entry.get("texture", SIMPLE_VISITED_TEXTURE),
		"visited_path": visited_entry.get("path", "res://assets/art/tiles/grids/grid_yellow.png"),
		"trail_texture": trail_entry.get("texture", SIMPLE_VISITED_TEXTURE),
		"trail_path": trail_entry.get("path", "res://assets/art/tiles/grids/grid_yellow.png"),
		"blocking_texture": SIMPLE_BLOCKING_TEXTURE,
		"blocking_path": "res://assets/art/tiles/grids/grid_purple.png",
		"wall_draws": [],
		"obstacles": [],
	}

	if level_data == null or use_simple_ui:
		return layout

	var dims: Vector2i = _get_level_dimensions(level_data)
	if dims.x == 0 or dims.y == 0:
		return layout

	var world_assets: Dictionary = _get_world_assets(world_id)
	var wall_assets: Array = world_assets.get("wall_assets", []) as Array
	var wall_draws: Array[Dictionary] = []
	var remaining_blocked: Dictionary = {}

	for row: int in range(dims.y):
		for col: int in range(dims.x):
			var coord: Vector2i = Vector2i(col, row)
			if not _is_blocked(level_data, coord, dims):
				continue
			if _is_outer_coord(coord, dims):
				var wall_texture_key: String = "%s|wall|%d|%d" % [level_data.level_id, col, row]
				var wall_asset: Dictionary = _pick_wall_asset(
					wall_assets,
					coord,
					dims,
					wall_texture_key
				)
				var wall_texture: Texture2D = wall_asset.get("texture", SIMPLE_BLOCKING_TEXTURE) as Texture2D
				wall_draws.append({
					"coord": coord,
					"path": wall_asset.get("path", "res://assets/art/tiles/grids/grid_purple.png"),
					"texture": wall_texture,
				})
				continue
			remaining_blocked[coord] = true

	layout["wall_draws"] = wall_draws
	layout["obstacles"] = _build_obstacle_draws(level_data, dims, remaining_blocked, world_assets)
	return layout


# —————————————————————————————————————————————
# Asset loading
# —————————————————————————————————————————————

static func _get_world_assets(world_id: int) -> Dictionary:
	if _asset_cache.has(world_id):
		return _asset_cache[world_id] as Dictionary

	var assets: Dictionary = {
		"floors": {},
		"wall_assets": [],
		"obstacle_groups": {},
		"tabletop_items": [],
	}

	var world_source: Dictionary = _get_world_tile_source(world_id)
	var source_root: String = str(world_source.get("root", HOME_TILE_ROOT))
	var source_folder: String = str(world_source.get("folder", ""))
	var include_common: bool = world_source.get("include_common", false) as bool

	if include_common:
		_merge_asset_folder(assets, source_root.path_join(COMMON_FOLDER))

	if source_folder == "":
		_merge_asset_folder(assets, source_root)
	else:
		_merge_asset_folder(assets, source_root.path_join(source_folder))
		# Keep walls world-specific even when common assets are merged.
		var wall_assets: Array = assets.get("wall_assets", []) as Array
		var world_wall_assets: Array = _filter_assets_by_path_token(
			wall_assets,
			"/%s/" % source_folder
		)
		if not world_wall_assets.is_empty():
			assets["wall_assets"] = world_wall_assets

	_asset_cache[world_id] = assets
	return assets


static func _get_world_tile_source(world_id: int) -> Dictionary:
	var world_source: Dictionary = WORLD_TILE_SOURCES.get(world_id, {}) as Dictionary
	if not world_source.is_empty():
		return world_source
	return WORLD_TILE_SOURCES.get(1, {}) as Dictionary


static func _merge_asset_folder(asset_set: Dictionary, folder_path: String) -> void:
	var directory: DirAccess = DirAccess.open(folder_path)
	if directory == null:
		return

	var bucket_names: Array[String] = []
	directory.list_dir_begin()
	while true:
		var entry: String = directory.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		if directory.current_is_dir():
			bucket_names.append(entry)
	directory.list_dir_end()

	bucket_names.sort()
	for bucket_name: String in bucket_names:
		_merge_asset_bucket(asset_set, folder_path.path_join(bucket_name), bucket_name)


static func _merge_wall_buckets_only(asset_set: Dictionary, folder_path: String) -> void:
	var directory: DirAccess = DirAccess.open(folder_path)
	if directory == null:
		return

	var bucket_names: Array[String] = []
	directory.list_dir_begin()
	while true:
		var entry: String = directory.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		if directory.current_is_dir() and entry.ends_with("_wall_tile"):
			bucket_names.append(entry)
	directory.list_dir_end()

	bucket_names.sort()
	for bucket_name: String in bucket_names:
		_merge_asset_bucket(asset_set, folder_path.path_join(bucket_name), bucket_name)


static func _merge_asset_bucket(asset_set: Dictionary, bucket_path: String, bucket_name: String) -> void:
	var png_paths: Array[String] = _list_png_files(bucket_path)
	if png_paths.is_empty():
		return

	if bucket_name.ends_with("_floor_tile"):
		for asset_path: String in png_paths:
			var texture: Texture2D = _load_png_texture(asset_path)
			if texture == null:
				continue
			var base_name: String = _basename_from_path(asset_path).to_lower()
			var floor_key: String = "normal"
			if base_name.find("visited_paw") >= 0:
				floor_key = "visited_paw"
			elif base_name.find("visited") >= 0:
				floor_key = "visited"
			var floor_entries: Dictionary = asset_set.get("floors", {}) as Dictionary
			floor_entries[floor_key] = {
				"name": _basename_from_path(asset_path),
				"path": asset_path,
				"texture": texture,
			}
			asset_set["floors"] = floor_entries
		return

	if bucket_name.ends_with("_wall_tile"):
		var wall_assets: Array = asset_set.get("wall_assets", []) as Array
		for asset_path: String in png_paths:
			var texture: Texture2D = _load_png_texture(asset_path)
			if texture == null:
				continue
			wall_assets.append({
				"name": _basename_from_path(asset_path),
				"path": asset_path,
				"texture": texture,
			})
		_sort_assets_by_name(wall_assets)
		asset_set["wall_assets"] = wall_assets
		return

	if bucket_name.ends_with("_tabletop_item"):
		var tabletop_items: Array = asset_set.get("tabletop_items", []) as Array
		for asset_path: String in png_paths:
			var texture: Texture2D = _load_png_texture(asset_path)
			if texture == null:
				continue
			tabletop_items.append({
				"name": _basename_from_path(asset_path),
				"path": asset_path,
				"texture": texture,
			})
		_sort_assets_by_name(tabletop_items)
		asset_set["tabletop_items"] = tabletop_items
		return

	if bucket_name.ends_with("_obstacle_tile") or bucket_name.ends_with("_obstacle_tile_side_facing"):
		var parsed_size: Vector2 = _parse_size_from_bucket(bucket_name)
		var obstacle_size: Vector2i = Vector2i(int(round(parsed_size.x)), int(round(parsed_size.y)))
		if obstacle_size.x <= 0 or obstacle_size.y <= 0:
			return

		var side_facing: bool = bucket_name.ends_with("_obstacle_tile_side_facing")
		var group_key: String = "%dx%d|%s" % [
			obstacle_size.x,
			obstacle_size.y,
			"side" if side_facing else "top",
		]

		var obstacle_groups: Dictionary = asset_set.get("obstacle_groups", {}) as Dictionary
		if not obstacle_groups.has(group_key):
			obstacle_groups[group_key] = {
				"size": obstacle_size,
				"side_facing": side_facing,
				"assets": [],
			}

		var group: Dictionary = obstacle_groups[group_key] as Dictionary
		var assets: Array = group.get("assets", []) as Array
		for asset_path: String in png_paths:
			var texture: Texture2D = _load_png_texture(asset_path)
			if texture == null:
				continue
			assets.append({
				"name": _basename_from_path(asset_path),
				"path": asset_path,
				"texture": texture,
			})
		_sort_assets_by_name(assets)
		group["assets"] = assets
		obstacle_groups[group_key] = group
		asset_set["obstacle_groups"] = obstacle_groups


static func _list_png_files(folder_path: String) -> Array[String]:
	var directory: DirAccess = DirAccess.open(folder_path)
	if directory == null:
		return []

	var file_names: Array[String] = []
	directory.list_dir_begin()
	while true:
		var entry: String = directory.get_next()
		if entry == "":
			break
		if entry.begins_with(".") or directory.current_is_dir():
			continue
		
		var entry_lower := entry.to_lower()
		if entry_lower.ends_with(".png"):
			if not entry in file_names:
				file_names.append(entry)
		elif entry_lower.ends_with(".png.import") or entry_lower.ends_with(".png.remap"):
			var base_file := entry.get_basename()
			if not base_file in file_names:
				file_names.append(base_file)
	
	directory.list_dir_end()

	file_names.sort()
	var file_paths: Array[String] = []
	for file_name: String in file_names:
		file_paths.append(folder_path.path_join(file_name))
	return file_paths


static func _sort_assets_by_name(assets: Array) -> void:
	assets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)


# —————————————————————————————————————————————
# Layout packing
# —————————————————————————————————————————————

static func _build_obstacle_draws(
	level_data: LevelData,
	dims: Vector2i,
	remaining_blocked: Dictionary,
	world_assets: Dictionary,
) -> Array[Dictionary]:
	var obstacle_draws: Array[Dictionary] = []
	var ordered_groups: Array = _get_ordered_obstacle_groups(
		world_assets.get("obstacle_groups", {}) as Dictionary
	)

	for group: Dictionary in ordered_groups:
		var size: Vector2i = group.get("size", Vector2i.ONE) as Vector2i
		var assets: Array = group.get("assets", []) as Array
		var side_facing: bool = group.get("side_facing", false) as bool

		for row: int in range(dims.y - size.y + 1):
			for col: int in range(dims.x - size.x + 1):
				var origin: Vector2i = Vector2i(col, row)
				if not _can_place_obstacle(remaining_blocked, origin, size):
					continue
				var side_facing_orientation: int = 0 # 0=none, 1=right, -1=left (flipped)
				if side_facing:
					side_facing_orientation = _get_side_facing_orientation(level_data, origin, size, dims)
					if side_facing_orientation == 0:
						continue

				var obstacle_asset: Dictionary = _pick_asset(
					assets,
					"%s|obstacle|%d|%d|%d|%d" % [
						level_data.level_id,
						origin.x,
						origin.y,
						size.x,
						size.y,
					]
				)
				var obstacle_texture: Texture2D = obstacle_asset.get("texture", SIMPLE_BLOCKING_TEXTURE) as Texture2D
				var asset_name: String = str(obstacle_asset.get("name", ""))
				var tabletop_texture: Texture2D = _pick_tabletop_texture(
					world_assets,
					level_data.level_id,
					origin,
					asset_name
				)

				obstacle_draws.append({
					"origin": origin,
					"size": size,
					"path": obstacle_asset.get("path", "res://assets/art/tiles/grids/grid_purple.png"),
					"texture": obstacle_texture,
					"asset_name": asset_name,
					"side_facing_orientation": side_facing_orientation,
					"tabletop_path": tabletop_texture.get_meta("source_path", "") if tabletop_texture != null else "",
					"tabletop_texture": tabletop_texture,
					"tabletop_offset_y": _get_tabletop_offset_y(size),
				})
				_consume_blocked_cells(remaining_blocked, origin, size)

	for row: int in range(dims.y):
		for col: int in range(dims.x):
			var coord: Vector2i = Vector2i(col, row)
			if not remaining_blocked.has(coord):
				continue
			obstacle_draws.append({
				"origin": coord,
				"size": Vector2i.ONE,
				"path": "res://assets/art/tiles/grids/grid_purple.png",
				"texture": SIMPLE_BLOCKING_TEXTURE,
				"asset_name": "simple_blocking",
				"side_facing_orientation": 0,
				"tabletop_path": "",
				"tabletop_texture": null,
				"tabletop_offset_y": 0.0,
			})
			remaining_blocked.erase(coord)
	return obstacle_draws


static func _get_ordered_obstacle_groups(obstacle_groups: Dictionary) -> Array:
	var ordered_groups: Array = []
	for group_key: String in obstacle_groups.keys():
		ordered_groups.append(obstacle_groups[group_key])

	ordered_groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var size_a: Vector2i = a.get("size", Vector2i.ONE) as Vector2i
		var size_b: Vector2i = b.get("size", Vector2i.ONE) as Vector2i
		var area_a: int = size_a.x * size_a.y
		var area_b: int = size_b.x * size_b.y
		if area_a != area_b:
			return area_a > area_b
		var side_a: bool = a.get("side_facing", false) as bool
		var side_b: bool = b.get("side_facing", false) as bool
		if side_a != side_b:
			return side_a
		if size_a.y != size_b.y:
			return size_a.y > size_b.y
		return size_a.x > size_b.x
	)
	return ordered_groups


static func _can_place_obstacle(remaining_blocked: Dictionary, origin: Vector2i, size: Vector2i) -> bool:
	for offset_y: int in range(size.y):
		for offset_x: int in range(size.x):
			var target: Vector2i = Vector2i(origin.x + offset_x, origin.y + offset_y)
			if not remaining_blocked.has(target):
				return false
	return true


static func _consume_blocked_cells(remaining_blocked: Dictionary, origin: Vector2i, size: Vector2i) -> void:
	for offset_y: int in range(size.y):
		for offset_x: int in range(size.x):
			remaining_blocked.erase(Vector2i(origin.x + offset_x, origin.y + offset_y))


static func _is_side_facing_allowed(
	level_data: LevelData,
	origin: Vector2i,
	size: Vector2i,
	dims: Vector2i,
) -> bool:
	return _get_side_facing_orientation(level_data, origin, size, dims) != 0


static func _get_side_facing_orientation(
	level_data: LevelData,
	origin: Vector2i,
	size: Vector2i,
	dims: Vector2i,
) -> int:
	# Returns: 1 for right-facing, -1 for left-facing (flipped), 0 for not allowed
	# Check right side first (default orientation)
	var right_x: int = origin.x + size.x
	if right_x < dims.x:
		var right_valid: bool = true
		for offset_y: int in range(size.y):
			var wall_coord: Vector2i = Vector2i(right_x, origin.y + offset_y)
			if not _is_outer_coord(wall_coord, dims) or not _is_blocked(level_data, wall_coord, dims):
				right_valid = false
				break
		if right_valid:
			return 1
	# Check left side (flipped orientation)
	var left_x: int = origin.x - 1
	if left_x >= 0:
		var left_valid: bool = true
		for offset_y: int in range(size.y):
			var wall_coord: Vector2i = Vector2i(left_x, origin.y + offset_y)
			if not _is_outer_coord(wall_coord, dims) or not _is_blocked(level_data, wall_coord, dims):
				left_valid = false
				break
		if left_valid:
			return -1
	return 0


static func _pick_wall_asset(
	wall_assets: Array,
	coord: Vector2i,
	dims: Vector2i,
	seed_key: String,
) -> Dictionary:
	var role_token: String = _get_wall_role_token(coord, dims)
	if role_token != "":
		var role_assets: Array = _filter_assets_by_exact_name_token(wall_assets, role_token)
		if not role_assets.is_empty():
			return _pick_asset(role_assets, seed_key)

	return _pick_asset(wall_assets, seed_key)


static func _get_wall_role_token(coord: Vector2i, dims: Vector2i) -> String:
	var max_x: int = dims.x - 1
	var max_y: int = dims.y - 1
	if coord.x == 0 and coord.y == 0:
		return "top_left_corner"
	if coord.x == max_x and coord.y == 0:
		return "top_right_corner"
	if coord.x == 0 and coord.y == max_y:
		return "bottom_left_corner"
	if coord.x == max_x and coord.y == max_y:
		return "bottom_right_corner"
	if coord.x == 0:
		return "left"
	if coord.x == max_x:
		return "right"
	if coord.y == 0:
		return "top"
	if coord.y == max_y:
		return "bottom"
	return ""


static func _filter_assets_by_path_token(assets: Array, token: String) -> Array:
	var token_lower: String = token.to_lower()
	var filtered: Array = []
	for asset: Dictionary in assets:
		var asset_path: String = str(asset.get("path", "")).to_lower()
		if asset_path.find(token_lower) >= 0:
			filtered.append(asset)
	return filtered


static func _filter_assets_by_exact_name_token(assets: Array, token: String) -> Array:
	var token_lower: String = token.to_lower()
	var filtered: Array = []
	for asset: Dictionary in assets:
		var asset_name: String = str(asset.get("name", "")).to_lower()
		var asset_path: String = str(asset.get("path", ""))
		var asset_basename: String = _basename_from_path(asset_path).to_lower()
		if asset_basename == token_lower or asset_name == token_lower:
			filtered.append(asset)
	return filtered


static func _filter_assets_by_name_token(assets: Array, token: String) -> Array:
	var token_lower: String = token.to_lower()
	var filtered: Array = []
	for asset: Dictionary in assets:
		var asset_name: String = str(asset.get("name", "")).to_lower()
		var asset_path: String = str(asset.get("path", "")).to_lower()
		if asset_name.find(token_lower) >= 0 or asset_path.find(token_lower) >= 0:
			filtered.append(asset)
	return filtered


static func _get_tabletop_offset_y(size: Vector2i) -> float:
	# For shelves/tables, place tabletop in upper half
	# Returns offset from top as a fraction of tile_size
	# 0.25 means 25% from top (upper quarter)
	if size.y <= 1:
		return 0.25 # For 1x1, place in upper area
	return 0.25 # For multi-height shelves, place in upper quarter


static func _pick_tabletop_texture(
	world_assets: Dictionary,
	level_id: String,
	origin: Vector2i,
	asset_name: String,
) -> Texture2D:
	if not _is_tabletop_candidate(asset_name):
		return null

	var tabletop_items: Array = world_assets.get("tabletop_items", []) as Array
	var tabletop_asset: Dictionary = _pick_asset(
		tabletop_items,
		"%s|tabletop|%d|%d|%s" % [level_id, origin.x, origin.y, asset_name]
	)
	var tabletop_texture: Texture2D = tabletop_asset.get("texture", null) as Texture2D
	if tabletop_texture != null:
		tabletop_texture.set_meta("source_path", tabletop_asset.get("path", ""))
	return tabletop_texture


static func _pick_asset(assets: Array, seed_key: String) -> Dictionary:
	if assets.is_empty():
		return {}
	var seed_hash: int = abs(seed_key.hash())
	var index: int = seed_hash % assets.size()
	return assets[index] as Dictionary


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

static func _get_world_id(level_data: LevelData) -> int:
	if level_data == null:
		return 1
	return max(level_data.world_id, 1)


static func _get_floor_entry(world_id: int, visited: bool, use_simple_ui: bool) -> Dictionary:
	return _get_floor_entry_by_key(world_id, "visited" if visited else "normal", use_simple_ui)


static func _get_floor_entry_by_key(
	world_id: int,
	floor_key: String,
	use_simple_ui: bool,
	fallback_keys: Array[String] = [],
) -> Dictionary:
	if use_simple_ui:
		var is_normal: bool = floor_key == "normal"
		return {
			"path": "res://assets/art/tiles/grids/grid_mint.png" if is_normal else "res://assets/art/tiles/grids/grid_yellow.png",
			"texture": SIMPLE_FLOOR_TEXTURE if is_normal else SIMPLE_VISITED_TEXTURE,
		}

	var world_assets: Dictionary = _get_world_assets(world_id)
	var floor_entries: Dictionary = world_assets.get("floors", {}) as Dictionary
	var floor_entry: Dictionary = floor_entries.get(floor_key, {}) as Dictionary
	if not floor_entry.is_empty():
		return floor_entry

	for fallback_key: String in fallback_keys:
		var fallback_entry: Dictionary = floor_entries.get(fallback_key, {}) as Dictionary
		if not fallback_entry.is_empty():
			return fallback_entry

	if floor_key != "normal":
		var visited_entry: Dictionary = floor_entries.get("visited", {}) as Dictionary
		if not visited_entry.is_empty():
			return visited_entry

	var is_normal_default: bool = floor_key == "normal"
	return {
		"path": "res://assets/art/tiles/grids/grid_mint.png" if is_normal_default else "res://assets/art/tiles/grids/grid_yellow.png",
		"texture": SIMPLE_FLOOR_TEXTURE if is_normal_default else SIMPLE_VISITED_TEXTURE,
	}


static func _get_level_dimensions(level_data: LevelData) -> Vector2i:
	if level_data == null:
		return Vector2i.ZERO
	return Vector2i(
		maxi(mini(level_data.grid_width, GridSystem.MAX_GRID_SIZE), 0),
		maxi(mini(level_data.grid_height, GridSystem.MAX_GRID_SIZE), 0)
	)


static func _is_outer_coord(coord: Vector2i, dims: Vector2i) -> bool:
	return coord.x == 0 \
		or coord.y == 0 \
		or coord.x == dims.x - 1 \
		or coord.y == dims.y - 1


static func _is_blocked(level_data: LevelData, coord: Vector2i, dims: Vector2i) -> bool:
	if level_data == null:
		return true
	if coord.x < 0 or coord.y < 0 or coord.x >= dims.x or coord.y >= dims.y:
		return true

	var walkability_arr: PackedInt32Array = level_data.walkability_tiles
	var obstacle_arr: PackedInt32Array = level_data.obstacle_tiles
	var index: int = coord.x + coord.y * level_data.grid_width
	var walk_val: int = walkability_arr[index] if index < walkability_arr.size() else GridSystem.TileWalkability.BLOCKING
	var obstacle_val: int = obstacle_arr[index] if index < obstacle_arr.size() else GridSystem.ObstacleType.NONE
	return walk_val == GridSystem.TileWalkability.BLOCKING or obstacle_val != GridSystem.ObstacleType.NONE


static func _parse_size_from_bucket(bucket_name: String) -> Vector2:
	var size_token_parts: PackedStringArray = bucket_name.split("_", false, 1)
	if size_token_parts.is_empty():
		return Vector2.ZERO

	var size_parts: PackedStringArray = size_token_parts[0].split("x", false, 1)
	if size_parts.size() != 2:
		return Vector2.ZERO

	return Vector2(float(size_parts[0]), float(size_parts[1]))


static func _basename_from_path(asset_path: String) -> String:
	var file_name: String = asset_path.get_file()
	var extension_index: int = file_name.rfind(".")
	if extension_index == -1:
		return file_name
	return file_name.substr(0, extension_index)


static func _is_tabletop_candidate(asset_name: String) -> bool:
	var normalized_name: String = asset_name.to_lower()
	return normalized_name.find("table") >= 0 or normalized_name.find("shelf") >= 0


static func _get_app_settings_node() -> Node:
	var main_loop: MainLoop = Engine.get_main_loop()
	if not main_loop is SceneTree:
		return null
	var tree: SceneTree = main_loop as SceneTree
	if tree.root == null:
		return null
	return tree.root.get_node_or_null("AppSettings")


static func _load_png_texture(asset_path: String) -> Texture2D:
	return load(asset_path) as Texture2D

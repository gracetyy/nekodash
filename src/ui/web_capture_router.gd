## WebCaptureRouter — routes HTML5 builds to specific screens for web UI snapshots.
## Usage:
##   Export with the custom feature `dev_capture`, then open:
##   http://localhost:8060/index.html?capture_ui=1&screen=main_menu
extends Node

const CAPTURE_PARAM: String = "capture_ui"
const SCREEN_PARAM: String = "screen"
const DELAY_PARAM: String = "delay_ms"
const DEV_CAPTURE_FEATURE: String = "dev_capture"
const WEB_VIEWPORT_FIX_SCRIPT: String = """
(function () {
	if (window.__nekodashViewportFixInstalled) {
		if (typeof window.__nekodashApplyViewportFix === 'function') {
			window.__nekodashApplyViewportFix();
		}
		return;
	}

	function applyViewportFix() {
		const html = document.documentElement;
		const body = document.body;
		const canvas = document.getElementById('canvas');
		const status = document.getElementById('status');
		const splash = document.getElementById('status-splash');
		const progress = document.getElementById('status-progress');

		if (html) {
			html.style.margin = '0';
			html.style.padding = '0';
			html.style.border = '0';
			html.style.width = '100vw';
			html.style.height = '100vh';
			html.style.minWidth = '0';
			html.style.minHeight = '0';
			html.style.overflow = 'hidden';
		}

		if (body) {
			body.style.margin = '0';
			body.style.padding = '0';
			body.style.border = '0';
			body.style.width = '100vw';
			body.style.height = '100vh';
			body.style.minWidth = '0';
			body.style.minHeight = '0';
			body.style.overflow = 'hidden';
			body.style.position = 'fixed';
			body.style.inset = '0';
			body.style.touchAction = 'none';
		}

		[canvas, status].forEach(function (element) {
			if (!element) {
				return;
			}
			element.style.position = 'fixed';
			element.style.inset = '0';
			element.style.width = '100vw';
			element.style.height = '100vh';
			element.style.minWidth = '0';
			element.style.minHeight = '0';
		});

		if (canvas) {
			canvas.style.display = 'block';
		}

		if (splash) {
			splash.style.maxWidth = '100vw';
			splash.style.maxHeight = '100vh';
			splash.style.margin = 'auto';
		}

		if (progress) {
			progress.style.left = '0';
			progress.style.right = '0';
		}
	}

	function pulseViewportResize() {
		try {
			window.dispatchEvent(new Event('resize'));
		} catch (_err) {
		}
	}

	window.__nekodashApplyViewportFix = applyViewportFix;
	window.__nekodashViewportFixInstalled = true;
	applyViewportFix();
	pulseViewportResize();
	window.addEventListener('resize', applyViewportFix, { passive: true });
	if (window.visualViewport) {
		window.visualViewport.addEventListener('resize', applyViewportFix, { passive: true });
	}
	window.setTimeout(function () {
		applyViewportFix();
		pulseViewportResize();
	}, 0);
	window.setTimeout(function () {
		applyViewportFix();
		pulseViewportResize();
	}, 120);
	window.setTimeout(function () {
		applyViewportFix();
		pulseViewportResize();
	}, 500);

	const observer = new MutationObserver(applyViewportFix);
	const canvas = document.getElementById('canvas');
	const status = document.getElementById('status');
	if (canvas) {
		observer.observe(canvas, { attributes: true, attributeFilter: ['style'] });
	}
	if (status) {
		observer.observe(status, { attributes: true, attributeFilter: ['style'] });
	}
}());
"""


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_apply_web_viewport_fix()
	if not _is_dev_capture_enabled():
		return
	call_deferred("_attempt_capture")


func _is_dev_capture_enabled() -> bool:
	return OS.has_feature(DEV_CAPTURE_FEATURE)


func _apply_web_viewport_fix() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(WEB_VIEWPORT_FIX_SCRIPT, true)


func _attempt_capture() -> void:
	if get_tree() == null:
		return
	var query: String = await _poll_query_string(90)
	if query.is_empty():
		return
	var params: Dictionary = _parse_query_params(query)
	if not _is_capture_enabled(params):
		return
	await _await_scene_manager_idle()
	call_deferred("_route_capture", params)


func _poll_query_string(max_frames: int) -> String:
	if get_tree() == null:
		return ""
	for _i: int in range(max_frames):
		var query: String = _get_query_string()
		if not query.is_empty():
			return query
		await get_tree().process_frame
	return ""


func _get_query_string() -> String:
	if not OS.has_feature("web"):
		return ""
	var query_value: Variant = JavaScriptBridge.eval("window.location.search", true)
	if query_value is String and (query_value as String) != "":
		return query_value as String
	query_value = JavaScriptBridge.eval("location.search", true)
	if query_value is String and (query_value as String) != "":
		return query_value as String
	query_value = JavaScriptBridge.eval("window.location.href", true)
	if query_value is String:
		return _extract_query_from_url(query_value as String)
	return ""


func _extract_query_from_url(url: String) -> String:
	var query_index: int = url.find("?")
	if query_index < 0:
		return ""
	var hash_index: int = url.find("#", query_index)
	if hash_index < 0:
		return url.substr(query_index)
	return url.substr(query_index, hash_index - query_index)


func _parse_query_params(query: String) -> Dictionary:
	var output: Dictionary = {}
	var trimmed: String = query
	if trimmed.begins_with("?"):
		trimmed = trimmed.substr(1)
	if trimmed.is_empty():
		return output
	var pairs: PackedStringArray = trimmed.split("&", false)
	for pair: String in pairs:
		var parts: PackedStringArray = pair.split("=", false, 2)
		if parts.is_empty():
			continue
		var key: String = parts[0]
		var value: String = ""
		if parts.size() > 1:
			value = parts[1]
		output[key] = value
	return output


func _is_capture_enabled(params: Dictionary) -> bool:
	var raw_value: String = str(params.get(CAPTURE_PARAM, ""))
	if raw_value == "1":
		return true
	return raw_value.to_lower() == "true"


func _route_capture(params: Dictionary) -> void:
	if get_tree() == null:
		return
	if SceneManager == null:
		return
	await _await_scene_manager_idle()

	var screen: String = str(params.get(SCREEN_PARAM, "main_menu")).to_lower()
	var delay_ms: int = int(params.get(DELAY_PARAM, 1200))
	match screen:
		"main_menu":
			SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
			await _wait_for_screen(SceneManager.Screen.MAIN_MENU)
		"world_map":
			SceneManager.go_to(SceneManager.Screen.WORLD_MAP, {
				"highlight_world_id": _resolve_last_world_id(),
			})
			await _wait_for_screen(SceneManager.Screen.WORLD_MAP)
		"skin_select":
			SceneManager.go_to(SceneManager.Screen.SKIN_SELECT)
			await _wait_for_screen(SceneManager.Screen.SKIN_SELECT)
		"options":
			await _route_main_menu_then_overlay(SceneManager.Overlay.OPTIONS, "Options")
		"pause":
			await _route_gameplay_then_overlay(SceneManager.Overlay.PAUSE, "")
		"level_complete_plain":
			SceneManager.go_to(SceneManager.Screen.LEVEL_COMPLETE)
			await _wait_for_screen(SceneManager.Screen.LEVEL_COMPLETE)
		"level_complete":
			await _route_level_complete(false, false)
		"level_complete_perfect":
			await _route_level_complete(true, false)
		"level_complete_overlay":
			await _route_level_complete(false, true)
		"gameplay":
			await _route_gameplay()
		_:
			SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
			await _wait_for_screen(SceneManager.Screen.MAIN_MENU)

	if delay_ms > 0:
		await get_tree().create_timer(float(delay_ms) / 1000.0).timeout
	_signal_capture_ready()


func _await_scene_manager_idle(max_frames: int = 120) -> void:
	if get_tree() == null or SceneManager == null:
		return
	for _i: int in range(max_frames):
		if not SceneManager.is_transitioning():
			return
		await get_tree().process_frame


func _wait_for_screen(target_screen: int, max_frames: int = 120) -> void:
	if get_tree() == null or SceneManager == null:
		return
	for _i: int in range(max_frames):
		if SceneManager.get_current_screen() == target_screen and not SceneManager.is_transitioning():
			await get_tree().process_frame
			return
		await get_tree().process_frame


func _wait_for_overlay(target_overlay: int, max_frames: int = 120) -> void:
	if get_tree() == null or SceneManager == null:
		return
	for _i: int in range(max_frames):
		if SceneManager.get_active_overlay() == target_overlay:
			await get_tree().process_frame
			return
		await get_tree().process_frame


func _route_main_menu_then_overlay(overlay: int, title: String) -> void:
	await _await_scene_manager_idle()
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
	await _wait_for_screen(SceneManager.Screen.MAIN_MENU)
	SceneManager.show_overlay(overlay, {
		"title": title,
		"pause_tree": false,
	})
	await _wait_for_overlay(overlay)


func _route_gameplay() -> void:
	var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
	if level_data == null:
		return
	await _await_scene_manager_idle()
	SceneManager.go_to(SceneManager.Screen.GAMEPLAY, {
		"level_data": level_data,
	})
	await _wait_for_screen(SceneManager.Screen.GAMEPLAY)


func _route_gameplay_then_overlay(overlay: int, title: String) -> void:
	await _route_gameplay()
	var params: Dictionary = {
		"pause_tree": false,
	}
	if title != "":
		params["title"] = title
	SceneManager.show_overlay(overlay, params)
	await _wait_for_overlay(overlay)


func _route_level_complete(perfect: bool, use_overlay: bool) -> void:
	var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
	var next_level_data: Resource = load("res://data/levels/world1/w1_l2.tres")
	if level_data == null:
		return

	var final_moves: int = 8
	var prev_best_moves: int = 9
	if perfect:
		var perfect_moves: int = int(level_data.get("minimum_moves"))
		final_moves = perfect_moves
		prev_best_moves = perfect_moves + 1

	var params: Dictionary = {
		"level_data": level_data,
		"stars": 3,
		"final_moves": final_moves,
		"prev_best_moves": prev_best_moves,
		"was_previously_completed": true,
		"next_level_data": next_level_data,
	}

	if use_overlay:
		await _route_gameplay()
		SceneManager.show_overlay(SceneManager.Overlay.LEVEL_COMPLETE, params)
		await _wait_for_overlay(SceneManager.Overlay.LEVEL_COMPLETE)
		return

	await _await_scene_manager_idle()
	SceneManager.go_to(SceneManager.Screen.LEVEL_COMPLETE, params)
	await _wait_for_screen(SceneManager.Screen.LEVEL_COMPLETE)


func _resolve_last_world_id() -> int:
	if AppSettings == null:
		return 1
	return AppSettings.get_last_world_id()


func _signal_capture_ready() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__nekodashCaptureReady = true;")

@tool
extends SceneTree

func _init():
	print("--- NEKODASH SMOKE TEST ---")
	
	var resources = {
		"SceneRegistry": "res://data/scene_registry.tres",
		"GlobalUIAssets": "res://data/global_ui_assets.tres",
		"SfxLibrary": "res://data/sfx_library.tres",
		"TutorialData": "res://data/tutorial_data.tres",
		"GlobalAudio": "res://data/global_audio.tres",
		"LevelCatalogue": "res://data/level_catalogue.tres"
	}
	
	var all_ok = true
	
	for res_name in resources:
		var path = resources[res_name]
		if not ResourceLoader.exists(path):
			print("[ERROR] %s missing at %s" % [res_name, path])
			all_ok = false
			continue
			
		var res = load(path)
		if res == null:
			print("[ERROR] %s failed to load at %s" % [res_name, path])
			all_ok = false
		else:
			print("[OK] %s loaded." % res_name)
			_check_resource_content(res_name, res)

	if all_ok:
		print("--- SMOKE TEST PASSED ---")
		quit(0)
	else:
		print("--- SMOKE TEST FAILED ---")
		quit(1)

func _check_resource_content(name, res):
	match name:
		"SceneRegistry":
			print("  Screens: %d, Overlays: %d" % [res.screen_paths.size(), res.overlay_paths.size()])
			if res.screen_paths.is_empty(): print("  [WARN] No screen paths!")
		"LevelCatalogue":
			print("  Worlds: %d" % res.worlds.size())
			if res.worlds.is_empty(): print("  [WARN] No worlds in catalogue!")
			else:
				for w in res.worlds:
					print("    World %d: %s (%d levels)" % [w.world_id, w.world_name, w.levels.size()])
		"GlobalUIAssets":
			print("  Icons: %d" % res.icons.size())
			if res.title_landscape == null: print("  [WARN] title_landscape is null")
		"SfxLibrary":
			if res.button_tap == null: print("  [WARN] button_tap SFX is null")

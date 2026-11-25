class_name SoundSettings
## Volume and mute (feedback F15) and mouse speed (F187), set on the Settings panel and remembered
## between games in user://settings.cfg on this computer.

const PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"

static var volume := 0.8  ## 0 = silent, 1 = full
static var music_volume := 0.6  ## the Music slider (owner, Nov 25): only the music, on top of the main volume
static var muted := false
static var camera_shake := 1.0  ## 0 = the camera never shakes, 1 = full (F695, owner Nov 22: a slider for it)


## Reads the saved settings (if any) and applies them. Call once when the game starts.
static func load_and_apply(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		volume = clampf(float(cfg.get_value("sound", "volume", volume)), 0.0, 1.0)
		music_volume = clampf(float(cfg.get_value("sound", "music_volume", music_volume)), 0.0, 1.0)
		muted = bool(cfg.get_value("sound", "muted", muted))
		Controls.mouse_scale = clampf(float(cfg.get_value("controls", "mouse_scale", Controls.mouse_scale)), 0.25, 3.0)
		camera_shake = clampf(float(cfg.get_value("controls", "camera_shake", camera_shake)), 0.0, 1.0)
	apply()


static func apply() -> void:
	var mb := AudioServer.get_bus_index(MUSIC_BUS)
	if mb < 0:  # first time: a bus just for the music, so its slider needs no other code
		AudioServer.add_bus()
		mb = AudioServer.bus_count - 1
		AudioServer.set_bus_name(mb, MUSIC_BUS)
	AudioServer.set_bus_volume_db(mb, linear_to_db(maxf(music_volume, 0.0001)))
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, muted)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


static func set_volume(v: float, path: String = PATH) -> void:
	volume = clampf(v, 0.0, 1.0)
	apply()
	save(path)


static func set_music_volume(v: float, path: String = PATH) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	apply()
	save(path)


static func set_muted(m: bool, path: String = PATH) -> void:
	muted = m
	apply()
	save(path)


static func set_mouse_scale(m: float, path: String = PATH) -> void:
	Controls.mouse_scale = clampf(m, 0.25, 3.0)
	save(path)


static func set_camera_shake(k: float, path: String = PATH) -> void:
	camera_shake = clampf(k, 0.0, 1.0)
	save(path)


static func save(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep any other settings already in the file
	cfg.set_value("sound", "volume", volume)
	cfg.set_value("sound", "music_volume", music_volume)
	cfg.set_value("sound", "muted", muted)
	cfg.set_value("controls", "mouse_scale", Controls.mouse_scale)
	cfg.set_value("controls", "camera_shake", camera_shake)
	cfg.save(path)

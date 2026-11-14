class_name SoundSettings
## Volume and mute (feedback F15), set on the pause screen (Esc) and remembered between games
## in user://settings.cfg on this computer.

const PATH := "user://settings.cfg"

static var volume := 0.8  ## 0 = silent, 1 = full
static var muted := false


## Reads the saved settings (if any) and applies them. Call once when the game starts.
static func load_and_apply(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		volume = clampf(float(cfg.get_value("sound", "volume", volume)), 0.0, 1.0)
		muted = bool(cfg.get_value("sound", "muted", muted))
	apply()


static func apply() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, muted)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


static func set_volume(v: float, path: String = PATH) -> void:
	volume = clampf(v, 0.0, 1.0)
	apply()
	save(path)


static func set_muted(m: bool, path: String = PATH) -> void:
	muted = m
	apply()
	save(path)


static func save(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep any other settings already in the file
	cfg.set_value("sound", "volume", volume)
	cfg.set_value("sound", "muted", muted)
	cfg.save(path)

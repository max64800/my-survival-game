class_name Session
extends Node
## Session: connects friends together.
##
## Two ways to connect (the game code doesn't care which one is used):
##  - Direct (ENet): type the host's IP address. Great for testing on one PC
##    (two game windows) or on the same home network.
##  - Steam: the host makes a friends-only Steam lobby, friends join from the
##    Steam friends list ("Join game") or the invite. Needs Steam running.
##
## Steam note: we use Valve's public test app id 480 ("Spacewar") until the game has
## its own Steam app id. Everyone must be logged into Steam.

signal status_changed(text: String)
signal connected_as_client
signal connection_failed(reason: String)
signal host_ready

const DEFAULT_PORT := 24570
const MAX_FRIENDS := 3  ## plus the host = 4 players
const STEAM_TEST_APP_ID := 480

var steam: Object = null  ## the GodotSteam singleton, if Steam is running
var lobby_id := 0


func _ready() -> void:
	multiplayer.connected_to_server.connect(func(): status_changed.emit("Connected!"); connected_as_client.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit("Couldn't reach the host."))


func _process(_delta: float) -> void:
	if steam:
		steam.run_callbacks()


# ---------------------------------------------------------------- direct (ENet)

func host_direct(port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_FRIENDS)
	if err != OK:
		connection_failed.emit("Couldn't open port %d (error %d). Is another game already hosting?" % [port, err])
		return false
	multiplayer.multiplayer_peer = peer
	status_changed.emit("Hosting on port %d. Friends join with your IP address." % port)
	host_ready.emit()
	return true


func join_direct(address: String, port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		connection_failed.emit("Couldn't start connecting (error %d)." % err)
		return false
	multiplayer.multiplayer_peer = peer
	status_changed.emit("Connecting to %s…" % address)
	return true


# ---------------------------------------------------------------- Steam
# Written against GodotSteam 4.24 (GDExtension). Not yet tested with real Steam
# accounts: test this on the gaming PC (needs 2 Steam accounts / 2 PCs).

func steam_available() -> bool:
	if steam:
		return true
	if not Engine.has_singleton("Steam"):
		return false
	var s: Object = Engine.get_singleton("Steam")
	var r: Dictionary = s.steamInitEx(STEAM_TEST_APP_ID, false)
	if r.get("status", 1) != 0:
		push_warning("Steam not available: %s" % r.get("verbal", "?"))
		return false
	steam = s
	steam.lobby_created.connect(_on_lobby_created)
	steam.lobby_joined.connect(_on_lobby_joined)
	steam.join_requested.connect(_on_join_requested)
	return true


func host_steam() -> bool:
	if not steam_available():
		connection_failed.emit("Steam isn't running (or isn't logged in).")
		return false
	status_changed.emit("Making a Steam lobby…")
	steam.createLobby(steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_FRIENDS + 1)
	return true


func join_steam_lobby(id: int) -> bool:
	if not steam_available():
		connection_failed.emit("Steam isn't running (or isn't logged in).")
		return false
	status_changed.emit("Joining your friend's lobby…")
	steam.joinLobby(id)
	return true


func _on_lobby_created(result: int, id: int) -> void:
	if result != 1:  # 1 = OK in Steam's result codes
		connection_failed.emit("Steam couldn't make a lobby (code %d)." % result)
		return
	lobby_id = id
	steam.setLobbyJoinable(id, true)
	steam.setLobbyData(id, "game", "dwarf_game")
	var peer: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	status_changed.emit("Steam lobby ready. Friends can join from your Steam profile.")
	host_ready.emit()


func _on_lobby_joined(id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		connection_failed.emit("Couldn't join that lobby (code %d)." % response)
		return
	var owner_id: int = steam.getLobbyOwner(id)
	if owner_id == steam.getSteamID():
		return  # that's our own lobby
	lobby_id = id
	var peer: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
	peer.create_client(owner_id, 0)
	multiplayer.multiplayer_peer = peer


## A friend clicked "Join game" on us in Steam.
func _on_join_requested(id: int, _friend_id: int) -> void:
	join_steam_lobby(id)


func leave() -> void:
	if steam and lobby_id != 0:
		steam.leaveLobby(lobby_id)
		lobby_id = 0
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

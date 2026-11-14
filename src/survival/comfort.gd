class_name Comfort
## How cozy a spot is (the "Cozy" rest buff). Rest near a campfire or bed for a few seconds and you
## get Cozy: faster healing, faster stamina, for longer the cozier the place is.
##   +1 for the fire or bed you rest at
##   +1 for each DIFFERENT kind of furniture or homely station within 8 m (two tables still count once)
##   +1 for a roof over your head (a built floor or roof piece above you)

const RANGE := 8.0
const REST_RANGE := 4.0
const MAX := 12
## Things that make a place homely, and the "kind" they count as.
const KINDS := {
	"table": "table", "chair": "chair", "bench": "bench", "rug": "rug", "banner": "banner",
	"wall_shield": "wall_shield", "wall_sconce": "light", "shelf": "shelf", "barrel": "barrel",
	"crate": "crate", "weapon_rack": "weapon_rack",
	"column_base": "column", "column_shaft": "column", "column_capital": "column", "column": "column",
	"door": "door",
}
const STATION_KINDS := {"bed": "bed", "cooking_pot": "cooking_pot", "crystal_sconce": "light", "glow_lamp": "light",
	"farm_plot": "garden", "training_dummy": "training_dummy"}

const BASE_TIME := 180.0  ## 3 minutes...
const TIME_PER_POINT := 60.0  ## ...plus 1 minute per comfort point
const STAMINA_PER_POINT := 0.05
const HEALTH_MULT := 1.5


## The comfort score at `pos`. `stations` = the referee's stations; `pieces` = Structure.pieces.
static func score(pos: Vector3, stations: Dictionary, pieces: Dictionary) -> int:
	var rest := false
	var kinds := {}
	for st in stations.values():
		var d: float = (st as Node3D).global_position.distance_to(pos)
		if st.kind in ["campfire", "bed"] and d < REST_RANGE:
			rest = true
		if d < RANGE and STATION_KINDS.has(st.kind):
			kinds[STATION_KINDS[st.kind]] = true
	if not rest:
		return 0
	var roof := false
	for uid in pieces:
		var p: Dictionary = pieces[uid]
		var at: Vector3 = p.pos
		if KINDS.has(p.piece) and at.distance_to(pos) < RANGE:
			kinds[KINDS[p.piece]] = true
		if not roof and Pieces.LIST.get(p.piece, {}).get("group", "") in ["roof", "floor"] \
				and at.y > pos.y + 1.5 and at.y < pos.y + 6.0 and Vector2(at.x - pos.x, at.z - pos.z).length() < 2.0:
			roof = true
	return mini(MAX, 1 + kinds.size() + (1 if roof else 0))


static func duration(points: int) -> float:
	return BASE_TIME + TIME_PER_POINT * points

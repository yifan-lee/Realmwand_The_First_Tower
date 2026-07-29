class_name FloorCatalog
extends Resource


@export var floors: Array[FloorDefinition] = []


func get_floor(floor_id: StringName) -> FloorDefinition:
	for definition: FloorDefinition in floors:
		if definition.floor_id == floor_id:
			return definition

	return null
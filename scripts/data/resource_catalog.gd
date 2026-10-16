class_name ResourceCatalog
extends RefCounted

const SITES := {
	&"forest": {"resource_id": &"wood", "rate": 12.0},
	&"mine": {"resource_id": &"spirit_stone", "rate": 8.0},
	&"field": {"resource_id": &"food", "rate": 10.0},
}


static func get_site(site_id: StringName) -> Dictionary:
	return SITES.get(site_id, {})

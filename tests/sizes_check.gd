extends Node3D

## LAS MEDIDAS DE LOS SEIS ARQUETIPOS, impresas (headless, un segundo): cada número que sale de SkeletonSizesUtil
## —alto, cápsula, piernas, brazos, la marcha— y dónde cae cada hueso en reposo. Para comparar antes y después de tocar
## el cálculo de medidas: si un cambio no debería cambiar a nadie, las dos salidas tienen que ser iguales.
##   godot --headless --path . res://tests/sizes_check.tscn

const FIELDS := ["total_height", "leg_height", "torso_height", "head_height", "hips_width", "shoulders_width",
	"arm_reach", "interaction_reach", "arm_stretch", "hand_width", "head_drop", "neck_anchor", "ankle_height",
	"standing_pelvis_height", "distance_from_ground", "raycast_leg_length", "raycast_stance_offset",
	"raycast_start_y_offset", "pole_distance", "step_height", "foot_reach", "walk_stride", "leg_reach",
	"slouchiness_neck", "spine_bend_chest", "spine_bend_lower", "shoulder_forward", "shoulder_drop",
	"arm_openness_angle", "arm_bentness", "neck_size", "head_size", "chest_size", "higher_spine_size",
	"lower_spine_size", "hip_size", "shoulder_width", "upper_arm_size", "lower_arm_size", "higher_leg_size",
	"lower_leg_size", "foot_size", "left_arm_tip_rest_local", "left_arm_pole_rest_local",
	"left_arm_shoulder_rest_local"]


func _ready() -> void:
	for row in PeopleArchetype.catalogue():
		var kind := (row as PeopleArchetype).archetype
		var look := CharacterLooks.for_archetype(kind)
		var inst := EntityInstantiation.create(EntityInstantiation.debug_seed(kind, look.seed))
		var s := SkeletonSizesUtil.create(inst)
		var name_ := String(EntityArchetype.Archetype.keys()[kind])
		for field: String in FIELDS:
			print("%s %s %s" % [name_, field, _fmt(s.get(field))])
		print("%s cabeza %s" % [name_, _fmt(Vector3(s.head_form.bottom_width, s.head_form.total_height(),
			s.head_form.top_width))])
		var bones := CustomBonesUtil.create(s, inst)
		add_child(bones.lower_spine)
		for bone in bones.get_all_bones():
			print("%s hueso %s %s %s" % [name_, bone.name, _fmt(bone.global_position), _fmt(bone.capsule_dimensions)])
		bones.lower_spine.queue_free()
	get_tree().quit()


static func _fmt(value: Variant) -> String:
	if value is float:
		return "%.4f" % value
	if value is Vector3:
		return "(%.4f, %.4f, %.4f)" % [value.x, value.y, value.z]
	return str(value)

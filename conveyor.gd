@tool
class_name Conveyor
extends Node3D

@export_category("Dimensions")
@export_range(1.0, 30.0, 0.5) var length := 6.0:
	set(v): length = v; _queue_rebuild()
@export_range(0.5, 10.0, 0.1) var width := 2.0:
	set(v): width = v; _queue_rebuild()
@export_range(0.05, 1.0, 0.05) var belt_thickness := 0.2:
	set(v): belt_thickness = v; _queue_rebuild()
@export_range(0.1, 3.0, 0.1) var wall_height := 0.6:
	set(v): wall_height = v; _queue_rebuild()
@export_range(0.05, 0.5, 0.05) var wall_thickness := 0.12:
	set(v): wall_thickness = v; _queue_rebuild()
@export_range(0.0, 1.0, 0.05) var surface_friction := 0.0

@export_category("Walls")
## Gap offset: distance of the opening's center from the wall's middle.
## Side walls: positive = toward the output end. Front/back walls: positive = right.
## Gap size 0 = solid wall.
@export_group("Left Wall", "left_")
@export var left_wall_enabled := true:
	set(v): left_wall_enabled = v; _queue_rebuild()
@export_range(-30.0, 30.0, 0.05, "suffix:m") var left_gap_offset := 0.0:
	set(v): left_gap_offset = v; _queue_rebuild()
@export_range(0.0, 30.0, 0.05, "suffix:m") var left_gap_size := 0.0:
	set(v): left_gap_size = v; _queue_rebuild()

@export_group("Right Wall", "right_")
@export var right_wall_enabled := true:
	set(v): right_wall_enabled = v; _queue_rebuild()
@export_range(-30.0, 30.0, 0.05, "suffix:m") var right_gap_offset := 0.0:
	set(v): right_gap_offset = v; _queue_rebuild()
@export_range(0.0, 30.0, 0.05, "suffix:m") var right_gap_size := 0.0:
	set(v): right_gap_size = v; _queue_rebuild()

@export_group("Front Wall (output end)", "front_")
@export var front_wall_enabled := false:
	set(v): front_wall_enabled = v; _queue_rebuild()
@export_range(-10.0, 10.0, 0.05, "suffix:m") var front_gap_offset := 0.0:
	set(v): front_gap_offset = v; _queue_rebuild()
@export_range(0.0, 10.0, 0.05, "suffix:m") var front_gap_size := 0.0:
	set(v): front_gap_size = v; _queue_rebuild()

@export_group("Back Wall (input end)", "back_")
@export var back_wall_enabled := false:
	set(v): back_wall_enabled = v; _queue_rebuild()
@export_range(-10.0, 10.0, 0.05, "suffix:m") var back_gap_offset := 0.0:
	set(v): back_gap_offset = v; _queue_rebuild()
@export_range(0.0, 10.0, 0.05, "suffix:m") var back_gap_size := 0.0:
	set(v): back_gap_size = v; _queue_rebuild()

@export_group("")
@export_category("Materials")
@export var belt_material: Material:
	set(v): belt_material = v; _queue_rebuild()
@export var wall_material: Material:
	set(v): wall_material = v; _queue_rebuild()

@export_category("Movement")
@export_range(0.0, 20.0, 0.1) var belt_speed := 2.5
@export_range(0.1, 50.0, 0.5) var acceleration := 15.0
## How far past its edges this conveyor can still claim/keep a body.
## This overlap is what hands cash from one conveyor to the next.
@export_range(0.0, 1.0, 0.05, "suffix:m") var handoff_margin := 0.15
## Only bodies in this group are moved. Leave empty to move every RigidBody3D.
@export var target_group := "printed_cash"
## Physics layers the conveyor detects.
@export_flags_3d_physics var detection_mask := 1
## Physics layer(s) the belt itself sits on.
@export_flags_3d_physics var belt_layer := 1:
	set(v): belt_layer = v; _queue_rebuild()

@export_category("Guidance")
## How hard cash is pulled toward the center lane. 0 = off.
@export_range(0.0, 10.0, 0.1) var centering_strength := 2.0
## Cash within this distance of the center line isn't nudged.
@export_range(0.0, 2.0, 0.05, "suffix:m") var centering_deadzone := 0.2
## Cap on sideways centering speed.
@export_range(0.0, 5.0, 0.1) var max_centering_speed := 1.0

const OWNER_META := &"_conveyor_owner"
const PARTS := [
	"belt",
	"left_a", "left_b", "right_a", "right_b",
	"front_a", "front_b", "back_a", "back_b",
]

var _body: StaticBody3D
var _area: Area3D
var _area_col: CollisionShape3D
var _parts := {} # name -> {mesh, col}
var _dirty := false


func _ready() -> void:
	_build_nodes()
	_rebuild()


func _build_nodes() -> void:
	if _body:
		return

	_body = StaticBody3D.new()
	_body.name = "ConveyorBody"
	add_child(_body, false, Node.INTERNAL_MODE_FRONT)
	
	var mat := PhysicsMaterial.new()
	mat.friction = surface_friction
	mat.bounce = 0.0
	_body.physics_material_override = mat

	for part in PARTS:
		var mesh := MeshInstance3D.new()
		var col := CollisionShape3D.new()
		_body.add_child(mesh)
		_body.add_child(col)
		_parts[part] = {"mesh": mesh, "col": col}

	_area = Area3D.new()
	_area.name = "ConveyorDetection"
	_area.monitorable = false
	add_child(_area, false, Node.INTERNAL_MODE_FRONT)

	_area_col = CollisionShape3D.new()
	_area.add_child(_area_col)


func _queue_rebuild() -> void:
	if _dirty or not is_inside_tree() or _body == null:
		return
	_dirty = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_dirty = false
	if _body == null:
		return

	var wall_x := width / 2.0 - wall_thickness / 2.0
	var end_span := maxf(0.1, width - wall_thickness * 2.0)
	var end_z := length / 2.0 - wall_thickness / 2.0

	_body.collision_layer = belt_layer
	_area.collision_mask = detection_mask

	_set_part("belt", Vector3(width, belt_thickness, length), Vector3.ZERO, true, belt_material)

	# Side walls run along Z. Forward is -Z, so a positive offset flips sign.
	_build_wall("left", left_wall_enabled, true, -wall_x, length, -left_gap_offset, left_gap_size)
	_build_wall("right", right_wall_enabled, true, wall_x, length, -right_gap_offset, right_gap_size)
	# End walls run along X.
	_build_wall("front", front_wall_enabled, false, -end_z, end_span, front_gap_offset, front_gap_size)
	_build_wall("back", back_wall_enabled, false, end_z, end_span, back_gap_offset, back_gap_size)

	# Cover the full width so cash entering through a side opening is detected.
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, wall_height + 0.5, length)
	_area_col.shape = shape
	_area_col.position = Vector3(0, belt_thickness / 2.0 + wall_height / 2.0, 0)


## Builds one wall as up to two segments with a gap between them.
func _build_wall(key: String, enabled: bool, along_z: bool, fixed: float, span: float, gap_center: float, gap_size: float) -> void:
	var half := span / 2.0
	var wall_y := belt_thickness / 2.0 + wall_height / 2.0
	var segs: Array[Vector2]

	if gap_size <= 0.0:
		segs = [Vector2(-half, half), Vector2.ZERO]
	else:
		var g0 := gap_center - gap_size / 2.0
		var g1 := gap_center + gap_size / 2.0
		segs = [Vector2(-half, minf(g0, half)), Vector2(maxf(g1, -half), half)]

	for i in 2:
		var s := segs[i]
		var seg_len := s.y - s.x
		var on := enabled and seg_len > 0.01
		var mid := (s.x + s.y) / 2.0
		var size: Vector3
		var pos: Vector3
		if along_z:
			size = Vector3(wall_thickness, wall_height, maxf(seg_len, 0.01))
			pos = Vector3(fixed, wall_y, mid)
		else:
			size = Vector3(maxf(seg_len, 0.01), wall_height, wall_thickness)
			pos = Vector3(mid, wall_y, fixed)
		_set_part(key + ("_a" if i == 0 else "_b"), size, pos, on, wall_material)


func _set_part(part: String, size: Vector3, pos: Vector3, enabled: bool, mat: Material) -> void:
	var mesh_node: MeshInstance3D = _parts[part]["mesh"]
	var col: CollisionShape3D = _parts[part]["col"]

	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.position = pos
	mesh_node.material_override = mat
	mesh_node.visible = enabled

	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	col.disabled = not enabled


func _contains(body: Node3D) -> bool:
	var p := to_local(body.global_position)
	return absf(p.x) <= width / 2.0 + handoff_margin \
		and absf(p.z) <= length / 2.0 + handoff_margin


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _area == null:
		return

	var me := get_instance_id()
	var direction := (global_transform.basis * Vector3.FORWARD).normalized()
	var target := direction * belt_speed

	for body in _area.get_overlapping_bodies():
		if not (body is RigidBody3D):
			continue
		if target_group != "" and not body.is_in_group(target_group):
			continue

		# Only one conveyor drives a body at a time.
		var owner_id: int = body.get_meta(OWNER_META, 0)
		if owner_id != me:
			if not _contains(body):
				continue
			var other := instance_from_id(owner_id) as Conveyor
			if other and other.is_inside_tree() and other._contains(body):
				continue # another conveyor still owns it
			body.set_meta(OWNER_META, me)
		elif not _contains(body):
			body.remove_meta(OWNER_META)
			continue

		var lane_dir := (global_transform.basis * Vector3.RIGHT).normalized()
		var local_x := to_local(body.global_position).x
		var excess := maxf(absf(local_x) - centering_deadzone, 0.0)
		var center_speed := minf(excess * centering_strength, max_centering_speed)
		var wanted := target + lane_dir * (-signf(local_x) * center_speed)

		var current := Vector3(body.linear_velocity.x, 0.0, body.linear_velocity.z)
		var next := current.move_toward(wanted, acceleration * delta)
		body.linear_velocity = Vector3(next.x, body.linear_velocity.y, next.z)
		body.sleeping = false

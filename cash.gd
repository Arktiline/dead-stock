class_name Paper
extends RigidBody3D

enum Side { FRONT, BACK }

signal changed

@export_category("Visuals")
@export var paper_mesh: MeshInstance3D
@export var front_stamp: Node3D  ## icon shown on the front face when stamped
@export var back_stamp: Node3D   ## icon shown on the back face when stamped

var front_stamped := false
var back_stamped := false
var colored := false
var dye_color := Color.SEA_GREEN
var sheets := 1  ## sheets fused into this one

func _ready() -> void:
	add_to_group("printed_cash")
	refresh()

## Which face currently points up (front = local +Y).
func up_side() -> Paper.Side:
	if global_basis.y.dot(Vector3.UP) >= 0.0:
		return Side.FRONT
	return Side.BACK


func is_stamped(side: Paper.Side) -> bool:
	return front_stamped if side == Side.FRONT else back_stamped


func stamp(side: Paper.Side) -> void:
	if side == Side.FRONT:
		front_stamped = true
	else:
		back_stamped = true
	refresh()

func dye(color: Color) -> void:
	colored = true
	dye_color = color
	refresh()


func stamp_count() -> int:
	return int(front_stamped) + int(back_stamped)


## 0..1 score for payouts, buyers, etc. Tweak the weights freely.
func legitimacy() -> float:
	var score := 0.3 * stamp_count()
	score += 0.2 if colored else 0.0
	score += 0.1 * (sheets - 1)
	return clampf(score, 0.0, 1.0)


## Call after changing any state directly.
func refresh() -> void:
	if front_stamp:
		front_stamp.visible = front_stamped
	if back_stamp:
		back_stamp.visible = back_stamped
	if paper_mesh:
		if colored:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = dye_color
			paper_mesh.material_override = mat
		else:
			paper_mesh.material_override = null
	changed.emit()

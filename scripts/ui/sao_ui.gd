extends Object
class_name SaoUi
## Estilos compartidos menú SAO (botones y desplegables).


static func style_flat(bg: Color, border: Color, border_w: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	return sb


static func apply_to_buttons(root: Node) -> void:
	var n := style_flat(Color(0.08, 0.14, 0.22, 0.42), Color(0.35, 0.72, 0.92, 0.35))
	var h := style_flat(Color(0.12, 0.38, 0.58, 0.62), Color(0.45, 0.92, 1.0, 0.95))
	var p := style_flat(Color(0.06, 0.22, 0.38, 0.78), Color(0.25, 0.55, 0.75, 1.0))
	_style_walk(root, n, h, p)


static func _style_walk(node: Node, n: StyleBoxFlat, h: StyleBoxFlat, p: StyleBoxFlat) -> void:
	if node is OptionButton:
		var ob := node as OptionButton
		ob.add_theme_stylebox_override(&"normal", n.duplicate() as StyleBoxFlat)
		ob.add_theme_stylebox_override(&"hover", h.duplicate() as StyleBoxFlat)
		ob.add_theme_stylebox_override(&"pressed", p.duplicate() as StyleBoxFlat)
	elif node is Button:
		var b := node as Button
		b.add_theme_stylebox_override(&"normal", n.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"hover", h.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"pressed", p.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"focus", h.duplicate() as StyleBoxFlat)
	elif node is CheckBox:
		var c := node as CheckBox
		c.add_theme_stylebox_override(&"normal", n.duplicate() as StyleBoxFlat)
		c.add_theme_stylebox_override(&"hover", h.duplicate() as StyleBoxFlat)
		c.add_theme_stylebox_override(&"pressed", p.duplicate() as StyleBoxFlat)
	for c in node.get_children():
		_style_walk(c, n, h, p)

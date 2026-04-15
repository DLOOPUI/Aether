extends Object
class_name SaoUi
## Estilos compartidos menú SAO (botones, desplegables, sliders).

## Texturas del grabber/tick (Slider usa iconos, no StyleBox).
static var _tex_grabber: ImageTexture
static var _tex_grabber_hi: ImageTexture
static var _tex_grabber_dis: ImageTexture
static var _tex_tick: ImageTexture


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


## Riel del slider (fondo completo de la pista).
static func style_slider_track(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


## Zona rellena a la izquierda / abajo del grabber.
static func style_slider_fill(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


static func apply_to_buttons(root: Node) -> void:
	var n := style_flat(Color(0.08, 0.14, 0.22, 0.42), Color(0.35, 0.72, 0.92, 0.35))
	var h := style_flat(Color(0.12, 0.38, 0.58, 0.62), Color(0.45, 0.92, 1.0, 0.95))
	var p := style_flat(Color(0.06, 0.22, 0.38, 0.78), Color(0.25, 0.55, 0.75, 1.0))
	var track := style_slider_track(Color(0.05, 0.11, 0.2, 0.92), Color(0.28, 0.62, 0.88, 0.38))
	var fill := style_slider_fill(Color(0.08, 0.32, 0.52, 0.68), Color(0.35, 0.78, 0.98, 0.5))
	var fill_hi := style_slider_fill(Color(0.12, 0.45, 0.68, 0.78), Color(0.45, 0.92, 1.0, 0.65))
	_ensure_slider_icons()
	_style_walk(root, n, h, p, track, fill, fill_hi)


static func _ensure_slider_icons() -> void:
	if _tex_grabber != null:
		return
	_tex_grabber = _make_grabber_texture(Color(0.18, 0.72, 0.98, 1.0), Color(0.45, 0.95, 1.0, 1.0))
	_tex_grabber_hi = _make_grabber_texture(Color(0.28, 0.82, 1.0, 1.0), Color(0.55, 1.0, 1.0, 1.0))
	_tex_grabber_dis = _make_grabber_texture(Color(0.12, 0.22, 0.34, 0.78), Color(0.35, 0.48, 0.58, 0.7))
	_tex_tick = _make_tick_texture(Color(0.45, 0.85, 0.98, 0.9))


static func _make_grabber_texture(fill: Color, edge: Color) -> ImageTexture:
	const GW := 15
	const GH := 20
	var img := Image.create(GW, GH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in GW:
		for y in GH:
			var c := fill
			if x == 0 or x == GW - 1 or y == 0 or y == GH - 1:
				c = edge
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _make_tick_texture(c: Color) -> ImageTexture:
	const TW := 3
	const TH := 10
	var img := Image.create(TW, TH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in TW:
		for y in TH:
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _style_walk(
	node: Node,
	n: StyleBoxFlat,
	h: StyleBoxFlat,
	p: StyleBoxFlat,
	track: StyleBoxFlat,
	fill: StyleBoxFlat,
	fill_hi: StyleBoxFlat,
) -> void:
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
	elif node is Slider:
		var s := node as Slider
		s.add_theme_stylebox_override(&"slider", track.duplicate() as StyleBoxFlat)
		s.add_theme_stylebox_override(&"grabber_area", fill.duplicate() as StyleBoxFlat)
		s.add_theme_stylebox_override(&"grabber_area_highlight", fill_hi.duplicate() as StyleBoxFlat)
		s.add_theme_icon_override(&"grabber", _tex_grabber)
		s.add_theme_icon_override(&"grabber_highlight", _tex_grabber_hi)
		s.add_theme_icon_override(&"grabber_disabled", _tex_grabber_dis)
		s.add_theme_icon_override(&"tick", _tex_tick)
	for c in node.get_children():
		_style_walk(c, n, h, p, track, fill, fill_hi)

class_name ArenaRenderer
extends RefCounted
## Procedural 16-bit-style pixel art: 32x32 px cells, dark outlines, 3-tone shading.
## Decoration never affects collision. Static art is drawn once into a cached layer.

const CELL := 32
const OUT := Color("2b1a10")

static func _h(x: int, y: int, salt: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791))

static func _r(ci: CanvasItem, o: Vector2, x: float, y: float, w: float, h: float, c: Color) -> void:
	ci.draw_rect(Rect2(o.x + x, o.y + y, w, h), c)

## Rectangle with chamfered (pixel-rounded) corners.
static func _rr(ci: CanvasItem, o: Vector2, x0: float, y0: float, x1: float, y1: float, c: Color, n: float = 2.0) -> void:
	_r(ci, o, x0, y0 + n, x1 - x0, y1 - y0 - n * 2.0, c)
	_r(ci, o, x0 + n, y0, x1 - x0 - n * 2.0, y1 - y0, c)

static func _poly(ci: CanvasItem, o: Vector2, pts: Array, c: Color, center: Vector2 = Vector2.ZERO, grow: float = 1.0) -> void:
	var v := PackedVector2Array()
	for p in pts:
		v.append(o + center + (Vector2(p) - center) * grow)
	ci.draw_colored_polygon(v, c)

static func _shadow(ci: CanvasItem, o: Vector2, cx: float, cy: float, rx: float, ry: float) -> void:
	var v := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		v.append(o + Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	ci.draw_colored_polygon(v, Color(0, 0, 0, 0.22))

# --------------------------------------------------------------------------- arena

static func draw_arena(ci: CanvasItem, arena: Dictionary, board: GridBoard, origin: Vector2, scale: float = 1.0) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2(scale, scale))
	var col: Dictionary = arena["colors"]
	var theme: String = arena["theme"]
	for y in board.rows:
		for x in board.cols:
			_ground(ci, theme, col, x, y)
	_border(ci, theme, col, board)
	var styles: Dictionary = arena["obstacle_styles"]
	for y in board.rows:
		for x in board.cols:
			var c := Vector2i(x, y)
			if board.obstacles.has(c):
				var style: String = styles[board.obstacles[c]]
				var nb := {
					"L": _same(board, styles, c + Vector2i.LEFT, style), "R": _same(board, styles, c + Vector2i.RIGHT, style),
					"U": _same(board, styles, c + Vector2i.UP, style), "D": _same(board, styles, c + Vector2i.DOWN, style),
				}
				_obstacle(ci, style, c, nb)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _same(board: GridBoard, styles: Dictionary, c: Vector2i, style: String) -> bool:
	return board.obstacles.has(c) and styles[board.obstacles[c]] == style

static func _ground(ci: CanvasItem, theme: String, col: Dictionary, x: int, y: int) -> void:
	var o := Vector2(x * CELL, y * CELL)
	var a := Color(col["bg_a"])
	var b := Color(col["bg_b"])
	var base := a if (x + y) % 2 == 0 else b
	match theme:
		"backyard": _grass(ci, o, base, x, y, true)
		"garden":
			if y == 5 or x == 10:
				_cobble(ci, o, Color(col["path_b"]), Color(col["path"]), x, y)
			else:
				_grass(ci, o, base, x, y, true)
		"living_room":
			if x >= 6 and x <= 13 and y >= 2 and y <= 7:
				_rug(ci, o, col, x, y)
			else:
				_planks(ci, o, a, b, x, y)
		"snowy_yard": _snow(ci, o, base, x, y)

static func _grass(ci: CanvasItem, o: Vector2, base: Color, x: int, y: int, flowers: bool) -> void:
	_r(ci, o, 0, 0, 32, 32, base)
	_r(ci, o, 0, 0, 32, 2, base.lightened(0.05))
	for i in 5:
		var hh := _h(x * 5 + i, y * 7 + i, 7)
		var px := float(hh % 26 + 2)
		var py := float((hh / 7) % 22 + 6)
		_r(ci, o, px, py, 2, 6, base.darkened(0.22))
		_r(ci, o, px + 2, py + 2, 2, 4, base.darkened(0.12))
		_r(ci, o, px - 2, py + 3, 2, 3, base.lightened(0.18))
		_r(ci, o, px, py - 1, 1, 2, base.lightened(0.25))
	var h := _h(x, y, 3)
	if flowers and h % 6 == 0:
		var p := o + Vector2(6 + h % 18, 6 + (h / 5) % 18)
		var petal: Color = [Color("ff8fb8"), Color("fff27a"), Color("ffffff"), Color("c9a0ff")][h % 4]
		_r(ci, p, 2, 0, 3, 3, petal)
		_r(ci, p, 2, 4, 3, 3, petal)
		_r(ci, p, 0, 2, 3, 3, petal)
		_r(ci, p, 4, 2, 3, 3, petal)
		_r(ci, p, 2, 2, 3, 3, Color("ffb52e"))
		_r(ci, p, 3, 7, 1, 5, base.darkened(0.3))

static func _planks(ci: CanvasItem, o: Vector2, a: Color, b: Color, x: int, y: int) -> void:
	for k in 2:
		var hh := _h(x, y * 2 + k, 11)
		var c := (a if hh % 2 == 0 else b).lightened(float(hh % 5) * 0.012)
		var py := float(k * 16)
		_r(ci, o, 0, py, 32, 16, c)
		_r(ci, o, 0, py, 32, 1, c.lightened(0.14))
		_r(ci, o, 0, py + 14, 32, 2, c.darkened(0.25))
		var seam := float((hh / 3) % 28 + 2)
		_r(ci, o, seam, py, 2, 16, c.darkened(0.3))
		_r(ci, o, seam + 2, py, 1, 14, c.lightened(0.08))
		_r(ci, o, float((hh / 5) % 12 + 3), py + 5, 10, 1, c.darkened(0.1))
		_r(ci, o, float((hh / 9) % 10 + 12), py + 9, 8, 1, c.lightened(0.08))

static func _rug(ci: CanvasItem, o: Vector2, col: Dictionary, x: int, y: int) -> void:
	var c1 := Color(col["carpet"])
	var c2 := Color(col["carpet_b"])
	_r(ci, o, 0, 0, 32, 32, c1)
	_poly(ci, o, [Vector2(16, 3), Vector2(29, 16), Vector2(16, 29), Vector2(3, 16)], c2)
	_poly(ci, o, [Vector2(16, 9), Vector2(23, 16), Vector2(16, 23), Vector2(9, 16)], c1.darkened(0.12))
	_r(ci, o, 15, 15, 2, 2, Color("ffd166"))
	var trim := Color("e8c26a")
	if x == 6: _r(ci, o, 0, 0, 3, 32, trim); _r(ci, o, 3, 0, 1, 32, c1.darkened(0.3))
	if x == 13: _r(ci, o, 29, 0, 3, 32, trim); _r(ci, o, 28, 0, 1, 32, c1.darkened(0.3))
	if y == 2: _r(ci, o, 0, 0, 32, 3, trim); _r(ci, o, 0, 3, 32, 1, c1.darkened(0.3))
	if y == 7: _r(ci, o, 0, 29, 32, 3, trim); _r(ci, o, 0, 28, 32, 1, c1.darkened(0.3))

static func _cobble(ci: CanvasItem, o: Vector2, mortar: Color, stone: Color, x: int, y: int) -> void:
	_r(ci, o, 0, 0, 32, 32, mortar.darkened(0.15))
	for sy in 2:
		for sx in 2:
			var hh := _h(x * 2 + sx, y * 2 + sy, 5)
			var px := float(sx * 16 + hh % 3)
			var py := float(sy * 16 + (hh / 3) % 3)
			var c := stone.darkened(float(hh % 4) * 0.03)
			_rr(ci, o, px + 1, py + 1, px + 15, py + 15, c, 3)
			_r(ci, o, px + 4, py + 2, 8, 2, c.lightened(0.22))
			_r(ci, o, px + 3, py + 12, 10, 2, c.darkened(0.15))

static func _snow(ci: CanvasItem, o: Vector2, base: Color, x: int, y: int) -> void:
	_r(ci, o, 0, 0, 32, 32, base)
	var h := _h(x, y, 9)
	_r(ci, o, float(h % 10), float(18 + (h / 3) % 8), float(10 + h % 12), 2, Color(0.62, 0.78, 0.92, 0.28))
	_r(ci, o, float(4 + (h / 7) % 14), float(6 + (h / 5) % 8), float(6 + h % 8), 2, Color(1, 1, 1, 0.7))
	if h % 11 == 0:
		_rr(ci, o, 6, 8, 26, 24, Color("bfe6f5"), 4)
		_r(ci, o, 10, 12, 8, 2, Color("ffffff"))
		_r(ci, o, 14, 17, 7, 1, Color("ffffff"))
	for i in 3:
		var hh := _h(x * 3 + i, y * 5 + i, 4)
		if hh % 3 == 0:
			var p := o + Vector2(hh % 28 + 2, (hh / 5) % 28 + 2)
			_r(ci, p, 0, 1, 3, 1, Color.WHITE)
			_r(ci, p, 1, 0, 1, 3, Color.WHITE)

static func _border(ci: CanvasItem, theme: String, col: Dictionary, board: GridBoard) -> void:
	var w := float(board.cols * CELL)
	var h := float(board.rows * CELL)
	var c := Color(col["border"])
	var t := 8.0
	var lt := c.lightened(0.28)
	var dk := c.darkened(0.35)
	var z := Vector2.ZERO
	for rect in [Rect2(0, 0, w, t), Rect2(0, h - t, w, t), Rect2(0, 0, t, h), Rect2(w - t, 0, t, h)]:
		ci.draw_rect(rect, c)
	match theme:
		"garden":
			for i in range(0, int(w), 16):
				var off := float((i / 16) % 2) * 8.0
				_r(ci, z, i, 0, 1, t, dk); _r(ci, z, i, h - t, 1, t, dk)
			_r(ci, z, 0, t / 2, w, 1, dk); _r(ci, z, 0, h - t / 2, w, 1, dk)
		"living_room":
			_r(ci, z, 0, 0, w, 2, lt); _r(ci, z, 0, t - 2, w, 2, dk)
			_r(ci, z, 0, h - t, w, 2, lt); _r(ci, z, 0, h - 2, w, 2, dk)
		_:
			for i in range(0, int(w), 8):
				_r(ci, z, i, 0, 1, t, dk); _r(ci, z, i + 1, 0, 1, t, lt)
				_r(ci, z, i, h - t, 1, t, dk); _r(ci, z, i + 1, h - t, 1, t, lt)
			for j in range(0, int(h), 8):
				_r(ci, z, 0, j, t, 1, dk); _r(ci, z, w - t, j, t, 1, dk)
			if theme == "snowy_yard":
				_r(ci, z, 0, 0, w, 3, Color.WHITE); _r(ci, z, 0, h - t, w, 3, Color.WHITE)
	_r(ci, z, 0, t, w, 1, Color(0, 0, 0, 0.25))
	_r(ci, z, t, 0, 1, h, Color(0, 0, 0, 0.18))

# ------------------------------------------------------------------------ obstacles

static func _block(ci: CanvasItem, o: Vector2, nb: Dictionary, inset: float, main: Color, light: Color, dark: Color, outline: Color) -> Rect2:
	var x0 := 0.0 if nb["L"] else inset
	var x1 := 32.0 if nb["R"] else 32.0 - inset
	var y0 := 0.0 if nb["U"] else inset
	var y1 := 32.0 if nb["D"] else 32.0 - inset
	_r(ci, o, x0 - (0.0 if nb["L"] else 2.0), y0 - (0.0 if nb["U"] else 2.0), (x1 - x0) + (0.0 if nb["L"] else 2.0) + (0.0 if nb["R"] else 2.0), (y1 - y0) + (0.0 if nb["U"] else 2.0) + (0.0 if nb["D"] else 2.0), outline)
	_r(ci, o, x0, y0, x1 - x0, y1 - y0, main)
	if not nb["U"]:
		_r(ci, o, x0, y0, x1 - x0, 3, light)
	if not nb["D"]:
		_r(ci, o, x0, y1 - 4, x1 - x0, 4, dark)
	if not nb["L"]:
		_r(ci, o, x0, y0, 2, y1 - y0, light)
	if not nb["R"]:
		_r(ci, o, x1 - 3, y0, 3, y1 - y0, dark)
	return Rect2(x0, y0, x1 - x0, y1 - y0)

static func _obstacle(ci: CanvasItem, style: String, cell: Vector2i, nb: Dictionary) -> void:
	var o := Vector2(cell.x * CELL, cell.y * CELL)
	var hh := _h(cell.x, cell.y, 13)
	match style:
		"rock":
			_shadow(ci, o, 16, 28, 13, 4)
			var pts := [Vector2(4, 26), Vector2(2, 17), Vector2(7, 8), Vector2(16, 4), Vector2(25, 7), Vector2(30, 16), Vector2(28, 26), Vector2(16, 29)]
			_poly(ci, o, pts, Color("2e2e3a"), Vector2(16, 17), 1.1)
			_poly(ci, o, pts, Color("8c8c9e"), Vector2(16, 17), 0.94)
			_poly(ci, o, [Vector2(8, 11), Vector2(16, 6), Vector2(25, 9), Vector2(22, 14), Vector2(11, 15)], Color("b6b6ca"))
			_poly(ci, o, [Vector2(5, 23), Vector2(28, 23), Vector2(26, 27), Vector2(8, 28)], Color("66667a"))
			_r(ci, o, 13, 16, 1, 5, Color("55556a")); _r(ci, o, 14, 20, 4, 1, Color("55556a"))
			_r(ci, o, 7, 22, 5, 2, Color("5aa83a")); _r(ci, o, 9, 21, 3, 1, Color("7fcb55"))
		"hedge":
			var r := _block(ci, o, nb, 1.0, Color("2f8c3f"), Color("62c856"), Color("1c5c2a"), Color("123d1c"))
			for i in 7:
				var q := _h(cell.x * 7 + i, cell.y * 3 + i, 17)
				var px := r.position.x + 3 + float(q % int(maxf(r.size.x - 8, 4)))
				var py := r.position.y + 5 + float((q / 7) % int(maxf(r.size.y - 14, 4)))
				ci.draw_circle(o + Vector2(px, py), 3.0, Color("49ad4d"))
				_r(ci, o, px - 2, py - 2, 3, 2, Color("7ee06a"))
				_r(ci, o, px, py + 2, 4, 1, Color("1f6a2c"))
			_r(ci, o, r.position.x + 1, r.position.y + r.size.y - 2, r.size.x - 2, 4, Color("3d2a1a"))
		"snow_tree", "tree":
			var snow := style == "snow_tree"
			_shadow(ci, o, 16, 30, 12, 3)
			_r(ci, o, 13, 24, 6, 7, Color("5a3a1e")); _r(ci, o, 13, 24, 2, 7, Color("7a5230"))
			var green := Color("1f6a52") if snow else Color("2f8c3f")
			var green_l := Color("2f8f6e") if snow else Color("49ad4d")
			for tier in [[Vector2(16, 13), Vector2(31, 29), Vector2(1, 29)], [Vector2(16, 7), Vector2(28, 22), Vector2(4, 22)], [Vector2(16, 1), Vector2(25, 14), Vector2(7, 14)]]:
				_poly(ci, o, tier, Color("0f2e26") if snow else Color("123d1c"), Vector2(16, 18), 1.12)
				_poly(ci, o, tier, green)
				_poly(ci, o, [tier[0], tier[0] + Vector2(-4, 8), tier[0] + Vector2(1, 9)], green_l)
				if snow:
					var a: Vector2 = tier[0]
					_poly(ci, o, [a, a + Vector2(7, 9), a + Vector2(3, 8), a + Vector2(0, 11), a + Vector2(-3, 8), a + Vector2(-7, 9)], Color("f3faff"))
					_r(ci, o, a.x - 2, a.y + 3, 3, 2, Color("ffffff"))
		"sofa":
			var l: bool = nb["L"]
			var r: bool = nb["R"]
			var x0 := 0.0 if l else 1.0
			var x1 := 32.0 if r else 31.0
			_r(ci, o, 3, 29, 4, 3, Color("2a1a10")); _r(ci, o, 25, 29, 4, 3, Color("2a1a10"))
			_r(ci, o, x0, 2, x1 - x0, 28, Color("26300a"))                       # outline
			_r(ci, o, x0 + (0.0 if l else 2.0), 4, (x1 - x0) - (0.0 if l else 2.0) - (0.0 if r else 2.0), 12, Color("4e6a14"))   # backrest
			_r(ci, o, x0 + (0.0 if l else 2.0), 4, (x1 - x0) - (0.0 if l else 2.0) - (0.0 if r else 2.0), 2, Color("7a9a26"))
			_r(ci, o, x0 + (0.0 if l else 8.0), 16, (x1 - x0) - (0.0 if l else 8.0) - (0.0 if r else 8.0), 11, Color("6f8f1f"))  # seat
			_r(ci, o, x0 + (0.0 if l else 8.0), 16, (x1 - x0) - (0.0 if l else 8.0) - (0.0 if r else 8.0), 2, Color("a0c43c"))
			_r(ci, o, x0 + (0.0 if l else 8.0), 25, (x1 - x0) - (0.0 if l else 8.0) - (0.0 if r else 8.0), 2, Color("46600f"))
			_r(ci, o, 14, 8, 3, 3, Color("2a350c"))                              # tufting button
			if r:
				_r(ci, o, 31, 4, 1, 22, Color("26300a"))
			if not l:
				_r(ci, o, 1, 8, 8, 21, Color("26300a")); _r(ci, o, 2, 9, 6, 18, Color("86a52b")); _r(ci, o, 2, 9, 6, 2, Color("b4d84c"))
			if not r:
				_r(ci, o, 23, 8, 8, 21, Color("26300a")); _r(ci, o, 24, 9, 6, 18, Color("86a52b")); _r(ci, o, 24, 9, 6, 2, Color("b4d84c"))
		"table":
			var r := _block(ci, o, nb, 3.0, Color("c88a4f"), Color("e8b274"), Color("8a5a2a"), Color("4a2a12"))
			_r(ci, o, r.position.x + 4, r.position.y + 6, r.size.x - 8, 1, Color("a8703a"))
			_r(ci, o, r.position.x + 6, r.position.y + 14, r.size.x - 12, 1, Color("d9a15f"))
			if not nb["L"] and not nb["U"]:
				_r(ci, o, 8, 8, 4, 4, Color("fff4d6"))  # candle
				_r(ci, o, 9, 4, 2, 4, Color("ffd24a"))
		"pond":
			var r := _block(ci, o, nb, 1.0, Color("3f9ad8"), Color("8fd6ff"), Color("2a6fb0"), Color("5a5048"))
			for i in 3:
				var q := _h(cell.x * 3 + i, cell.y * 5 + i, 21)
				_r(ci, o, r.position.x + 4 + float(q % 18), r.position.y + 6 + float((q / 5) % 18), 8, 1, Color("bfe9ff"))
			if hh % 3 == 0:
				ci.draw_circle(o + Vector2(20, 20), 5.0, Color("2f8c3f")); ci.draw_circle(o + Vector2(19, 19), 3.0, Color("49ad4d"))
				_r(ci, o, 22, 14, 3, 3, Color("ffb3d1"))
		"snowman":
			_shadow(ci, o, 16, 30, 11, 3)
			ci.draw_circle(o + Vector2(16, 22), 10.0, Color("5a7a96")); ci.draw_circle(o + Vector2(16, 22), 8.6, Color.WHITE); ci.draw_circle(o + Vector2(19, 25), 5.0, Color("dcecf7"))
			ci.draw_circle(o + Vector2(16, 11), 7.5, Color("5a7a96")); ci.draw_circle(o + Vector2(16, 11), 6.2, Color.WHITE); ci.draw_circle(o + Vector2(18, 13), 3.5, Color("dcecf7"))
			_r(ci, o, 9, 2, 14, 3, Color("2a2a38")); _r(ci, o, 12, -3, 8, 6, Color("2a2a38")); _r(ci, o, 12, 1, 8, 1, Color("e2506b"))
			_r(ci, o, 12, 9, 2, 2, Color("1a1a24")); _r(ci, o, 18, 9, 2, 2, Color("1a1a24"))
			_poly(ci, o, [Vector2(16, 11), Vector2(25, 13), Vector2(16, 14)], Color("f2994a"))
			_r(ci, o, 8, 15, 16, 3, Color("e2506b")); _r(ci, o, 20, 17, 3, 7, Color("c2384f"))
			_r(ci, o, 15, 21, 2, 2, Color("1a1a24")); _r(ci, o, 15, 26, 2, 2, Color("1a1a24"))
			ci.draw_line(o + Vector2(7, 20), o + Vector2(0, 14), Color("5a3a1e"), 2.0); ci.draw_line(o + Vector2(25, 20), o + Vector2(32, 14), Color("5a3a1e"), 2.0)

# ---------------------------------------------------------------------------- items

const F_OUT := Color("1a3b6e")
const F_BODY := Color("4aa8ff")
const F_BELLY := Color("c3e6ff")
const F_DARK := Color("2a6fc0")
const G_OUT := Color("7a4a00")
const G_BODY := Color("ffd23f")
const G_BELLY := Color("fff3a8")
const G_DARK := Color("e0a000")

static func _fish(ci: CanvasItem, c: Vector2, body: Color, belly: Color, dark: Color, out: Color) -> void:
	var pts := [Vector2(-11, 0), Vector2(-6, -6), Vector2(2, -7), Vector2(9, -3), Vector2(11, 0), Vector2(9, 3), Vector2(2, 7), Vector2(-6, 6)]
	_poly(ci, c, [Vector2(10, 0), Vector2(17, -8), Vector2(15, 0), Vector2(17, 8)], out, Vector2(13, 0), 1.25)
	_poly(ci, c, [Vector2(10, 0), Vector2(17, -8), Vector2(15, 0), Vector2(17, 8)], dark, Vector2.ZERO)
	_poly(ci, c, [Vector2(-2, -7), Vector2(3, -12), Vector2(7, -4)], out, Vector2(2, -7), 1.3)
	_poly(ci, c, [Vector2(-2, -7), Vector2(3, -12), Vector2(7, -4)], dark, Vector2.ZERO)
	_poly(ci, c, pts, out, Vector2.ZERO, 1.2)
	_poly(ci, c, pts, body)
	_poly(ci, c, [Vector2(-10, 1), Vector2(10, 1), Vector2(8, 3), Vector2(2, 6), Vector2(-6, 5)], belly)
	_r(ci, c, -6, -5, 5, 2, body.lightened(0.3))
	_r(ci, c, -1, -5, 2, 9, dark); _r(ci, c, 4, -4, 2, 7, dark)
	ci.draw_circle(c + Vector2(-7, -1), 2.6, Color.WHITE); ci.draw_circle(c + Vector2(-7.5, -1), 1.5, Color("10101a"))
	ci.draw_arc(c + Vector2(-3, 0), 5.0, -0.9, 0.9, 6, out, 1.0)

static func draw_item(ci: CanvasItem, id: String, center: Vector2, t: float, animate: bool) -> void:
	var c := center + Vector2(0, sin(t * 4.0) * 1.6 if animate else 0.0)
	_shadow(ci, Vector2.ZERO, center.x, center.y + 13, 9, 3)
	match id:
		"fish":
			_fish(ci, c, F_BODY, F_BELLY, F_DARK, F_OUT)
		"golden":
			ci.draw_circle(c, 17.0 + (sin(t * 5.0) * 1.5 if animate else 0.0), Color(1, 0.85, 0.2, 0.2))
			_fish(ci, c, G_BODY, G_BELLY, G_DARK, G_OUT)
			if fmod(t * 2.5, 1.0) < 0.5:
				_r(ci, c, -10, -14, 2, 7, Color.WHITE); _r(ci, c, -12, -12, 6, 2, Color.WHITE)
			if fmod(t * 2.5 + 0.5, 1.0) < 0.5:
				_r(ci, c, 10, 6, 2, 5, Color.WHITE); _r(ci, c, 8, 8, 6, 2, Color.WHITE)
		"milk":
			_rr(ci, c, -9, -8, 9, 14, Color("20406e"), 2)
			_poly(ci, c, [Vector2(-9, -7), Vector2(9, -7), Vector2(6, -15), Vector2(-6, -15)], Color("20406e"), Vector2(0, -11), 1.1)
			_poly(ci, c, [Vector2(-8, -7), Vector2(8, -7), Vector2(5, -14), Vector2(-5, -14)], Color("78b9ff"))
			_r(ci, c, -3, -14, 6, 2, Color("b9deff"))
			_r(ci, c, -8, -7, 16, 14, Color.WHITE)
			_r(ci, c, 4, -7, 4, 14, Color("d4e2f2"))
			_r(ci, c, -8, 5, 16, 2, Color("b8c8dc"))
			_rr(ci, c, -6, -3, 6, 4, Color("4a9aef"), 1)
			_poly(ci, c, [Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)], Color.WHITE)
		"yarn":
			ci.draw_circle(c, 13.0, Color("7a1d4a")); ci.draw_circle(c, 11.5, Color("ff5fa2"))
			ci.draw_circle(c + Vector2(-3, -3), 5.0, Color("ff8cc0"))
			ci.draw_arc(c, 8.0, 0.2, 2.6, 10, Color("c2417a"), 2.0); ci.draw_arc(c, 6.0, 2.8, 5.8, 10, Color("ffb8d8"), 2.0)
			ci.draw_arc(c, 9.0, 3.6, 5.6, 10, Color("a02c64"), 2.0); ci.draw_arc(c, 4.0, 0.0, 3.4, 8, Color("c2417a"), 2.0)
			ci.draw_polyline(PackedVector2Array([c + Vector2(9, 7), c + Vector2(14, 11), c + Vector2(19, 9), c + Vector2(22, 13)]), Color("7a1d4a"), 4.0)
			ci.draw_polyline(PackedVector2Array([c + Vector2(9, 7), c + Vector2(14, 11), c + Vector2(19, 9), c + Vector2(22, 13)]), Color("ff5fa2"), 2.0)
			_r(ci, c, -7, -8, 4, 2, Color("ffe1ee"))
		"scissors":
			for s in [-1, 1]:
				ci.draw_line(c + Vector2(-9 * s, 10), c + Vector2(9 * s, -12), Color("2a3238"), 6.0)
				ci.draw_line(c + Vector2(-9 * s, 10), c + Vector2(9 * s, -12), Color("dbe4e9"), 3.0)
				ci.draw_circle(c + Vector2(-8 * s, 11), 5.0, Color("7a1d2a")); ci.draw_circle(c + Vector2(-8 * s, 11), 3.0, Color("2b1a10"))
				ci.draw_arc(c + Vector2(-8 * s, 11), 4.0, 0.0, TAU, 12, Color("e2506b"), 2.0)
			ci.draw_circle(c, 2.0, Color("7a8890"))

# ---------------------------------------------------------------------------- kitten

const K_OUT := Color("3b2210")
const K_ORG := Color("f59a32")
const K_LIT := Color("ffc067")
const K_DRK := Color("d9741a")
const K_PINK := Color("ff9db8")

## Orange tabby kitten head: white muzzle, big shiny eyes, pink nose, striped forehead.
static func draw_kitten(ci: CanvasItem, center: Vector2, dir: Vector2i, t: float, dead: bool, animate: bool) -> void:
	var o := center + Vector2(0, sin(t * 6.0) * 0.8 if animate and not dead else 0.0)
	var f := Vector2(dir) * 2.5
	# ears
	for s in [-1, 1]:
		var ear := [Vector2(13 * s, -8), Vector2(12 * s, -20), Vector2(3 * s, -11)]
		_poly(ci, o, ear, K_OUT, Vector2(9 * s, -13), 1.35)
		_poly(ci, o, ear, K_ORG)
		_poly(ci, o, [Vector2(11 * s, -9), Vector2(11 * s, -16), Vector2(5 * s, -11)], K_PINK)
	# head
	_rr(ci, o, -17, -13, 17, 15, K_OUT, 4)
	_rr(ci, o, -15, -11, 15, 13, K_ORG, 3)
	_r(ci, o, -11, -11, 22, 3, K_LIT)
	_r(ci, o, -15, 8, 30, 3, K_DRK)
	for s in [-1, 1]:  # cheek tufts
		_poly(ci, o, [Vector2(14 * s, 3), Vector2(19 * s, 8), Vector2(12 * s, 11)], K_OUT)
		_poly(ci, o, [Vector2(14 * s, 4), Vector2(17 * s, 8), Vector2(12 * s, 10)], Color("ffe0b8"))
	_r(ci, o, -2, -11, 4, 7, K_DRK); _r(ci, o, -8, -11, 3, 5, K_DRK); _r(ci, o, 5, -11, 3, 5, K_DRK)
	# muzzle
	_rr(ci, o + f * 0.6, -8, 3, 8, 12, Color.WHITE, 3)
	_r(ci, o + f * 0.6, -8, 9, 16, 3, Color("e8e0d8"))
	# eyes
	if dead:
		for ex in [-9.0, 4.0]:
			ci.draw_line(o + f + Vector2(ex, -4), o + f + Vector2(ex + 5, 2), K_OUT, 2.0)
			ci.draw_line(o + f + Vector2(ex + 5, -4), o + f + Vector2(ex, 2), K_OUT, 2.0)
	else:
		var blink := fmod(t, 3.4) > 3.25
		for ex in [-9.0, 4.0]:
			if blink:
				_r(ci, o + f, ex, -1, 6, 2, K_OUT)
			else:
				_rr(ci, o + f, ex, -5, ex + 6, 5, Color("120c1a"), 2)
				_r(ci, o + f, ex + 1, -4, 3, 3, Color.WHITE)
				_r(ci, o + f, ex + 4, 2, 1, 1, Color("bfd8ff"))
	# nose + mouth
	_r(ci, o + f, -2, 4, 4, 3, K_PINK); _r(ci, o + f, -1, 4, 2, 1, Color("ffd0dd"))
	_r(ci, o + f * 0.8, -1, 7, 2, 1, K_OUT)
	_r(ci, o + f * 0.8, -4, 8, 3, 1, K_OUT); _r(ci, o + f * 0.8, 1, 8, 3, 1, K_OUT)
	for s in [-1, 1]:  # whiskers
		ci.draw_line(o + Vector2(15 * s, 4), o + Vector2(24 * s, 2), K_OUT, 1.0)
		ci.draw_line(o + Vector2(15 * s, 7), o + Vector2(24 * s, 8), K_OUT, 1.0)

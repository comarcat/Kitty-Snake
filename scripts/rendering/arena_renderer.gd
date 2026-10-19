class_name ArenaRenderer
extends RefCounted
## Procedural placeholder pixel art for arenas, obstacles, items and the kitten.
## All drawing uses 16x16 logical-pixel cells. Decoration never affects collision.

const CELL := 16

static func _h(x: int, y: int, salt: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791))

static func draw_arena(ci: CanvasItem, arena: Dictionary, board: GridBoard, origin: Vector2, scale: float = 1.0) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2(scale, scale))
	var col: Dictionary = arena["colors"]
	var theme: String = arena["theme"]
	var a := Color(col["bg_a"])
	var b := Color(col["bg_b"])
	for y in board.rows:
		for x in board.cols:
			var base := a if (x + y) % 2 == 0 else b
			base = _floor_color(theme, col, x, y, base)
			ci.draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), base)
			_decor(ci, theme, col, x, y)
	_border(ci, theme, col, board)
	var styles: Dictionary = arena["obstacle_styles"]
	for cell in board.obstacles:
		_obstacle(ci, styles[board.obstacles[cell]], cell)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _floor_color(theme: String, col: Dictionary, x: int, y: int, base: Color) -> Color:
	match theme:
		"living_room":
			if x >= 6 and x <= 13 and y >= 2 and y <= 7:
				return Color(col["carpet"]) if (x + y) % 2 == 0 else Color(col["carpet_b"])
		"garden":
			if y == 5 or x == 10:
				return Color(col["path"]) if (x + y) % 2 == 0 else Color(col["path_b"])
	return base

static func _decor(ci: CanvasItem, theme: String, col: Dictionary, x: int, y: int) -> void:
	var o := Vector2(x * CELL, y * CELL)
	var h := _h(x, y, 3)
	match theme:
		"backyard":
			ci.draw_rect(Rect2(o + Vector2(3 + h % 9, 4 + (h / 7) % 8), Vector2(1, 2)), Color("5aa83a"))
			if h % 6 == 0:
				var p := o + Vector2(2 + (h / 3) % 11, 2 + (h / 11) % 11)
				ci.draw_rect(Rect2(p, Vector2(2, 2)), Color(col["decor"]))
				ci.draw_rect(Rect2(p + Vector2(0.5, 0.5), Vector2(1, 1)), Color(col["accent"]))
		"living_room":
			ci.draw_rect(Rect2(o + Vector2(0, 15), Vector2(16, 1)), Color(col["decor"]))
			ci.draw_rect(Rect2(o + Vector2(((y % 2) * 8 + 4) % 16, 0), Vector2(1, 15)), Color(col["decor"]))
		"garden":
			if h % 5 == 0 and y != 5 and x != 10:
				var p := o + Vector2(3 + h % 9, 3 + (h / 5) % 9)
				ci.draw_rect(Rect2(p, Vector2(2, 2)), Color(col["decor"]))
				ci.draw_rect(Rect2(p + Vector2(0, 2), Vector2(1, 2)), Color("3d7a34"))
		"snowy_yard":
			if h % 4 == 0:
				ci.draw_rect(Rect2(o + Vector2(2 + h % 12, 2 + (h / 4) % 12), Vector2(1, 1)), Color.WHITE)
			if h % 9 == 0:
				ci.draw_rect(Rect2(o + Vector2(4 + h % 8, 8), Vector2(3, 1)), Color("c4d9e8"))

static func _border(ci: CanvasItem, theme: String, col: Dictionary, board: GridBoard) -> void:
	var w := board.cols * CELL
	var h := board.rows * CELL
	var c := Color(col["border"])
	var lt := c.lightened(0.3)
	ci.draw_rect(Rect2(0, 0, w, 2), c)
	ci.draw_rect(Rect2(0, h - 2, w, 2), c)
	ci.draw_rect(Rect2(0, 0, 2, h), c)
	ci.draw_rect(Rect2(w - 2, 0, 2, h), c)
	ci.draw_rect(Rect2(0, 2, w, 1), lt)
	ci.draw_rect(Rect2(2, 0, 1, h), lt)
	if theme == "backyard":
		for i in range(0, w, 8):
			ci.draw_rect(Rect2(i, 0, 2, 4), lt)
			ci.draw_rect(Rect2(i, h - 4, 2, 4), lt)

static func _obstacle(ci: CanvasItem, style: String, cell: Vector2i) -> void:
	var o := Vector2(cell.x * CELL, cell.y * CELL)
	var outline := Color("3b2418")
	match style:
		"rock":
			ci.draw_rect(Rect2(o + Vector2(1, 4), Vector2(14, 11)), outline)
			ci.draw_rect(Rect2(o + Vector2(3, 2), Vector2(10, 3)), outline)
			ci.draw_rect(Rect2(o + Vector2(2, 5), Vector2(12, 9)), Color("8d8d9c"))
			ci.draw_rect(Rect2(o + Vector2(4, 3), Vector2(8, 3)), Color("a9a9ba"))
			ci.draw_rect(Rect2(o + Vector2(3, 11), Vector2(10, 3)), Color("6b6b7a"))
		"hedge":
			ci.draw_rect(Rect2(o + Vector2(0, 1), Vector2(16, 15)), Color("1f5a2a"))
			ci.draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 12)), Color("2f8a3c"))
			ci.draw_rect(Rect2(o + Vector2(3, 3), Vector2(4, 3)), Color("49b04f"))
			ci.draw_rect(Rect2(o + Vector2(9, 7), Vector2(4, 3)), Color("49b04f"))
			ci.draw_rect(Rect2(o + Vector2(1, 13), Vector2(14, 3)), Color("3d2a1a"))
		"tree", "snow_tree":
			var snow := style == "snow_tree"
			ci.draw_rect(Rect2(o + Vector2(7, 11), Vector2(3, 5)), Color("6b4226"))
			var pts := PackedVector2Array([o + Vector2(8, 0), o + Vector2(15, 12), o + Vector2(1, 12)])
			ci.draw_colored_polygon(pts, Color("1d5c4a") if snow else Color("2f8a3c"))
			ci.draw_colored_polygon(PackedVector2Array([o + Vector2(8, 0), o + Vector2(12, 6), o + Vector2(4, 6)]), Color("f4f9ff") if snow else Color("49b04f"))
			if snow:
				ci.draw_rect(Rect2(o + Vector2(3, 9), Vector2(10, 2)), Color("f4f9ff"))
		"sofa":
			ci.draw_rect(Rect2(o + Vector2(0, 2), Vector2(16, 13)), Color("3d4d12"))
			ci.draw_rect(Rect2(o + Vector2(0, 3), Vector2(16, 11)), Color("6b8a1f"))
			ci.draw_rect(Rect2(o + Vector2(1, 3), Vector2(14, 4)), Color("557015"))
			ci.draw_rect(Rect2(o + Vector2(1, 8), Vector2(14, 5)), Color("86a52b"))
		"table":
			ci.draw_circle(o + Vector2(8, 8), 8.0, Color("5a3418"))
			ci.draw_circle(o + Vector2(8, 8), 7.0, Color("c88a4f"))
			ci.draw_circle(o + Vector2(6, 6), 2.0, Color("e0a566"))
		"pond":
			ci.draw_rect(Rect2(o, Vector2(16, 16)), Color("2d6fa8"))
			ci.draw_rect(Rect2(o + Vector2(1, 1), Vector2(14, 14)), Color("4aa3df"))
			ci.draw_rect(Rect2(o + Vector2(3, 5), Vector2(6, 1)), Color("bfe6ff"))
			ci.draw_rect(Rect2(o + Vector2(7, 10), Vector2(6, 1)), Color("bfe6ff"))
		"snowman":
			ci.draw_circle(o + Vector2(8, 11), 5.0, outline)
			ci.draw_circle(o + Vector2(8, 11), 4.0, Color.WHITE)
			ci.draw_circle(o + Vector2(8, 5), 3.5, outline)
			ci.draw_circle(o + Vector2(8, 5), 2.5, Color.WHITE)
			ci.draw_rect(Rect2(o + Vector2(8, 5), Vector2(3, 1)), Color("f2994a"))
			ci.draw_rect(Rect2(o + Vector2(6, 4), Vector2(1, 1)), Color.BLACK)
			ci.draw_rect(Rect2(o + Vector2(5, 7), Vector2(6, 1)), Color("e2506b"))

static func draw_item(ci: CanvasItem, id: String, center: Vector2, t: float, animate: bool) -> void:
	var c := center + Vector2(0, sin(t * 4.0) * 0.8 if animate else 0.0)
	var outline := Color("3b2418")
	match id:
		"fish", "golden":
			var body := Color("5fb8ff") if id == "fish" else Color("ffd23f")
			var dark := Color("2a7fc0") if id == "fish" else Color("d99a00")
			var pts := PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-3, -4), c + Vector2(3, -4), c + Vector2(5, 0), c + Vector2(3, 4), c + Vector2(-3, 4)])
			ci.draw_colored_polygon(pts, body)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(5, 0), c + Vector2(8, -4), c + Vector2(8, 4)]), dark)
			ci.draw_rect(Rect2(c + Vector2(-4, -1.5), Vector2(1.5, 1.5)), outline)
			ci.draw_rect(Rect2(c + Vector2(0, -3), Vector2(1, 6)), dark)
			if id == "golden" and fmod(t * 3.0, 1.0) < 0.5:
				ci.draw_rect(Rect2(c + Vector2(-2, -7), Vector2(1, 3)), Color.WHITE)
				ci.draw_rect(Rect2(c + Vector2(-3, -6), Vector2(3, 1)), Color.WHITE)
		"milk":
			ci.draw_rect(Rect2(c + Vector2(-4, -5), Vector2(8, 11)), outline)
			ci.draw_rect(Rect2(c + Vector2(-3, -4), Vector2(6, 9)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-3, -6), Vector2(6, 3)), Color("8fd0ff"))
			ci.draw_rect(Rect2(c + Vector2(-2, -1), Vector2(4, 4)), Color("5fb8ff"))
		"yarn":
			ci.draw_circle(c, 6.0, outline)
			ci.draw_circle(c, 5.0, Color("ff6fae"))
			ci.draw_arc(c, 3.0, 0.3, 4.0, 8, Color("ffc2dd"), 1.0)
			ci.draw_arc(c, 4.5, 2.0, 5.5, 8, Color("c2417a"), 1.0)
			ci.draw_line(c + Vector2(4, 3), c + Vector2(8, 6), Color("ff6fae"), 1.0)
		"scissors":
			ci.draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), Color("cfd8dc"), 2.0)
			ci.draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Color("cfd8dc"), 2.0)
			ci.draw_circle(c + Vector2(-5, 6), 2.0, Color("e2506b"))
			ci.draw_circle(c + Vector2(5, 6), 2.0, Color("e2506b"))

## Orange tabby kitten head: white muzzle, big eyes, pink nose. Faces `dir`.
static func draw_kitten(ci: CanvasItem, center: Vector2, dir: Vector2i, t: float, dead: bool) -> void:
	var o := center
	var outline := Color("4a2a12")
	var orange := Color("f5922f")
	var light := Color("ffb255")
	var stripe := Color("d9741a")
	# ears
	var ear_l := PackedVector2Array([o + Vector2(-7, -3), o + Vector2(-6, -9), o + Vector2(-1, -5)])
	var ear_r := PackedVector2Array([o + Vector2(7, -3), o + Vector2(6, -9), o + Vector2(1, -5)])
	ci.draw_colored_polygon(ear_l, outline)
	ci.draw_colored_polygon(ear_r, outline)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-6, -4), o + Vector2(-5.5, -7.5), o + Vector2(-2.5, -5)]), Color("ff9db8"))
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(6, -4), o + Vector2(5.5, -7.5), o + Vector2(2.5, -5)]), Color("ff9db8"))
	# head
	ci.draw_rect(Rect2(o + Vector2(-8, -6), Vector2(16, 13)), outline)
	ci.draw_rect(Rect2(o + Vector2(-9, -4), Vector2(18, 9)), outline)
	ci.draw_rect(Rect2(o + Vector2(-7, -5), Vector2(14, 11)), orange)
	ci.draw_rect(Rect2(o + Vector2(-8, -3), Vector2(16, 7)), orange)
	ci.draw_rect(Rect2(o + Vector2(-5, -5), Vector2(10, 2)), light)
	ci.draw_rect(Rect2(o + Vector2(-1, -5), Vector2(2, 3)), stripe)
	ci.draw_rect(Rect2(o + Vector2(-4, -5), Vector2(1, 2)), stripe)
	ci.draw_rect(Rect2(o + Vector2(3, -5), Vector2(1, 2)), stripe)
	# face shifts toward the travel direction
	var f := Vector2(dir) * 1.5
	ci.draw_rect(Rect2(o + f + Vector2(-4, 1), Vector2(8, 4)), Color.WHITE)  # muzzle
	if dead:
		for ex in [-4.0, 2.0]:
			ci.draw_line(o + f + Vector2(ex, -2), o + f + Vector2(ex + 2, 1), outline, 1.0)
			ci.draw_line(o + f + Vector2(ex + 2, -2), o + f + Vector2(ex, 1), outline, 1.0)
	else:
		var blink := fmod(t, 3.2) > 3.05
		var eh := 1.0 if blink else 3.5
		for ex in [-4.5, 2.5]:
			ci.draw_rect(Rect2(o + f + Vector2(ex, -2), Vector2(2, eh)), Color("1a1020"))
			if not blink:
				ci.draw_rect(Rect2(o + f + Vector2(ex, -2), Vector2(1, 1)), Color.WHITE)
	ci.draw_rect(Rect2(o + f + Vector2(-1, 1.5), Vector2(2, 1)), Color("ff7fa8"))  # nose
	ci.draw_line(o + Vector2(-9, 1), o + Vector2(-12, 0), outline, 1.0)
	ci.draw_line(o + Vector2(-9, 3), o + Vector2(-12, 4), outline, 1.0)
	ci.draw_line(o + Vector2(9, 1), o + Vector2(12, 0), outline, 1.0)
	ci.draw_line(o + Vector2(9, 3), o + Vector2(12, 4), outline, 1.0)

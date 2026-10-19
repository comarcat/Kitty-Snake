class_name YarnMath
extends RefCounted
## Pure visual helpers for the yarn line. Never used by the simulation.

const WIGGLE_AMPLITUDE := 0.9

static func wiggle(index: int, time: float, amp: float, reduce_motion: bool) -> float:
	if reduce_motion:
		return 0.0
	return sin(time * 7.0 + float(index) * 0.8) * amp

## Interpolated cell-centre points for body cells (head first).
static func body_points(prev: Array[Vector2i], cur: Array[Vector2i], alpha: float, cell: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in cur.size():
		var p: Vector2i = prev[i] if i < prev.size() else prev.back()
		var a := (Vector2(p) + Vector2(0.5, 0.5)) * cell
		var b := (Vector2(cur[i]) + Vector2(0.5, 0.5)) * cell
		pts.append(a.lerp(b, alpha))
	return pts

## Chaikin corner cutting, endpoints preserved.
static func smooth(points: Array[Vector2], iterations: int = 2) -> Array[Vector2]:
	var pts := points
	for _it in iterations:
		if pts.size() < 3:
			break
		var out: Array[Vector2] = [pts[0]]
		for i in pts.size() - 1:
			out.append(pts[i].lerp(pts[i + 1], 0.25))
			out.append(pts[i].lerp(pts[i + 1], 0.75))
		out.append(pts[pts.size() - 1])
		pts = out
	return pts

## Perpendicular wiggle; the first point (the kitten) stays anchored.
static func apply_wiggle(points: Array[Vector2], time: float, reduce_motion: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in points.size():
		if i == 0 or i == points.size() - 1 or reduce_motion:
			out.append(points[i])
			continue
		var tangent := (points[i + 1] - points[i - 1]).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		out.append(points[i] + normal * wiggle(i, time, WIGGLE_AMPLITUDE, false))
	return out

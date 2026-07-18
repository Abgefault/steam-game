extends PanelContainer
## End-of-day report popup.

var report: Dictionary = {}
var day: int = 1


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.center_popup(self)
	custom_minimum_size = Vector2(460, 320)
	var v := UIKit.vbox(8)
	add_child(v)
	v.add_child(UIKit.title("Day %d — Daily Report" % day))
	var profit := float(report.get("profit", 0.0))
	var g := UIKit.grid(2)
	v.add_child(g)
	var rows := [
		["Revenue", UIKit.money(float(report.get("revenue", 0)))],
		["Expenses", UIKit.money(float(report.get("expenses", 0)))],
		["Profit", UIKit.money(profit)],
		["Units sold", str(int(report.get("units_sold", 0)))],
		["Customers", "%d (%d happy)" % [int(report.get("customers", 0)), int(report.get("customers_happy", 0))]],
		["Wasted units", str(int(report.get("wasted_units", 0)))],
		["Cash", UIKit.money(float(report.get("cash", 0)))],
		["Valuation", UIKit.money(float(report.get("valuation", 0)))],
	]
	if report.has("trial_day"):
		rows.append(["Trial deliveries", "%d / %d" % [int(report.trial_delivered), int(report.trial_target)]])
	for r: Array in rows:
		g.add_child(UIKit.label(str(r[0]) + ":", UIKit.TEXT_DIM))
		var val := UIKit.label(str(r[1]))
		if str(r[0]) == "Profit":
			val.add_theme_color_override("font_color", UIKit.OK if profit >= 0 else UIKit.ERR)
		g.add_child(val)
	if report.has("payroll_missed"):
		v.add_child(UIKit.label("⚠ PAYROLL MISSED — staff morale collapsed!", UIKit.ERR))
	if report.has("loan_missed"):
		v.add_child(UIKit.label("⚠ LOAN PAYMENT MISSED — the bank is watching.", UIKit.ERR))
	v.add_child(UIKit.separator())
	var row := UIKit.hbox(8)
	v.add_child(row)
	row.add_child(UIKit.button("Continue (new day)", func():
		queue_free()
		SimClock.set_paused(false)))
	row.add_child(UIKit.button("Stay paused", queue_free))

extends PanelContainer
## The in-game company tablet: left navigation, content pages. All pages
## read/write the authoritative Game.state through the sim APIs.

const PAGES := ["Overview", "Campaign", "Orders", "Finances", "Inventory",
	"Products", "Production", "Automation", "Staff", "Stores", "Market",
	"Research", "Compliance", "Objectives", "Events"]

var _content: ScrollContainer
var _page: String = "Overview"
var _nav_buttons: Dictionary = {}
var _refresh_timer: Timer


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := 40
	offset_left = margin
	offset_top = margin
	offset_right = -margin
	offset_bottom = -margin
	var h := UIKit.hbox(0)
	add_child(h)
	var nav_panel := PanelContainer.new()
	var nav := UIKit.vbox(2)
	nav_panel.add_child(nav)
	h.add_child(nav_panel)
	nav.add_child(UIKit.title("GREEN EMPIRE", 19))
	nav.add_child(UIKit.label(str(Game.state.company.name), UIKit.TEXT_DIM, 13))
	nav.add_child(UIKit.separator())
	for p in PAGES:
		var b := UIKit.button(p, _goto.bind(p))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_nav_buttons[p] = b
		nav.add_child(b)
	nav.add_child(UIKit.separator())
	nav.add_child(UIKit.button("Close (TAB)", queue_free))
	_content = ScrollContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(_content)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 1.0
	_refresh_timer.timeout.connect(_render)
	add_child(_refresh_timer)
	_refresh_timer.start()
	_goto("Overview")


func _goto(page: String) -> void:
	_page = page
	for p: String in _nav_buttons.keys():
		(_nav_buttons[p] as Button).modulate = Color(1, 1, 1) if p == page else Color(0.65, 0.7, 0.66)
	_render()


func _render() -> void:
	for c in _content.get_children():
		c.queue_free()
	var v := UIKit.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("margin_left", 16)
	_content.add_child(v)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	_content.remove_child(v)
	pad.add_child(v)
	_content.add_child(pad)
	match _page:
		"Overview": _page_overview(v)
		"Campaign": _page_campaign(v)
		"Orders": _page_orders(v)
		"Finances": _page_finances(v)
		"Inventory": _page_inventory(v)
		"Products": _page_products(v)
		"Production": _page_production(v)
		"Automation": _page_automation(v)
		"Staff": _page_staff(v)
		"Stores": _page_stores(v)
		"Market": _page_market(v)
		"Research": _page_research(v)
		"Compliance": _page_compliance(v)
		"Objectives": _page_objectives(v)
		"Events": _page_events(v)


# ----------------------------------------------------------------- pages

func _page_overview(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Company Overview"))
	var g := UIKit.grid(2)
	v.add_child(g)
	var rows := [
		["Company", str(s.company.name)],
		["Stage", "%d — %s" % [int(s.stage), Game.stage_name()]],
		["Day", "%d of %d (%d left)" % [int(s.day), CampaignSim.CAMPAIGN_DAYS, CampaignSim.days_remaining(s)]],
		["Cash", UIKit.money(Game.cash())],
		["Valuation", UIKit.money(EconomySim.valuation(s))],
		["Loan remaining", UIKit.money(float(s.loan_balance))],
		["Reputation", "%.0f / 100" % float(s.reputation)],
		["Compliance", "%.0f / 100" % float(s.compliance)],
		["Automation", "%.0f%%" % float(s.automation_score)],
		["Research Points", str(int(s.research_points))],
		["Staff", str((s.staff as Array).size())],
		["Warehouse stock", "%d units" % InventorySim.total_qty(s)],
		["Customers served", str(int(s.stats.customers_served))],
		["Units sold (total)", str(int(s.stats.total_units_sold))],
	]
	for r: Array in rows:
		g.add_child(UIKit.label(str(r[0]) + ":", UIKit.TEXT_DIM))
		g.add_child(UIKit.label(str(r[1])))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Next recommended step:", UIKit.TEXT_DIM))
	v.add_child(UIKit.label(AutomationSim.dashboard(s).recommendation, UIKit.ACCENT))


func _page_campaign(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Verdantia City Supply Contract"))
	v.add_child(UIKit.label("Qualify before day %d, then pass the %d-day supply trial. %d days remain."
		% [CampaignSim.QUALIFY_BY_DAY, CampaignSim.TRIAL_DAYS, CampaignSim.days_remaining(s)]))
	v.add_child(UIKit.separator())
	if s.trial.active:
		var t := CampaignSim.trial_status(s)
		v.add_child(UIKit.title("FINAL TRIAL — Day %d of %d" % [int(t.day), CampaignSim.TRIAL_DAYS], 18))
		var g := UIKit.grid(2)
		v.add_child(g)
		for r: Array in [
			["Delivered", "%d / %d units" % [int(t.delivered), int(t.target)]],
			["On-time days", "%.0f%% (need ≥ %d%%)" % [float(t.on_time_pct), int(CampaignSim.TRIAL_ON_TIME_PCT)]],
			["Rejected", "%.1f%% (keep < %d%%)" % [float(t.reject_pct), int(CampaignSim.TRIAL_MAX_REJECT_PCT)]],
			["Avg quality", "%.2f (need ≥ %d = Select)" % [float(t.avg_quality), CampaignSim.TRIAL_MIN_QUALITY]],
			["Trial profit", UIKit.money(float(t.profit))],
			["Violations", str(int(t.violations))],
		]:
			g.add_child(UIKit.label(str(r[0]) + ":", UIKit.TEXT_DIM))
			g.add_child(UIKit.label(str(r[1])))
		v.add_child(UIKit.label("Deliveries pull tested Select+ lots from the warehouse every hour. Keep production running!", UIKit.WARN))
		return
	v.add_child(UIKit.label("Qualification requirements:", UIKit.TEXT_DIM))
	for req in CampaignSim.requirements(s):
		var row := UIKit.hbox(10)
		v.add_child(row)
		var mark := UIKit.label("✔" if bool(req.done) else "✘",
			UIKit.OK if bool(req.done) else UIKit.ERR, 16)
		mark.custom_minimum_size.x = 22
		row.add_child(mark)
		var lbl := UIKit.label(str(req.label))
		lbl.custom_minimum_size.x = 320
		row.add_child(lbl)
		row.add_child(UIKit.progress(float(req.progress), 1.0,
			UIKit.OK if bool(req.done) else UIKit.ACCENT_DIM))
		row.add_child(UIKit.label(str(req.value), UIKit.TEXT_DIM))
	v.add_child(UIKit.separator())
	if CampaignSim.qualified(s):
		v.add_child(UIKit.button("BEGIN THE FINAL 30-DAY TRIAL", func():
			UIKit.confirm(self, "Start the final trial now? Your real production and inventory will be used.",
				func(): CampaignSim.start_trial(Game.state))))
	else:
		v.add_child(UIKit.label("Meet every requirement to unlock the final trial.", UIKit.TEXT_DIM))


func _page_orders(v: VBoxContainer) -> void:
	var s := Game.state
	OrdersSim.ensure_state(s)
	v.add_child(UIKit.title("Wholesale Orders"))
	if not "logistics_license" in (s.licenses as Array):
		v.add_child(UIKit.label("Wholesale requires the logistics license (reach stage 3 or research Wholesale Operations).", UIKit.WARN))
		return
	v.add_child(UIKit.label("Active orders:", UIKit.TEXT_DIM))
	if (s.wholesale.active as Array).is_empty():
		v.add_child(UIKit.label("None."))
	for o: Dictionary in s.wholesale.active:
		var p: Dictionary = DataRegistry.products[str(o.product_id)]
		v.add_child(UIKit.label("• %s — %d/%d× %s (min %s) — due day %d — pays %s" % [
			str(o.customer), int(o.delivered), int(o.qty), str(p.name),
			Game.quality_name(int(o.min_quality)), int(o.deadline_day), UIKit.money(float(o.payment))]))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Today's offers:", UIKit.TEXT_DIM))
	if (s.wholesale.offers as Array).is_empty():
		v.add_child(UIKit.label("No offers today — check back tomorrow."))
	for o: Dictionary in s.wholesale.offers:
		var p: Dictionary = DataRegistry.products[str(o.product_id)]
		var row := UIKit.hbox(10)
		v.add_child(row)
		row.add_child(UIKit.label("%s wants %d× %s (min %s), due day %d — %s (penalty %s)" % [
			str(o.customer), int(o.qty), str(p.name), Game.quality_name(int(o.min_quality)),
			int(o.deadline_day), UIKit.money(float(o.payment)), UIKit.money(float(o.penalty))]))
		row.add_child(UIKit.button("Accept", func():
			OrdersSim.accept(Game.state, int(o.id))
			_render()))


func _page_finances(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Finances"))
	var g := UIKit.grid(2)
	v.add_child(g)
	for r: Array in [
		["Cash", UIKit.money(Game.cash())],
		["Valuation", UIKit.money(EconomySim.valuation(s))],
		["Loan balance", UIKit.money(float(s.loan_balance))],
		["Weekly loan payment", UIKit.money(float(s.loan_payment))],
		["Overdraft limit", UIKit.money(DataRegistry.bal("overdraft_limit"))],
		["Today's revenue", UIKit.money(float(s.daily.revenue))],
		["Today's expenses", UIKit.money(float(s.daily.expenses))],
	]:
		g.add_child(UIKit.label(str(r[0]) + ":", UIKit.TEXT_DIM))
		g.add_child(UIKit.label(str(r[1])))
	if float(s.loan_balance) > 0.0 and Game.cash() > 2000.0:
		v.add_child(UIKit.button("Extra loan payment: %s" % UIKit.money(minf(2000.0, float(s.loan_balance))), func():
			var pay := minf(2000.0, float(Game.state.loan_balance))
			if EconomySim.spend(Game.state, pay, "Extra loan payment", "reporting"):
				Game.state.loan_balance = float(Game.state.loan_balance) - pay
			_render()))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Last daily results:", UIKit.TEXT_DIM))
	var table := UIKit.grid(5)
	v.add_child(table)
	for htxt in ["Day", "Revenue", "Expenses", "Profit", "Units"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	var daily: Array = s.stats.daily
	for rec: Dictionary in daily.slice(maxi(0, daily.size() - 10)):
		table.add_child(UIKit.label(str(int(rec.day))))
		table.add_child(UIKit.label(UIKit.money(float(rec.revenue))))
		table.add_child(UIKit.label(UIKit.money(float(rec.expenses))))
		var profit := float(rec.get("profit", 0.0))
		table.add_child(UIKit.label(UIKit.money(profit), UIKit.OK if profit >= 0 else UIKit.ERR))
		table.add_child(UIKit.label(str(int(rec.units_sold))))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Today's transactions:", UIKit.TEXT_DIM))
	var tx: Array = s.daily.transactions
	for entry: Dictionary in tx.slice(maxi(0, tx.size() - 15)):
		var amt := float(entry.amount)
		v.add_child(UIKit.label("%s  %s" % [UIKit.money(amt), str(entry.reason)],
			UIKit.OK if amt >= 0 else UIKit.TEXT_DIM, 13))


func _page_inventory(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Inventory & Supplies"))
	var sup := UIKit.hbox(12)
	v.add_child(sup)
	sup.add_child(UIKit.label("Seed kits: %d" % int(s.supplies.seed_units)))
	sup.add_child(UIKit.button("Buy 2 (%s)" % UIKit.money(MarketSim.supplier_price(s, DataRegistry.bal("price_seed_unit") * 2)),
		func(): MarketSim.buy_supplies(Game.state, "seed_units", 2); _render()))
	sup.add_child(UIKit.label("Packaging: %d" % int(s.supplies.packaging_units)))
	sup.add_child(UIKit.button("Buy 60 (%s)" % UIKit.money(MarketSim.supplier_price(s, DataRegistry.bal("price_packaging_unit") * 60)),
		func(): MarketSim.buy_supplies(Game.state, "packaging_units", 60); _render()))
	sup.add_child(UIKit.label("Spare parts: %d" % int(s.supplies.spare_parts)))
	sup.add_child(UIKit.button("Buy 1 (%s)" % UIKit.money(MarketSim.supplier_price(s, DataRegistry.bal("price_spare_part"))),
		func(): MarketSim.buy_supplies(Game.state, "spare_parts", 1); _render()))
	v.add_child(UIKit.separator())
	var pools := UIKit.hbox(20)
	v.add_child(pools)
	for pool_info in [["Harvest", s.raw], ["Conditioned", s.conditioned], ["Refined", s.processed]]:
		var col := UIKit.vbox(2)
		pools.add_child(col)
		col.add_child(UIKit.label(str(pool_info[0]) + ":", UIKit.ACCENT))
		var pool: Dictionary = pool_info[1]
		if pool.is_empty():
			col.add_child(UIKit.label("—", UIKit.TEXT_DIM))
		for k: String in pool.keys():
			col.add_child(UIKit.label("%s × %d" % [str(DataRegistry.strains.get(k, {}).get("name", k)), int(pool[k])]))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Finished lots (FEFO):", UIKit.TEXT_DIM))
	var table := UIKit.grid(7)
	v.add_child(table)
	for htxt in ["Lot", "Product", "Qty", "Quality", "Tested", "Expires", "Location"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	var lots: Array = (s.lots as Array).duplicate()
	lots.sort_custom(func(a, b): return int(a.day_expires) < int(b.day_expires))
	for lot: Dictionary in lots.slice(0, 25):
		table.add_child(UIKit.label(str(lot.lot_number), UIKit.TEXT_DIM, 13))
		table.add_child(UIKit.label(str(DataRegistry.products[str(lot.product_id)].name)))
		table.add_child(UIKit.label(str(int(lot.qty))))
		table.add_child(UIKit.label(Game.quality_name(int(lot.quality))))
		table.add_child(UIKit.label("✔" if bool(lot.tested) else "✘",
			UIKit.OK if bool(lot.tested) else UIKit.ERR))
		var days_left := int(lot.day_expires) - int(s.day)
		table.add_child(UIKit.label("day %d (%dd)" % [int(lot.day_expires), days_left],
			UIKit.ERR if days_left <= 2 else UIKit.TEXT))
		table.add_child(UIKit.label(str(lot.location), UIKit.TEXT_DIM, 13))


func _page_products(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Products & Pricing"))
	var policy_row := UIKit.hbox(10)
	v.add_child(policy_row)
	policy_row.add_child(UIKit.label("Pricing policy:"))
	for pol in ["budget", "recommended", "premium", "match_market", "maximize_margin", "clear_expiring"]:
		var b := UIKit.button(pol.capitalize(), func():
			Game.state.price_policy = pol
			Game.state.prices.clear()
			_render())
		if str(s.price_policy) == pol:
			b.modulate = Color(1, 1, 0.7)
		policy_row.add_child(b)
	var table := UIKit.grid(7)
	v.add_child(table)
	for htxt in ["Product", "Category", "Cost", "Price", "Margin", "Stock", "Adjust"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	for pid: String in DataRegistry.products.keys():
		var p: Dictionary = DataRegistry.products[pid]
		if int(p.stage_required) > int(s.stage):
			continue
		var price := EconomySim.effective_price(s, pid)
		table.add_child(UIKit.label(str(p.name)))
		table.add_child(UIKit.label(str(p.category), UIKit.TEXT_DIM))
		table.add_child(UIKit.label(UIKit.money(float(p.base_cost))))
		table.add_child(UIKit.label(UIKit.money(price)))
		table.add_child(UIKit.label("%.0f%%" % (EconomySim.gross_margin(s, pid) * 100.0)))
		table.add_child(UIKit.label(str(InventorySim.total_qty(s, pid))))
		var adj := UIKit.hbox(4)
		table.add_child(adj)
		adj.add_child(UIKit.button("−", func():
			Game.state.prices[pid] = maxf(0.5, EconomySim.effective_price(Game.state, pid) - 0.5)
			_render()))
		adj.add_child(UIKit.button("+", func():
			Game.state.prices[pid] = EconomySim.effective_price(Game.state, pid) + 0.5
			_render()))


func _page_production(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Production"))
	var table := UIKit.grid(6)
	v.add_child(table)
	for htxt in ["Machine", "Tier", "State", "Condition", "Progress", "Actions"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	for m: Dictionary in s.machines.values():
		table.add_child(UIKit.label(MachineSim.display_name(m)))
		table.add_child(UIKit.label("T%d" % int(m.tier)))
		table.add_child(UIKit.label(str(m.state).to_upper(),
			UIKit.OK if str(m.state) == "running" else (UIKit.ERR if str(m.state) == "broken" else UIKit.TEXT)))
		table.add_child(UIKit.progress(float(m.condition), 100.0,
			UIKit.OK if float(m.condition) > 50 else UIKit.WARN))
		var prog := 0.0
		if str(m.state) == "running":
			prog = float(m.progress) / maxf(1.0, float(m.duration))
		table.add_child(UIKit.progress(prog))
		var acts := UIKit.hbox(4)
		table.add_child(acts)
		var mid := str(m.id)
		var cost := MachineSim.upgrade_cost(m)
		if cost >= 0.0:
			acts.add_child(UIKit.button("Upgrade %s" % UIKit.money(cost), func():
				MachineSim.upgrade(Game.state, mid)
				_render()))
		if float(m.condition) < 70.0 or str(m.state) == "broken":
			acts.add_child(UIKit.button("Repair", func():
				MachineSim.repair(Game.state, mid)
				_render()))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Active batches:", UIKit.TEXT_DIM))
	if (s.batches as Array).is_empty():
		v.add_child(UIKit.label("None — feed the chain: Cultivation → Conditioning → Processing → Product Machine → Lab → Packaging."))
	for b: Dictionary in s.batches:
		var p: Dictionary = DataRegistry.products[str(b.product_id)]
		v.add_child(UIKit.label("• Batch #%d — %s ×%d, %s, %s" % [int(b.id), str(p.name), int(b.qty),
			Game.quality_name(int(b.quality)),
			"tested ✔" if bool(b.tested) else ("in lab…" if bool(b.in_lab) else "awaiting lab test")]))


func _page_automation(v: VBoxContainer) -> void:
	var s := Game.state
	var dash := AutomationSim.dashboard(s)
	v.add_child(UIKit.title("Automation Dashboard"))
	var head := UIKit.hbox(16)
	v.add_child(head)
	head.add_child(UIKit.label("Overall score:", UIKit.TEXT_DIM))
	head.add_child(UIKit.progress(float(dash.overall), 100.0,
		UIKit.OK if float(dash.overall) >= 85.0 else UIKit.ACCENT))
	head.add_child(UIKit.label("%.0f%% (campaign needs 85%%)" % float(dash.overall)))
	v.add_child(UIKit.label("Manual actions today: %d — automated: %d — labor-hours saved: %.1f"
		% [int(dash.manual_today), int(dash.auto_today), float(dash.labor_hours_saved)], UIKit.TEXT_DIM))
	var g := UIKit.grid(4)
	v.add_child(g)
	for dept: String in (dash.departments as Dictionary).keys():
		g.add_child(UIKit.label(dept.capitalize() + ":", UIKit.TEXT_DIM))
		g.add_child(UIKit.progress(float(dash.departments[dept]), 100.0))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Recommendation: " + str(dash.recommendation), UIKit.ACCENT))
	for txt in (dash.blocked as Array) + (dash.starved as Array):
		v.add_child(UIKit.label("⚠ " + str(txt), UIKit.WARN))
	v.add_child(UIKit.separator())
	# Policies.
	v.add_child(UIKit.label("Automation policies:", UIKit.TEXT_DIM))
	var pol_grid := UIKit.grid(2)
	v.add_child(pol_grid)
	var policies := [
		["purchasing", "Automatic supplier purchasing", "auto_purchasing"],
		["restock", "Automatic store replenishment", "auto_replenishment"],
		["maintenance", "Scheduled maintenance", "maintenance_scheduling"],
		["scheduling", "Central production scheduling", "central_scheduling"],
		["reporting", "Automated financial reporting", "advanced_analytics"],
	]
	for pol: Array in policies:
		var key := str(pol[0])
		var research_id := str(pol[2])
		var cb := CheckBox.new()
		cb.text = str(pol[1])
		cb.button_pressed = bool(s.auto[key])
		cb.disabled = not Game.has_research(research_id)
		cb.toggled.connect(func(on: bool): Game.state.auto[key] = on)
		pol_grid.add_child(cb)
		pol_grid.add_child(UIKit.label("" if Game.has_research(research_id) else "needs research: %s"
			% str(DataRegistry.research[research_id].name), UIKit.TEXT_DIM, 13))
	v.add_child(UIKit.separator())
	# Conveyor builder.
	v.add_child(UIKit.label("Conveyor connections:", UIKit.TEXT_DIM))
	if not Game.has_research("conveyors"):
		v.add_child(UIKit.label("Research 'Conveyor Systems' (Automation branch) to build conveyors.", UIKit.WARN))
	else:
		for c: Dictionary in s.conveyors:
			var row := UIKit.hbox(8)
			v.add_child(row)
			row.add_child(UIKit.label("%s → %s" % [
				MachineSim.display_name(s.machines[str(c.from)]),
				MachineSim.display_name(s.machines[str(c.to)])]))
			row.add_child(UIKit.button("Remove", func():
				Game.state.conveyors.erase(c)
				_rebuild_world_conveyors()
				_render()))
		var builder := UIKit.hbox(8)
		v.add_child(builder)
		var from_opt := OptionButton.new()
		var to_opt := OptionButton.new()
		var ids: Array = s.machines.keys()
		for id: String in ids:
			from_opt.add_item(MachineSim.display_name(s.machines[id]))
			to_opt.add_item(MachineSim.display_name(s.machines[id]))
		builder.add_child(UIKit.label("Connect:"))
		builder.add_child(from_opt)
		builder.add_child(UIKit.label("→"))
		builder.add_child(to_opt)
		var cost := DataRegistry.bal("conveyor_cost", 900.0)
		builder.add_child(UIKit.button("Build (%s)" % UIKit.money(cost), func():
			var from_id := str(ids[from_opt.selected])
			var to_id := str(ids[to_opt.selected])
			if from_id == to_id:
				EventBus.notify("A conveyor needs two different machines.", "warning")
				return
			for existing: Dictionary in Game.state.conveyors:
				if str(existing.from) == from_id:
					EventBus.notify("That machine's output is already connected.", "warning")
					return
			if EconomySim.spend(Game.state, cost, "Conveyor construction", "warehouse"):
				Game.state.conveyors.append({"from": from_id, "to": to_id})
				_rebuild_world_conveyors()
				EventBus.notify("Conveyor built.", "success")
			_render()))


func _rebuild_world_conveyors() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("rebuild_conveyors"):
		scene.call("rebuild_conveyors")


func _page_staff(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Staff"))
	var table := UIKit.grid(7)
	v.add_child(table)
	for htxt in ["Name", "Role", "Skill", "Level", "Morale", "Wage/day", "Actions"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	for e: Dictionary in s.staff:
		table.add_child(UIKit.label("%s  (%s)" % [str(e.name), ", ".join(e.traits)]))
		table.add_child(UIKit.label(StaffSim.ROLE_NAMES.get(str(e.role), "?")))
		table.add_child(UIKit.label(str(int(e.skill))))
		table.add_child(UIKit.label(str(int(e.level))))
		table.add_child(UIKit.progress(float(e.morale), 100.0,
			UIKit.OK if float(e.morale) > 50 else UIKit.WARN))
		table.add_child(UIKit.label(UIKit.money(float(e.wage))))
		var acts := UIKit.hbox(4)
		table.add_child(acts)
		var eid := int(e.id)
		acts.add_child(UIKit.button("Bonus $100", func():
			StaffSim.give_bonus(Game.state, eid, 100.0)
			_render()))
		acts.add_child(UIKit.button("Dismiss", func():
			UIKit.confirm(self, "Dismiss %s?" % str(e.name), func():
				StaffSim.fire(Game.state, eid)
				_render())))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Hire (fee %s + daily wage):" % UIKit.money(DataRegistry.bal("hiring_fee")), UIKit.TEXT_DIM))
	var hire_grid := UIKit.grid(4)
	v.add_child(hire_grid)
	for role: String in StaffSim.ROLES:
		var cand := StaffSim.generate_candidate(s, role)
		hire_grid.add_child(UIKit.label(StaffSim.ROLE_NAMES[role]))
		hire_grid.add_child(UIKit.label("%s — skill %d" % [str(cand.name), int(cand.skill)]))
		hire_grid.add_child(UIKit.label("%s/day" % UIKit.money(float(cand.wage))))
		hire_grid.add_child(UIKit.button("Hire", func():
			StaffSim.hire(Game.state, cand)
			_render()))


func _page_stores(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Stores & City Map"))
	for district_id: String in DataRegistry.districts.keys():
		var d: Dictionary = DataRegistry.districts[district_id]
		var store_id := "store_%s" % district_id
		var owned: bool = s.stores.has(store_id) and bool(s.stores[store_id].owned)
		var panel_content := UIKit.vbox(4)
		v.add_child(UIKit.panel(panel_content))
		panel_content.add_child(UIKit.title(str(d.name), 17))
		panel_content.add_child(UIKit.label(str(d.desc), UIKit.TEXT_DIM, 13))
		if owned:
			var st: Dictionary = s.stores[store_id]
			var row := UIKit.hbox(14)
			panel_content.add_child(row)
			row.add_child(UIKit.label("OPEN" if bool(st.open) else "CLOSED",
				UIKit.OK if bool(st.open) else UIKit.TEXT_DIM))
			row.add_child(UIKit.label("Satisfaction %.0f%%" % float(st.satisfaction)))
			row.add_child(UIKit.label("Regulars %d" % int(st.regulars)))
			row.add_child(UIKit.label("Appeal %.0f" % float(st.appeal)))
			row.add_child(UIKit.label("Today: %s" % UIKit.money(float(st.daily_sales))))
			var stock := 0
			for lot: Dictionary in InventorySim.lots_at(s, "display:%s" % store_id):
				stock += int(lot.qty)
			row.add_child(UIKit.label("On display: %d" % stock))
			var acts := UIKit.hbox(8)
			panel_content.add_child(acts)
			if SimClock.minute_of_day >= RetailSim.OPEN_MINUTE and SimClock.minute_of_day < RetailSim.CLOSE_MINUTE:
				acts.add_child(UIKit.button("Close store" if bool(st.open) else "Open store", func():
					RetailSim.set_open(Game.state, store_id, not bool(Game.state.stores[store_id].open))
					_render()))
			acts.add_child(UIKit.button("Restock all (from warehouse)", func():
				for pid: String in DataRegistry.products.keys():
					RetailSim.restock(Game.state, store_id, pid, 6, false)
				_render()))
			acts.add_child(UIKit.button("Renovate +Appeal (%s)" % UIKit.money(2000), func():
				if EconomySim.spend(Game.state, 2000, "Store renovation", "planning"):
					Game.state.stores[store_id].appeal = minf(100.0, float(Game.state.stores[store_id].appeal) + 10.0)
					Game.state.stores[store_id].security = minf(100.0, float(Game.state.stores[store_id].security) + 8.0)
				_render()))
		else:
			var cost := RetailSim.store_purchase_cost(district_id)
			panel_content.add_child(UIKit.button("Buy store (%s)" % UIKit.money(cost), func():
				RetailSim.buy_store(Game.state, district_id)
				_render()))


func _page_market(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Market"))
	var table := UIKit.grid(3)
	v.add_child(table)
	for htxt in ["Category", "Demand", "7-day trend"]:
		table.add_child(UIKit.label(htxt, UIKit.ACCENT))
	for c in MarketSim.CATEGORIES:
		table.add_child(UIKit.label(str(c).capitalize()))
		var demand := MarketSim.category_demand(s, c)
		table.add_child(UIKit.progress(demand, 1.6,
			UIKit.OK if demand > 1.0 else UIKit.WARN))
		var hist: Array = s.market.category_history.get(c, [])
		var arrow := "→"
		if hist.size() >= 2:
			var delta := float(hist[-1]) - float(hist[0])
			arrow = "↑" if delta > 0.05 else ("↓" if delta < -0.05 else "→")
		table.add_child(UIKit.label("%s  %.2f" % [arrow, demand]))
	v.add_child(UIKit.separator())
	var trend := str(s.market.trend_product)
	v.add_child(UIKit.label("Trending product: %s" % (
		str(DataRegistry.products[trend].name) if trend != "" else "none"),
		UIKit.ACCENT if trend != "" else UIKit.TEXT_DIM))
	v.add_child(UIKit.label("Competitor pressure: %.0f%%" % (float(s.market.competitor_pressure) * 100.0)))
	v.add_child(UIKit.label("Supplier price index: ×%.2f" % float(s.market.supplier_price_mult)))
	v.add_child(UIKit.label("Utility price index: ×%.2f" % float(s.market.utility_mult)))
	if Game.has_research("demand_forecasting"):
		v.add_child(UIKit.separator())
		v.add_child(UIKit.label("Forecast (Demand Forecasting research):", UIKit.TEXT_DIM))
		for c in MarketSim.CATEGORIES:
			var demand := MarketSim.category_demand(s, c)
			var f := "stable"
			if demand > 1.2:
				f = "cooling off soon"
			elif demand < 0.8:
				f = "likely to recover"
			v.add_child(UIKit.label("• %s: %s" % [str(c).capitalize(), f], UIKit.TEXT_DIM, 13))


func _page_research(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Research — %d RP available" % int(s.research_points)))
	for branch in ["production", "automation", "retail", "logistics", "brand"]:
		v.add_child(UIKit.title(branch.capitalize() + " Branch", 17))
		var table := UIKit.grid(4)
		v.add_child(table)
		for node: Dictionary in ResearchSim.by_branch(branch):
			var id := str(node.id)
			var done := Game.has_research(id)
			table.add_child(UIKit.label(str(node.name), UIKit.OK if done else UIKit.TEXT))
			table.add_child(UIKit.label(str(node.desc), UIKit.TEXT_DIM, 13))
			var cost_txt := "%d RP" % int(node.cost_rp)
			if float(node.get("cost_cash", 0)) > 0:
				cost_txt += " + " + UIKit.money(float(node.cost_cash))
			table.add_child(UIKit.label(cost_txt))
			if done:
				table.add_child(UIKit.label("✔ Done", UIKit.OK))
			else:
				var why := ResearchSim.can_start(s, id)
				if why == "":
					table.add_child(UIKit.button("Research", func():
						ResearchSim.unlock(Game.state, id)
						_render()))
				else:
					table.add_child(UIKit.label(why, UIKit.TEXT_DIM, 13))


func _page_compliance(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Compliance"))
	var head := UIKit.hbox(12)
	v.add_child(head)
	head.add_child(UIKit.label("Rating:"))
	head.add_child(UIKit.progress(float(s.compliance), 100.0,
		UIKit.OK if float(s.compliance) >= 90 else (UIKit.WARN if float(s.compliance) >= 60 else UIKit.ERR)))
	head.add_child(UIKit.label("%.0f / 100 (contract needs 90)" % float(s.compliance)))
	v.add_child(UIKit.label("Licenses held: %s" % ", ".join(s.licenses)))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Audits inspect real state. Keep these clean:", UIKit.TEXT_DIM))
	var untested := 0
	var expiring := 0
	for lot: Dictionary in s.lots:
		if not bool(lot.tested) and str(lot.location).begins_with("display:"):
			untested += 1
		if int(lot.day_expires) - int(s.day) <= 2 and int(lot.qty) > 0:
			expiring += 1
	var checks := [
		["No untested lots on display", untested == 0, "%d untested lots displayed!" % untested],
		["No stock about to expire", expiring == 0, "%d lots expire within 2 days" % expiring],
		["Compliance officer employed", not StaffSim.by_role(s, "compliance").is_empty(), "hire one to drift upward"],
		["Maintenance staffed", not StaffSim.by_role(s, "maintenance").is_empty(), "cleanliness suffers"],
		["Store security invested", _avg_security(s) >= 50.0, "renovate stores to raise security"],
	]
	for c: Array in checks:
		var ok := bool(c[1])
		v.add_child(UIKit.label("%s %s%s" % ["✔" if ok else "✘", str(c[0]),
			"" if ok else " — " + str(c[2])], UIKit.OK if ok else UIKit.WARN))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Scheduled audit every 30 days; surprise audits can occur anytime.", UIKit.TEXT_DIM))


func _avg_security(s: Dictionary) -> float:
	var t := 0.0
	var n := 0
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			t += float(st.security)
			n += 1
	return t / maxf(1.0, float(n))


func _page_objectives(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Objectives"))
	for kind_info in [["tutorial", "Getting Started"], ["regular", "Company Objectives"], ["challenge", "Challenges"]]:
		v.add_child(UIKit.title(str(kind_info[1]), 17))
		for def: Dictionary in DataRegistry.objectives.values():
			if str(def.get("kind", "regular")) != str(kind_info[0]):
				continue
			var st: Dictionary = s.objectives.get(str(def.id), {})
			var done := bool(st.get("done", false))
			var row := UIKit.hbox(8)
			v.add_child(row)
			var mark := UIKit.label("✔" if done else "○", UIKit.OK if done else UIKit.TEXT_DIM)
			mark.custom_minimum_size.x = 20
			row.add_child(mark)
			var lbl := UIKit.label("%s — %s" % [str(def.name), str(def.desc)],
				UIKit.TEXT if not done else UIKit.TEXT_DIM)
			lbl.custom_minimum_size.x = 480
			row.add_child(lbl)
			if not done:
				row.add_child(UIKit.progress(float(st.get("progress", 0.0))))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.title("Achievements (%d / %d)" % [(s.achievements as Array).size(),
		DataRegistry.achievements.size()], 17))
	var g := UIKit.grid(2)
	v.add_child(g)
	for def: Dictionary in DataRegistry.achievements.values():
		var got: bool = str(def.id) in (s.achievements as Array)
		g.add_child(UIKit.label("%s %s" % ["★" if got else "☆", str(def.name)],
			UIKit.WARN if got else UIKit.TEXT_DIM))
		g.add_child(UIKit.label(str(def.desc), UIKit.TEXT_DIM, 13))


func _page_events(v: VBoxContainer) -> void:
	var s := Game.state
	v.add_child(UIKit.title("Messages & Events"))
	v.add_child(UIKit.label("Active:", UIKit.TEXT_DIM))
	if (s.events_active as Array).is_empty():
		v.add_child(UIKit.label("Nothing happening right now."))
	for ev: Dictionary in s.events_active:
		var pc := UIKit.vbox(4)
		v.add_child(UIKit.panel(pc))
		pc.add_child(UIKit.title(str(ev.title), 16))
		pc.add_child(UIKit.label(str(ev.text), UIKit.TEXT_DIM))
		if not bool(ev.resolved):
			var row := UIKit.hbox(8)
			pc.add_child(row)
			var choices: Array = ev.choices
			for i in choices.size():
				var choice: Dictionary = choices[i]
				row.add_child(UIKit.button(str(choice.label), func():
					EventsSim.choose(Game.state, str(ev.id), i)
					_render()))
		else:
			pc.add_child(UIKit.label("%d day(s) remaining" % int(ev.days_left), UIKit.TEXT_DIM, 13))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Recent history:", UIKit.TEXT_DIM))
	var hist: Array = s.events_history
	for h: Dictionary in hist.slice(maxi(0, hist.size() - 12)):
		var def: Dictionary = DataRegistry.events.get(str(h.id), {})
		v.add_child(UIKit.label("Day %d — %s" % [int(h.day), str(def.get("title", h.id))], UIKit.TEXT_DIM, 13))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tablet") or event.is_action_pressed("pause_menu"):
		queue_free()
		get_viewport().set_input_as_handled()

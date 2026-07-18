class_name ComplianceSim
## Compliance rating (0-100), scheduled & surprise audits. Audits inspect
## real state (untested lots, expired stock, security, staffing) rather
## than rolling dice.

const AUDIT_CATEGORIES: PackedStringArray = ["Product testing", "Expiration control",
	"Label accuracy", "Inventory records", "Restricted access", "Security coverage",
	"Employee certifications", "Facility cleanliness", "Order traceability", "Licenses"]


static func daily_update(s: Dictionary) -> void:
	# Gentle drift toward 75 baseline; violations push it down elsewhere.
	var target := 75.0
	s.compliance = clampf(lerpf(float(s.compliance), target, 0.02), 0.0, 100.0)
	# Untested lots on display are a violation risk.
	for lot: Dictionary in s.lots:
		if str(lot.location).begins_with("display:") and not bool(lot.tested):
			s.compliance = maxf(0.0, float(s.compliance) - 2.0)
			EventBus.notify("Untested product on display! Compliance dropped.", "error")
			break
	# Scheduled audit every 30 days; surprise audits occasionally.
	if int(s.day) % 30 == 0 or randf() < 0.03:
		run_audit(s)
	EventBus.compliance_changed.emit(float(s.compliance))


## Inspect actual state per category; returns detailed result and applies
## consequences. Score per category 0-10.
static func run_audit(s: Dictionary) -> Dictionary:
	var scores: Dictionary = {}
	var untested_displayed := 0
	var expired := 0
	for lot: Dictionary in s.lots:
		if not bool(lot.tested) and str(lot.location).begins_with("display:"):
			untested_displayed += 1
		if int(lot.day_expires) <= int(s.day):
			expired += 1
	scores["Product testing"] = 10 if untested_displayed == 0 else maxi(0, 10 - untested_displayed * 4)
	scores["Expiration control"] = 10 if expired == 0 else maxi(0, 10 - expired * 2)
	scores["Label accuracy"] = 10 if Game.has_research("premium_packaging") else 8
	scores["Inventory records"] = 10 if bool(s.auto.reporting) else 7
	var sec := 0.0
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			sec += float(st.security)
	sec /= maxf(1.0, float(s.stores.size()))
	scores["Restricted access"] = clampi(int(sec / 10.0), 3, 10)
	scores["Security coverage"] = clampi(int(sec / 8.0), 3, 10)
	scores["Employee certifications"] = 10 if not StaffSim.by_role(s, "compliance").is_empty() else 6
	scores["Facility cleanliness"] = 9 if StaffSim.by_role(s, "maintenance").size() > 0 else 6
	scores["Order traceability"] = 10  # lot history is always tracked
	scores["Licenses"] = 10 if s.licenses.size() >= 2 else 5
	var total := 0
	for v in scores.values():
		total += int(v)
	var pct := float(total) / (AUDIT_CATEGORIES.size() * 10.0) * 100.0
	var passed := pct >= 70.0
	var result := {"day": s.day, "scores": scores, "pct": pct, "passed": passed}
	if passed:
		s.compliance = minf(100.0, float(s.compliance) + 8.0)
		s.research_points = int(s.research_points) + 2
		EventBus.notify("Audit passed (%.0f%%). +2 Research Points." % pct, "success")
		if pct >= 99.9:
			ObjectivesSim.grant_achievement(s, "ach_perfect_audit")
	else:
		s.compliance = maxf(0.0, float(s.compliance) - 12.0)
		var fine := DataRegistry.bal("audit_fine", 1500.0)
		EconomySim.spend(s, fine, "Compliance fine", "reporting")
		s.trial.violations = int(s.trial.violations) + (1 if s.trial.active else 0)
		EventBus.notify("Audit FAILED (%.0f%%). Fine: $%d." % [pct, int(fine)], "error")
	EventBus.audit_finished.emit(result)
	EventBus.compliance_changed.emit(float(s.compliance))
	return result

extends Node
## Global typed signal hub. All cross-system notifications go through here so
## systems never hold hard references to each other.

# Time
signal minute_passed(day: int, minute: int)
signal hour_passed(day: int, hour: int)
signal day_started(day: int)
signal day_ended(day: int, report: Dictionary)
signal speed_changed(speed: float, paused: bool)

# Economy
signal cash_changed(cash: float, delta: float, reason: String)
signal transaction_logged(entry: Dictionary)

# Production / inventory
signal batch_stage_changed(batch: Dictionary)
signal batch_completed(batch: Dictionary)
signal lot_created(lot: Dictionary)
signal inventory_changed()
signal machine_state_changed(machine_id: String)

# Retail
signal sale_made(store_id: String, product_id: String, price: float, quality: int)
signal customer_feedback(store_id: String, text: String, positive: bool)
signal store_opened(store_id: String)
signal store_closed(store_id: String)

# Staff
signal employee_hired(emp: Dictionary)
signal employee_quit(emp: Dictionary)
signal employee_leveled(emp: Dictionary)

# Campaign / meta
signal stage_advanced(stage: int)
signal objective_completed(obj: Dictionary)
signal achievement_unlocked(ach: Dictionary)
signal research_completed(node: Dictionary)
signal compliance_changed(value: float)
signal reputation_changed(value: float)
signal automation_changed(score: float)
signal audit_finished(result: Dictionary)
signal game_event_fired(ev: Dictionary)
signal trial_started()
signal trial_day_result(result: Dictionary)
signal campaign_won(result: Dictionary)
signal campaign_lost(reason: String, summary: Dictionary)

# UI helpers
signal toast(text: String, kind: String)
signal alert_raised(id: String, text: String, severity: int)
signal alert_cleared(id: String)
signal tutorial_step_changed(step: Dictionary)
signal game_loaded()
signal game_saved(slot: String)


func notify(text: String, kind: String = "info") -> void:
	toast.emit(text, kind)

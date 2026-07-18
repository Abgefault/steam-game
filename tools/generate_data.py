#!/usr/bin/env python3
"""Generates the authoritative game data JSON files in data/.
Run from repo root: python3 tools/generate_data.py
All content is fictional and abstract; no real-world process data."""
import json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(OUT, exist_ok=True)

def write(name, obj):
    with open(os.path.join(OUT, name), "w") as f:
        json.dump(obj, f, indent=1)
    print("wrote", name)

# ---------------------------------------------------------------- strains
strains = [
    {"id": "verdant_dawn", "name": "Verdant Dawn", "yield": 4, "grow_minutes": 220, "tone": "calm"},
    {"id": "citrus_static", "name": "Citrus Static", "yield": 3, "grow_minutes": 260, "tone": "bright"},
    {"id": "moon_garden", "name": "Moon Garden", "yield": 4, "grow_minutes": 300, "tone": "mellow"},
    {"id": "electric_fern", "name": "Electric Fern", "yield": 3, "grow_minutes": 340, "tone": "vivid"},
    {"id": "amber_drift", "name": "Amber Drift", "yield": 5, "grow_minutes": 280, "tone": "warm"},
    {"id": "northern_glass", "name": "Northern Glass", "yield": 2, "grow_minutes": 380, "tone": "crisp"},
]
write("strains.json", {"strains": strains})

# ---------------------------------------------------------------- products
# category, strain, base_cost, retail, prod_minutes, batch, qpot, intensity,
# wellness, trend, shelf, risk, stage, machine_tier, segments, tradeoff
P = []
def prod(id, name, cat, strain, desc, cost, retail, mins, batch, qpot, inten,
         well, trend, shelf, risk, stage, mtier, segs, tradeoff):
    P.append({"id": id, "name": name, "category": cat, "strain": strain,
        "desc": desc, "base_cost": cost, "retail_price": retail,
        "prod_minutes": mins, "batch_size": batch, "quality_potential": qpot,
        "intensity": inten, "wellness": well, "trend": trend,
        "shelf_life_days": shelf, "compliance_risk": risk,
        "stage_required": stage, "machine": "product", "machine_tier": mtier,
        "segments": segs, "tradeoff": tradeoff})

prod("flower_dawn", "Velvet Comet Flower", "flower", "verdant_dawn",
     "The house classic. Reliable, affordable, always in demand.",
     3.2, 9.0, 45, 24, 2, 2, 1, 0.2, 12, 0.1, 1, 1,
     ["budget", "regular"], "Low margin but sells everywhere.")
prod("flower_citrus", "Citrus Static Flower", "flower", "citrus_static",
     "Bright and zesty. A favorite with newcomers.",
     3.8, 11.0, 50, 24, 2, 2, 1, 0.4, 12, 0.1, 1, 1,
     ["newcomer", "budget"], "Slightly slower to produce than Velvet Comet.")
prod("flower_moon", "Moon Garden Reserve", "flower", "moon_garden",
     "Slow-conditioned reserve flower for connoisseurs.",
     6.5, 19.0, 70, 18, 3, 3, 1, 0.3, 10, 0.15, 2, 2,
     ["enthusiast", "premium"], "High margin, short shelf life.")
prod("flower_glass", "Northern Glass Select", "flower", "northern_glass",
     "Crisp, rare, unmistakable. Limited natural yield.",
     9.0, 26.0, 90, 12, 3, 3, 1, 0.5, 9, 0.2, 3, 2,
     ["enthusiast", "premium"], "Tiny batches; input strain is scarce.")
prod("preroll_daily", "Daily Ember Pre-Rolls", "preroll", "verdant_dawn",
     "Five-pack of everyday pre-rolls. The commuter's choice.",
     4.0, 10.5, 40, 30, 1, 2, 0, 0.3, 14, 0.1, 1, 1,
     ["budget", "professional"], "Quality capped at Select.")
prod("preroll_citrus", "Static Sticks", "preroll", "citrus_static",
     "Zingy pre-rolls with a paper twist of citrus flair.",
     4.6, 12.5, 45, 30, 2, 2, 0, 0.5, 14, 0.1, 1, 1,
     ["newcomer", "trend"], "Trend-sensitive demand swings.")
prod("preroll_fern", "Fern Torches", "preroll", "electric_fern",
     "Bold cone pre-rolls for the weekend crowd.",
     5.5, 15.0, 55, 24, 2, 3, 0, 0.6, 14, 0.15, 2, 1,
     ["enthusiast", "trend"], "Strong but polarizing.")
prod("oil_amber", "Amber Drift Oil", "oil", "amber_drift",
     "Smooth dropper-bottle oil for measured evenings.",
     7.0, 21.0, 80, 16, 2, 2, 2, 0.2, 30, 0.15, 2, 2,
     ["wellness", "professional"], "Needs Tier 2 product machine.")
prod("oil_moon", "Moonlight Tincture", "oil", "moon_garden",
     "Premium slow-extracted oil with a silver label.",
     9.5, 29.0, 95, 12, 3, 2, 2, 0.3, 30, 0.15, 3, 2,
     ["wellness", "premium"], "Expensive inputs; wealthy districts only.")
prod("oil_glass", "Glasshouse Concentrate", "oil", "northern_glass",
     "Ultra-refined concentrate for the discerning few.",
     13.0, 39.0, 110, 10, 3, 3, 1, 0.4, 28, 0.25, 4, 3,
     ["enthusiast", "premium"], "Highest compliance scrutiny in the lineup.")
prod("edible_square", "Quiet Harbor Squares", "edible", "verdant_dawn",
     "Gentle chocolate squares in resealable tins.",
     5.0, 14.0, 60, 20, 2, 1, 2, 0.3, 21, 0.1, 2, 1,
     ["newcomer", "wellness"], "Mild — enthusiasts skip it.")
prod("edible_citrus", "Citrus Cloud Gummies", "edible", "citrus_static",
     "Sparkling gummy clouds with a static tingle.",
     5.6, 16.0, 65, 20, 2, 2, 1, 0.6, 21, 0.1, 2, 1,
     ["trend", "newcomer"], "Demand spikes and crashes with trends.")
prod("edible_amber", "Amber Caramels", "edible", "amber_drift",
     "Slow-melt caramels, individually wrapped.",
     6.2, 18.5, 70, 18, 3, 2, 2, 0.3, 25, 0.1, 3, 2,
     ["wellness", "premium"], "Long production time per batch.")
prod("well_balm", "Fern & Field Balm", "wellness", "electric_fern",
     "Herbal recovery balm for desk-weary shoulders.",
     6.8, 20.0, 75, 16, 2, 0, 3, 0.2, 40, 0.05, 2, 2,
     ["wellness", "professional"], "Zero intensity — no enthusiast appeal.")
prod("well_drops", "Morning Meadow Drops", "wellness", "amber_drift",
     "Daily wellness drops with a sunrise-yellow label.",
     7.4, 23.0, 80, 14, 3, 0, 3, 0.2, 40, 0.05, 3, 2,
     ["wellness"], "Premium shelf appeal required to move.")
prod("well_patch", "Quiet Harbor Patches", "wellness", "moon_garden",
     "Slow-release comfort patches, 8-pack.",
     8.0, 25.0, 85, 14, 2, 1, 3, 0.2, 45, 0.1, 4, 3,
     ["wellness", "professional"], "Needs Tier 3 machine and stage 4.")
prod("bev_tea", "Moon Garden Tea", "beverage", "moon_garden",
     "Loose-leaf calm in a hexagonal tin.",
     4.4, 13.0, 55, 22, 2, 1, 2, 0.3, 35, 0.05, 2, 1,
     ["wellness", "newcomer"], "Bulky stock; ties up shelf space.")
prod("bev_spark", "Static Spark Soda", "beverage", "citrus_static",
     "Lightly fizzy citrus soda in a retro can.",
     4.8, 14.0, 60, 24, 2, 1, 1, 0.7, 28, 0.1, 3, 2,
     ["trend", "newcomer"], "Trend darling — volatile.")
prod("bev_glow", "Evening Glow Cordial", "beverage", "amber_drift",
     "Amber cordial served over ice at better parties.",
     6.0, 18.0, 70, 18, 3, 2, 1, 0.5, 30, 0.1, 4, 2,
     ["premium", "trend"], "Arts Quarter loves it; suburbs shrug.")
prod("lim_comet", "Comet Trail Limited", "limited", "verdant_dawn",
     "Numbered tins celebrating the company's rebirth.",
     8.0, 27.0, 100, 10, 3, 2, 1, 0.9, 8, 0.2, 3, 2,
     ["trend", "enthusiast"], "Huge spike appeal, brutal expiry risk.")
prod("lim_aurora", "Aurora Batch No.7", "limited", "northern_glass",
     "A one-off aurora-labeled collector run.",
     11.0, 36.0, 120, 8, 3, 3, 1, 1.0, 8, 0.25, 4, 3,
     ["enthusiast", "premium"], "Sells out or spoils — nothing between.")
prod("lim_solstice", "Solstice Reserve", "limited", "moon_garden",
     "Seasonal reserve with hand-stamped labels.",
     9.0, 30.0, 110, 10, 3, 2, 2, 0.8, 9, 0.2, 4, 2,
     ["premium", "wellness"], "Only worth it near seasonal peaks.")
prod("flower_fern", "Electric Fern Flower", "flower", "electric_fern",
     "Vivid green flower with an electric aroma.",
     4.4, 13.0, 55, 20, 2, 3, 0, 0.5, 11, 0.15, 2, 1,
     ["enthusiast", "trend"], "Strong intensity limits newcomer sales.")
prod("preroll_moon", "Moonlit Minis", "preroll", "moon_garden",
     "Elegant mini pre-rolls in a slide-out case.",
     5.8, 16.5, 60, 20, 3, 2, 1, 0.4, 13, 0.1, 3, 2,
     ["premium", "professional"], "Premium positioning or bust.")
prod("edible_glass", "Glass Petal Mints", "edible", "northern_glass",
     "Crystal-clear mints, two per tin.",
     7.5, 24.0, 85, 12, 3, 1, 2, 0.5, 30, 0.15, 4, 3,
     ["premium", "professional"], "Financial Center exclusive appeal.")
prod("bev_harbor", "Harbor Chai Latte Kit", "beverage", "verdant_dawn",
     "Brew-at-home chai kit with oat creamer sachets.",
     5.2, 15.5, 65, 18, 2, 1, 2, 0.4, 26, 0.05, 3, 1,
     ["wellness", "newcomer"], "Kit assembly slows the line.")
write("products.json", {"products": P})

# ---------------------------------------------------------------- districts
districts = [
    {"id": "old_market", "name": "Old Market", "rent": 180, "traffic": 0.55,
     "store_cost": 0, "season_phase": 0.0,
     "desc": "Low rent, balanced traffic, price-sensitive starting customers.",
     "archetype_weights": {"budget": 3, "newcomer": 2, "regular": 2, "tourist": 1,
                           "professional": 1, "wellness": 0.5, "enthusiast": 0.5, "trend": 0.5}},
    {"id": "university_row", "name": "University Row", "rent": 320, "traffic": 0.85,
     "store_cost": 55000, "season_phase": 1.6,
     "desc": "High foot traffic, affordable-product demand, low queue tolerance.",
     "archetype_weights": {"budget": 3, "newcomer": 3, "trend": 2, "tourist": 1,
                           "regular": 1, "professional": 0.5, "wellness": 0.5, "enthusiast": 1}},
    {"id": "wellness_heights", "name": "Wellness Heights", "rent": 650, "traffic": 0.5,
     "store_cost": 95000, "season_phase": 3.1,
     "desc": "Wealthy wellness customers, high quality expectations, expensive rent.",
     "archetype_weights": {"wellness": 4, "professional": 2, "premiumseeker": 0,
                           "regular": 1, "newcomer": 1, "enthusiast": 0.5, "budget": 0.3, "trend": 0.7, "tourist": 0.5}},
    {"id": "arts_quarter", "name": "Arts Quarter", "rent": 420, "traffic": 0.7,
     "store_cost": 75000, "season_phase": 4.4,
     "desc": "Trend-driven customers, strong branding response, volatile demand.",
     "archetype_weights": {"trend": 4, "enthusiast": 2, "tourist": 2, "newcomer": 1,
                           "budget": 1, "regular": 1, "wellness": 1, "professional": 0.5}},
    {"id": "financial_center", "name": "Financial Center", "rent": 900, "traffic": 0.6,
     "store_cost": 140000, "season_phase": 5.5,
     "desc": "Premium demand, time-sensitive customers, highest rent, strictest inspections.",
     "archetype_weights": {"professional": 4, "enthusiast": 1.5, "wellness": 1.5,
                           "regular": 1, "tourist": 0.5, "trend": 0.5, "budget": 0.2, "newcomer": 0.5}},
]
write("districts.json", {"districts": districts})

# ---------------------------------------------------------------- customers
archetypes = [
    {"id": "budget", "name": "Budget Shopper", "budget": 16, "categories": ["flower", "preroll"],
     "quality_expectation": 0.4, "price_sensitivity": 0.9, "queue_tolerance": 0.6,
     "trend_sensitivity": 0.1, "wellness_focus": 0.1, "extra_purchase": 0.1},
    {"id": "newcomer", "name": "Curious Newcomer", "budget": 24, "categories": ["edible", "beverage", "preroll"],
     "quality_expectation": 0.8, "price_sensitivity": 0.5, "queue_tolerance": 0.7,
     "trend_sensitivity": 0.4, "wellness_focus": 0.3, "extra_purchase": 0.2},
    {"id": "wellness", "name": "Wellness Customer", "budget": 45, "categories": ["wellness", "oil", "beverage"],
     "quality_expectation": 1.8, "price_sensitivity": 0.3, "queue_tolerance": 0.8,
     "trend_sensitivity": 0.2, "wellness_focus": 1.0, "extra_purchase": 0.3},
    {"id": "enthusiast", "name": "Enthusiast", "budget": 55, "categories": ["flower", "oil", "limited"],
     "quality_expectation": 2.2, "price_sensitivity": 0.2, "queue_tolerance": 0.9,
     "trend_sensitivity": 0.5, "wellness_focus": 0.1, "extra_purchase": 0.4},
    {"id": "trend", "name": "Trend Seeker", "budget": 38, "categories": ["limited", "beverage", "edible"],
     "quality_expectation": 1.2, "price_sensitivity": 0.4, "queue_tolerance": 0.4,
     "trend_sensitivity": 1.0, "wellness_focus": 0.2, "extra_purchase": 0.35},
    {"id": "professional", "name": "Busy Professional", "budget": 50, "categories": ["oil", "wellness", "preroll"],
     "quality_expectation": 1.6, "price_sensitivity": 0.25, "queue_tolerance": 0.2,
     "trend_sensitivity": 0.2, "wellness_focus": 0.5, "extra_purchase": 0.25},
    {"id": "regular", "name": "Loyal Regular", "budget": 30, "categories": ["flower", "preroll", "edible"],
     "quality_expectation": 1.0, "price_sensitivity": 0.5, "queue_tolerance": 0.8,
     "trend_sensitivity": 0.2, "wellness_focus": 0.2, "extra_purchase": 0.3},
    {"id": "tourist", "name": "Tourist", "budget": 34, "categories": ["limited", "preroll", "edible"],
     "quality_expectation": 0.9, "price_sensitivity": 0.4, "queue_tolerance": 0.7,
     "trend_sensitivity": 0.6, "wellness_focus": 0.2, "extra_purchase": 0.5},
]
write("customers.json", {"archetypes": archetypes})

# ---------------------------------------------------------------- events
E = []
def ev(id, title, text, duration=1, cooldown=25, requires=None, effects=None, choices=None):
    E.append({"id": id, "title": title, "text": text, "duration": duration,
              "cooldown": cooldown, "requires": requires or {},
              "effects": effects or {}, "choices": choices or []})

ev("influencer", "Influencer Recommendation",
   "A city influencer posted about your store. Foot traffic surges for two days.",
   2, 30, {"min_day": 5}, {"traffic_mult": 1.5, "reputation": 3})
ev("viral_negative", "Viral Negative Review",
   "A harsh review is trending. Respond publicly or ride it out?",
   2, 35, {"min_day": 8},
   choices=[{"label": "Public apology + free samples ($800)", "cost": 800,
             "effects": {"reputation": 4}},
            {"label": "Ignore it", "effects": {"reputation": -6, "traffic_mult": 0.85}}])
ev("festival", "Festival Weekend",
   "The city festival floods the streets. All districts see more shoppers.",
   3, 28, {"min_day": 10}, {"traffic_mult": 1.4})
ev("exams", "University Exams",
   "Exam season empties University Row but boosts calm wellness products.",
   4, 30, {"min_day": 12}, {"category_demand": {"wellness": 1.3, "preroll": 0.8}})
ev("wellness_conv", "Wellness Convention",
   "A wellness convention is in town. Wellness Heights demand spikes.",
   3, 30, {"min_day": 15}, {"category_demand": {"wellness": 1.5, "oil": 1.3}})
ev("supplier_shortage", "Supplier Shortage",
   "A supplier cooperative reports shortages. Input prices climb this week.",
   4, 26, {}, {"supplier_price_mult": 1.5})
ev("packaging_rules", "Packaging Rule Update",
   "The city updated packaging rules. Adapt immediately or risk compliance.",
   1, 40, {"min_day": 20},
   choices=[{"label": "Retool packaging ($1,200)", "cost": 1200, "effects": {"compliance": 6}},
            {"label": "Delay adaptation", "effects": {"compliance": -8}}])
ev("utility_surge", "Utility Price Surge",
   "Energy prices spike citywide. Utilities cost more for a few days.",
   3, 24, {}, {"utility_mult": 1.6})
ev("competitor_discount", "Competitor Discount Campaign",
   "A rival chain slashes prices. Price-sensitive customers wander off.",
   3, 26, {"min_day": 14}, {"traffic_mult": 0.85})
ev("recall", "Product Recall Scare",
   "A supplier upstream issued a recall. Prove your lot tracking is clean.",
   1, 45, {"min_day": 25}, {"audit": True})
ev("staff_illness", "Staff Illness Wave",
   "A cold wave hits the team. Morale and energy dip.",
   2, 22, {"min_staff": 2}, {"staff_morale": -8})
ev("equipment_failure", "Equipment Failure",
   "A power spike damaged a machine on the floor.",
   1, 20, {"min_day": 6}, {"damage_machine": 30})
ev("surprise_audit", "Surprise Audit",
   "City inspectors walked in unannounced.",
   1, 35, {"min_day": 18}, {"audit": True})
ev("tourism_boom", "Tourism Boom",
   "A travel magazine featured Verdantia. Tourists everywhere.",
   4, 30, {"min_day": 20}, {"traffic_mult": 1.3, "category_demand": {"limited": 1.4}})
ev("construction", "District Construction",
   "Roadworks choke a district. Deliveries and foot traffic slow down.",
   4, 28, {"min_day": 16}, {"traffic_mult": 0.8})
ev("charity", "Charity Opportunity",
   "The Verdantia Youth Fund asks for a sponsorship.",
   1, 40, {"min_day": 10},
   choices=[{"label": "Donate $2,000", "cost": 2000, "effects": {"reputation": 8}},
            {"label": "Politely decline", "effects": {"reputation": -1}}])
ev("input_auction", "Limited Input Auction",
   "A rare lot of Northern Glass inputs is on auction.",
   1, 35, {"min_stage": 3},
   choices=[{"label": "Bid $3,000", "cost": 3000, "effects": {"research_points": 1, "cash": 0}},
            {"label": "Skip the auction", "effects": {}}])
ev("landlord", "Landlord Negotiation",
   "Your landlord offers a deal: prepay rent for a discount.",
   1, 45, {"min_day": 30},
   choices=[{"label": "Prepay $2,500 now", "cost": 2500, "effects": {"cash": 500}},
            {"label": "Keep monthly terms", "effects": {}}])
ev("data_outage", "Data-System Outage",
   "The city data network hiccups. Remote systems fall back to local mode.",
   1, 30, {"min_stage": 3}, {"traffic_mult": 0.95})
ev("delivery_delay", "Delivery Delay",
   "A highway closure delays supplier deliveries this week.",
   3, 25, {}, {"supplier_price_mult": 1.25})
ev("heat_wave", "Heat Wave",
   "A heat wave rolls in: beverages boom, machines strain.",
   3, 30, {}, {"category_demand": {"beverage": 1.5}, "utility_mult": 1.3})
ev("employee_dispute", "Employee Dispute",
   "Two team members clash over shift priorities.",
   1, 25, {"min_staff": 3},
   choices=[{"label": "Mediate personally (morale +)", "effects": {"staff_morale": 6}},
            {"label": "Let them sort it out", "effects": {"staff_morale": -6}}])
ev("investor", "Investor Offer",
   "An investor offers quick cash for a slice of future goodwill.",
   1, 60, {"min_stage": 3},
   choices=[{"label": "Accept $15,000 (reputation -5)", "effects": {"cash": 15000, "reputation": -5}},
            {"label": "Stay independent (reputation +2)", "effects": {"reputation": 2}}])
ev("sustain_grant", "Sustainability Grant",
   "The city grants efficient operators a sustainability bonus.",
   1, 50, {"min_stage": 2}, {"cash": 4000, "reputation": 3})
ev("new_competitor", "New Competitor Opening",
   "A flashy competitor opened across town.",
   5, 40, {"min_day": 35}, {"traffic_mult": 0.9})
ev("news_interview", "Local News Interview",
   "A journalist wants a tour of your facility.",
   1, 45, {"min_stage": 2},
   choices=[{"label": "Give the tour", "effects": {"reputation": 5, "audit": True}},
            {"label": "Decline politely", "effects": {}}])
ev("rain_week", "Grey Rain Week",
   "A week of drizzle keeps casual shoppers home.",
   4, 26, {}, {"traffic_mult": 0.88})
ev("food_fair", "Street Food Fair",
   "A food fair beside Old Market spills hungry crowds into your store.",
   2, 30, {}, {"category_demand": {"edible": 1.4, "beverage": 1.2}})
ev("marathon", "City Marathon",
   "Marathon day: wellness products surge, roads close.",
   1, 40, {"min_day": 22}, {"category_demand": {"wellness": 1.6}, "traffic_mult": 0.9})
ev("art_opening", "Gallery Opening Night",
   "The Arts Quarter celebrates. Limited editions are the ticket.",
   1, 30, {"min_day": 18}, {"category_demand": {"limited": 1.8}})
ev("power_deal", "Green Power Deal",
   "A co-op offers discounted clean power for a signup fee.",
   1, 60, {"min_stage": 2},
   choices=[{"label": "Sign up ($1,500)", "cost": 1500, "effects": {"utility_mult": 0.7}},
            {"label": "Pass", "effects": {}}])
ev("bulk_seed_offer", "Bulk Input Offer",
   "A supplier clears warehouse space: discounted seed kits today.",
   1, 30, {},
   choices=[{"label": "Buy 4 kits ($350)", "cost": 350, "effects": {}},
            {"label": "Decline", "effects": {}}])
ev("mystery_shopper", "Mystery Shopper",
   "The retail association sent a mystery shopper. Results go public.",
   1, 35, {"min_day": 15}, {"reputation": 2})
ev("printing_error", "Label Printing Error",
   "A misprint batch slipped through. Fix labels before inspectors notice.",
   1, 35, {"min_day": 20},
   choices=[{"label": "Relabel stock ($600)", "cost": 600, "effects": {"compliance": 3}},
            {"label": "Risk it", "effects": {"compliance": -7}}])
ev("radio_feature", "Radio Feature",
   "A local radio host praised your storefront rebrand.",
   2, 35, {"min_stage": 2}, {"reputation": 4, "traffic_mult": 1.15})
ev("cold_snap", "Cold Snap",
   "Freezing days push customers toward teas and edibles.",
   3, 28, {}, {"category_demand": {"beverage": 1.35, "edible": 1.2}})
ev("supplier_bonus", "Supplier Loyalty Bonus",
   "Your steady orders earned a supplier credit.",
   1, 45, {"min_day": 30}, {"cash": 1200})
ev("intern_program", "Intern Program",
   "The university proposes an intern program.",
   1, 60, {"min_stage": 3},
   choices=[{"label": "Host interns ($500)", "cost": 500, "effects": {"research_points": 2}},
            {"label": "Decline", "effects": {}}])
ev("night_market", "Night Market License",
   "Verdantia trials night markets. Extended hours, extra staff strain.",
   2, 45, {"min_stage": 3}, {"traffic_mult": 1.25, "staff_morale": -4})
ev("tax_rebate", "Efficiency Tax Rebate",
   "The city rebates part of your taxes for efficient operation.",
   1, 55, {"min_stage": 4}, {"cash": 6000})
ev("blackout", "Rolling Blackout",
   "A rolling blackout stalls part of the grid for a day.",
   1, 40, {"min_day": 28}, {"utility_mult": 1.8, "damage_machine": 15})
ev("street_art", "Street Art Collab",
   "A famous muralist offers to paint your storefront.",
   1, 60, {"min_stage": 2},
   choices=[{"label": "Commission mural ($1,800)", "cost": 1800,
             "effects": {"reputation": 6}},
            {"label": "Decline", "effects": {}}])
write("events.json", {"events": E})

# ---------------------------------------------------------------- research
R = []
def rs(id, name, branch, cost_rp, desc, requires=None, stage=1, cost_cash=0):
    R.append({"id": id, "name": name, "branch": branch, "cost_rp": cost_rp,
              "cost_cash": cost_cash, "desc": desc,
              "requires": requires or [], "stage": stage})

# Production branch
rs("fast_processing", "Streamlined Processing", "production", 2,
   "All machines run 15% faster.")
rs("quality_consistency", "Quality Consistency", "production", 3,
   "Batches roll higher, steadier quality.", ["fast_processing"])
rs("durable_parts", "Durable Components", "production", 3,
   "Machines wear 40% slower.", ["fast_processing"])
rs("large_buffers", "Extended Buffers", "production", 4,
   "Machines hold larger input/output buffers.", ["durable_parts"], 2)
rs("lab_protocols", "Laboratory Protocols", "production", 4,
   "Lab testing is faster and grants the testing license.", ["quality_consistency"], 2)
rs("efficient_power", "Efficient Power Systems", "production", 5,
   "Machinery consumes less power.", ["large_buffers"], 3)
rs("pilot_lines", "Pilot Production Lines", "production", 6,
   "Unlocks Tier 4+ machine upgrades.", ["efficient_power"], 4)
# Automation branch
rs("conveyors", "Conveyor Systems", "automation", 3,
   "Build conveyors that move outputs between machines automatically.", [], 2, 2000)
rs("belt_filters", "Belt Filters & Splitters", "automation", 4,
   "Conveyor routing rules by product and quality.", ["conveyors"], 3)
rs("robotic_arms", "Robotic Transfer Arms", "automation", 5,
   "Machines auto-feed from connected buffers.", ["belt_filters"], 3)
rs("auto_labeling", "Automatic Labeling", "automation", 4,
   "Packaging machines label without manual work.", ["conveyors"], 3)
rs("asrs", "Automated Storage & Retrieval", "automation", 6,
   "Warehouse racks store and pick lots automatically.", ["robotic_arms"], 4)
rs("central_scheduling", "Central Production Scheduling", "automation", 6,
   "A planning terminal schedules production automatically.", ["asrs"], 4)
rs("predictive_maintenance", "Predictive Maintenance", "automation", 7,
   "Machines report wear before failing.", ["central_scheduling"], 5)
# Retail branch
rs("staff_training", "Staff Training Program", "retail", 2,
   "New hires start more skilled; XP gain doubled.")
rs("loyalty_program", "Loyalty Program", "retail", 4,
   "Happy customers become regulars twice as often.", ["staff_training"], 2)
rs("premium_displays", "Premium Display Cases", "retail", 4,
   "Store appeal rises; premium products sell better.", ["staff_training"], 2)
rs("remote_store_mgmt", "Remote Store Management", "retail", 5,
   "Store managers run day-to-day operations remotely.", ["loyalty_program"], 3)
rs("auto_replenishment", "Automatic Replenishment", "retail", 5,
   "Stores restock from the warehouse automatically.", ["remote_store_mgmt"], 3)
rs("brand_studio", "In-House Brand Studio", "retail", 6,
   "Marketing campaigns cost less and reach further.", ["premium_displays"], 4)
# Logistics branch
rs("route_planning", "Route Planning", "logistics", 2,
   "Transfers between locations are cheaper.")
rs("fleet_upgrade", "Fleet Upgrade", "logistics", 4,
   "Bigger vans: transfer capacity doubles.", ["route_planning"], 2)
rs("auto_purchasing", "Scheduled Supplier Purchasing", "logistics", 4,
   "Supplies reorder themselves below thresholds.", ["route_planning"], 2)
rs("demand_forecasting", "Demand Forecasting", "logistics", 6,
   "Market screen predicts demand; smarter auto-restock.", ["auto_purchasing"], 4)
rs("cold_chain", "Cold Chain Logistics", "logistics", 5,
   "Shelf life of delivered goods +25%.", ["fleet_upgrade"], 3)
rs("wholesale_license", "Wholesale Operations", "logistics", 5,
   "Unlocks the logistics license and wholesale orders.", ["fleet_upgrade"], 3)
# Brand & Compliance branch
rs("compliance_office", "Compliance Office", "brand", 3,
   "Compliance drifts upward; audit prep is easier.")
rs("audit_prep", "Audit Preparation Kits", "brand", 4,
   "Scheduled audits score one category higher.", ["compliance_office"], 2)
rs("premium_packaging", "Premium Packaging", "brand", 4,
   "Label accuracy is guaranteed; brand appeal up.", ["compliance_office"], 2)
rs("shelf_life_tech", "Modified Atmosphere Packs", "brand", 5,
   "All product shelf life +20%.", ["premium_packaging"], 3)
rs("advanced_analytics", "Advanced Analytics Suite", "brand", 6,
   "Financial reporting runs itself; deep dashboards.", ["audit_prep"], 4)
rs("maintenance_scheduling", "Maintenance Scheduling", "brand", 4,
   "Enable automatic maintenance policies.", ["compliance_office"], 2)
rs("city_relations", "City Relations Office", "brand", 7,
   "Reputation floor raised; inspectors are friendlier.", ["advanced_analytics"], 5)
write("research.json", {"research": R})

# ---------------------------------------------------------------- objectives
O = []
def ob(id, name, kind, desc, condition, rewards=None):
    O.append({"id": id, "name": name, "kind": kind, "desc": desc,
              "condition": condition, "rewards": rewards or {}})

# Tutorial chain (contextual onboarding, checked against real actions)
ob("tut_move", "Find Your Feet", "tutorial",
   "Walk through the facility (WASD, mouse to look).", {"day": 1})
ob("tut_tablet", "Open the Tablet", "tutorial",
   "Press TAB and skim the Company Overview.", {"tutorial_done": 0})
ob("tut_batch", "First Batch", "tutorial",
   "Load and start the Cultivation Module.", {"batches_completed": 0})
ob("tut_condition", "Condition the Harvest", "tutorial",
   "Run harvest containers through the Conditioning Unit.", {"batches_completed": 0})
ob("tut_lab", "Test It", "tutorial",
   "Test a batch in the Quality Laboratory.", {"lot_count": 1})
ob("tut_package", "Package It", "tutorial",
   "Package a tested batch into a finished lot.", {"lot_count": 1})
ob("tut_stock", "Stock the Shelf", "tutorial",
   "Move packaged product onto the store display.", {"units_sold": 1})
ob("tut_price", "Set a Price", "tutorial",
   "Review pricing on the tablet's Products page.", {"units_sold": 1})
ob("tut_open", "Open the Store", "tutorial",
   "Open your storefront to customers.", {"customers_served": 1})
ob("tut_sale", "First Sale", "tutorial",
   "Sell your first product.", {"units_sold": 1}, {"cash": 200})
ob("tut_report", "Read the Daily Report", "tutorial",
   "Finish a day and read the report.", {"day": 2})
ob("tut_hire", "First Hire", "tutorial",
   "Hire your first employee.", {"staff_count": 1}, {"research_points": 1})
ob("tut_save", "Safety First", "tutorial",
   "Save the game (F5 quicksaves).", {"day": 2})
# Regular objectives (30+)
ob("obj_first_1k", "Pocket Money", "regular", "Hold $13,000 cash.", {"cash": 13000}, {"research_points": 1})
ob("obj_sell_50", "Fifty Sales", "regular", "Sell 50 units.", {"units_sold": 50}, {"cash": 500})
ob("obj_sell_250", "Steady Trade", "regular", "Sell 250 units.", {"units_sold": 250}, {"research_points": 2})
ob("obj_sell_1000", "Volume Dealer", "regular", "Sell 1,000 units.", {"units_sold": 1000}, {"research_points": 3})
ob("obj_batch_5", "Production Rhythm", "regular", "Complete 5 batches.", {"batches_completed": 5}, {"cash": 400})
ob("obj_batch_25", "Line Cook", "regular", "Complete 25 batches.", {"batches_completed": 25}, {"research_points": 2})
ob("obj_batch_100", "Factory Floor", "regular", "Complete 100 batches.", {"batches_completed": 100}, {"research_points": 3})
ob("obj_day5k", "Earn $5,000 in one day", "regular", "Have a $5,000-profit day.", {"best_day_profit": 5000}, {"research_points": 2})
ob("obj_staff_3", "Small Team", "regular", "Employ 3 people.", {"staff_count": 3}, {"cash": 600})
ob("obj_staff_8", "Growing Team", "regular", "Employ 8 people.", {"staff_count": 8}, {"research_points": 2})
ob("obj_rep_50", "Known in Town", "regular", "Reach 50 reputation.", {"reputation": 50}, {"cash": 800})
ob("obj_rep_80", "City Favorite", "regular", "Reach 80 reputation.", {"reputation": 80}, {"research_points": 3})
ob("obj_comp_80", "Clean House", "regular", "Reach 80 compliance.", {"compliance": 80}, {"research_points": 2})
ob("obj_stage_2", "Small Business", "regular", "Reach company stage 2.", {"stage": 2}, {"cash": 1000})
ob("obj_stage_3", "Local Supplier", "regular", "Reach company stage 3.", {"stage": 3}, {"research_points": 2})
ob("obj_stage_4", "Industrial Operation", "regular", "Reach company stage 4.", {"stage": 4}, {"research_points": 3})
ob("obj_stage_5", "Citywide Company", "regular", "Reach company stage 5.", {"stage": 5}, {"research_points": 4})
ob("obj_stage_6", "Contract Contender", "regular", "Reach company stage 6.", {"stage": 6}, {"research_points": 5})
ob("obj_research_5", "R&D Habit", "regular", "Complete 5 research projects.", {"research_count": 5}, {"cash": 1500})
ob("obj_research_15", "Innovation Engine", "regular", "Complete 15 research projects.", {"research_count": 15}, {"research_points": 3})
ob("obj_conveyor_1", "First Conveyor", "regular", "Build a conveyor connection.", {"conveyor_count": 1}, {"research_points": 2})
ob("obj_conveyor_5", "Connected Factory", "regular", "Run 5 conveyor connections.", {"conveyor_count": 5}, {"research_points": 3})
ob("obj_auto_25", "Hands Off (25%)", "regular", "Reach 25% automation.", {"automation": 25}, {"research_points": 2})
ob("obj_auto_50", "Hands Off (50%)", "regular", "Reach 50% automation.", {"automation": 50}, {"research_points": 3})
ob("obj_auto_85", "Hands Off (85%)", "regular", "Reach 85% automation.", {"automation": 85}, {"research_points": 4})
ob("obj_val_100k", "Six Figures", "regular", "Reach $100,000 valuation.", {"valuation": 100000}, {"research_points": 2})
ob("obj_val_500k", "Half a Million", "regular", "Reach $500,000 valuation.", {"valuation": 500000}, {"research_points": 3})
ob("obj_val_1m", "Millionaire on Paper", "regular", "Reach $1,000,000 valuation.", {"valuation": 1000000}, {"research_points": 4})
ob("obj_store_2", "Second Location", "regular", "Own 2 stores.", {"stores_owned": 2}, {"cash": 3000})
ob("obj_store_3", "Retail Network", "regular", "Own 3 profitable stores.", {"stores_profitable": 3}, {"research_points": 4})
ob("obj_loan", "Debt Free", "regular", "Repay the startup loan.", {"loan_repaid": 1}, {"reputation": 5})
ob("obj_premium", "Premium Craft", "regular", "Produce a Premium-quality lot.", {"premium_batch": 1}, {"research_points": 2})
ob("obj_tier3", "Modern Machinery", "regular", "Upgrade 3 machines to Tier 3.", {"machines_tier3": 3}, {"research_points": 3})
ob("obj_serve_500", "Familiar Faces", "regular", "Serve 500 customers.", {"customers_served": 500}, {"cash": 2000})
# Challenge objectives (15+)
ob("ch_day30_profit", "Fast Start", "challenge", "Reach $30,000 cash by day 30.", {"cash": 30000}, {"research_points": 3})
ob("ch_exceptional", "Produce an Exceptional batch", "challenge", "Roll an Exceptional-quality lot.", {"exceptional_batch": 1}, {"research_points": 3})
ob("ch_no_waste", "Zero Waste Week", "challenge", "Serve 200 customers with no expired stock.", {"customers_served": 200}, {"research_points": 2})
ob("ch_rep90", "Beloved Brand", "challenge", "Reach 90 reputation.", {"reputation": 90}, {"research_points": 4})
ob("ch_comp95", "Spotless", "challenge", "Reach 95 compliance.", {"compliance": 95}, {"research_points": 3})
ob("ch_auto95", "Ghost Factory", "challenge", "Reach 95% automation.", {"automation": 95}, {"research_points": 5})
ob("ch_auto100", "Full Autonomy", "challenge", "Reach 100% automation.", {"automation": 100}, {"research_points": 6})
ob("ch_val2m", "Two Million", "challenge", "Reach $2,000,000 valuation.", {"valuation": 2000000}, {"research_points": 4})
ob("ch_staff12", "Full Payroll", "challenge", "Employ 12 people at once.", {"staff_count": 12}, {"research_points": 3})
ob("ch_batches200", "Production Marathon", "challenge", "Complete 200 batches.", {"batches_completed": 200}, {"research_points": 4})
ob("ch_sales5000", "Citywide Supplier", "challenge", "Sell 5,000 units.", {"units_sold": 5000}, {"research_points": 4})
ob("ch_research25", "Think Tank", "challenge", "Complete 25 research projects.", {"research_count": 25}, {"research_points": 5})
ob("ch_conveyor10", "Belt Empire", "challenge", "Run 10 conveyor connections.", {"conveyor_count": 10}, {"research_points": 4})
ob("ch_day10k", "Golden Day", "challenge", "Bank $10,000 profit in one day.", {"best_day_profit": 10000}, {"research_points": 4})
ob("ch_serve2000", "Household Name", "challenge", "Serve 2,000 customers.", {"customers_served": 2000}, {"research_points": 4})
ob("ch_win", "Win the Contract", "challenge", "Win the Verdantia City Supply Contract.", {"trial_won": 1}, {})
write("objectives.json", {"objectives": O})

# ---------------------------------------------------------------- achievements
A = []
def ach(id, name, desc, condition):
    A.append({"id": id, "name": name, "desc": desc, "condition": condition})

ach("ach_first_batch", "Green Thumb", "Complete your first batch.", {"batches_completed": 1})
ach("ach_first_sale", "Open for Business", "Sell your first product.", {"units_sold": 1})
ach("ach_first_hire", "Now We're a Team", "Hire your first employee.", {"staff_count": 1})
ach("ach_sell_100", "Hundred Club", "Sell 100 units.", {"units_sold": 100})
ach("ach_sell_1000", "Thousand Club", "Sell 1,000 units.", {"units_sold": 1000})
ach("ach_sell_10000", "Ten Thousand Strong", "Sell 10,000 units.", {"units_sold": 10000})
ach("ach_batch_50", "Batch Master", "Complete 50 batches.", {"batches_completed": 50})
ach("ach_stage_3", "Local Supplier", "Reach stage 3.", {"stage": 3})
ach("ach_stage_5", "Citywide Company", "Reach stage 5.", {"stage": 5})
ach("ach_stage_6", "Contract Contender", "Reach stage 6.", {"stage": 6})
ach("ach_auto_50", "Half Machine", "Reach 50% automation.", {"automation": 50})
ach("ach_auto_85", "Automation Architect", "Reach 85% automation.", {"automation": 85})
ach("ach_auto_100", "The Invisible Hand", "Reach 100% automation.", {"automation": 100})
ach("ach_rep_80", "Talk of the Town", "Reach 80 reputation.", {"reputation": 80})
ach("ach_comp_90", "By the Book", "Reach 90 compliance.", {"compliance": 90})
ach("ach_loan", "Unchained", "Repay the startup loan.", {"loan_repaid": 1})
ach("ach_store_3", "Chain Reaction", "Own 3 stores.", {"stores_owned": 3})
ach("ach_val_1m", "Paper Millionaire", "Reach $1M valuation.", {"valuation": 1000000})
ach("ach_val_25m", "Qualified", "Reach $2.5M valuation.", {"valuation": 2500000})
ach("ach_premium", "Fine Craft", "Produce a Premium lot.", {"premium_batch": 1})
ach("ach_exceptional", "Perfection", "Produce an Exceptional lot.", {"exceptional_batch": 1})
ach("ach_research_10", "Lab Coat Energy", "Finish 10 research projects.", {"research_count": 10})
ach("ach_staff_10", "Two Digits", "Employ 10 people.", {"staff_count": 10})
ach("ach_serve_1000", "People Person", "Serve 1,000 customers.", {"customers_served": 1000})
ach("ach_conveyors", "Keep It Rolling", "Run 5 conveyor connections.", {"conveyor_count": 5})
ach("ach_perfect_audit", "Immaculate", "Pass an audit with a perfect score.", {"day": 99999})
ach("ach_win_campaign", "Verdantia's Choice", "Win the city supply contract.", {"day": 99999})
write("achievements.json", {"achievements": A})

# ---------------------------------------------------------------- machines
machines = [
    {"id": "cultivation", "name": "Cultivation Module", "slot": "cultivation",
     "tiers": [{"cost": 0, "desc": "Primitive module, slow and thirsty."},
               {"cost": 6000, "desc": "Sealed module with stable cycles."},
               {"cost": 18000, "desc": "Racked modules with sensor feedback."},
               {"cost": 45000, "desc": "Automated vertical module wall."},
               {"cost": 95000, "desc": "Industrial module hall segment."}]},
    {"id": "conditioning", "name": "Conditioning Unit", "slot": "conditioning",
     "tiers": [{"cost": 0, "desc": "A repurposed drying cabinet."},
               {"cost": 5000, "desc": "Calibrated conditioning cabinet."},
               {"cost": 15000, "desc": "Twin-chamber conditioning line."},
               {"cost": 38000, "desc": "Continuous-flow conditioning tunnel."},
               {"cost": 80000, "desc": "Climate-managed conditioning hall."}]},
    {"id": "processing", "name": "Processing Machine", "slot": "processing",
     "tiers": [{"cost": 0, "desc": "Hand-fed processor, temperamental."},
               {"cost": 7000, "desc": "Bench processor with feed hopper."},
               {"cost": 20000, "desc": "Enclosed processing station."},
               {"cost": 50000, "desc": "Dual-line processing cell."},
               {"cost": 105000, "desc": "Automated processing suite."}]},
    {"id": "lab", "name": "Quality Laboratory", "slot": "lab",
     "tiers": [{"cost": 0, "desc": "A microscope and stubborn optimism."},
               {"cost": 8000, "desc": "Certified test bench."},
               {"cost": 22000, "desc": "Accredited lab station."},
               {"cost": 52000, "desc": "Automated sample handling."},
               {"cost": 110000, "desc": "Full digital QA laboratory."}]},
    {"id": "product", "name": "Product Machine", "slot": "product",
     "tiers": [{"cost": 0, "desc": "Manual assembly table with molds."},
               {"cost": 9000, "desc": "Powered forming machine."},
               {"cost": 26000, "desc": "Multi-head product line."},
               {"cost": 60000, "desc": "Recipe-programmable cell."},
               {"cost": 125000, "desc": "Flexible robotic product line."}]},
    {"id": "packaging", "name": "Packaging Machine", "slot": "packaging",
     "tiers": [{"cost": 0, "desc": "Manual packaging table."},
               {"cost": 6500, "desc": "Semi-automatic sealer."},
               {"cost": 19000, "desc": "Label-and-seal combo unit."},
               {"cost": 48000, "desc": "Automated packing lane."},
               {"cost": 100000, "desc": "High-speed packaging cell."}]},
]
write("machines.json", {"machines": machines})

# ---------------------------------------------------------------- balance
balance = {
    "start_cash": 12000, "loan_principal": 45000, "loan_payment": 950,
    "overdraft_limit": -15000, "start_reputation": 35, "start_compliance": 60,
    "facility_rent": 220, "tax_rate": 0.12,
    "base_wage": 90, "hiring_fee": 150,
    "price_seed_unit": 120, "price_packaging_unit": 1.2, "price_spare_part": 160,
    "machine_wear_per_hour": 1.1,
    "customer_base_rate": 0.11,
    "event_daily_chance": 0.4,
    "audit_fine": 1500,
    "rp_profit_threshold": 400,
    "store_goodwill": 90000,
    "trial_unit_price": 9.5,
}
write("balance.json", balance)

# ---------------------------------------------------------------- names
names = {
    "first": ["Ava", "Ben", "Carla", "Dmitri", "Elena", "Felix", "Grace", "Hana",
              "Ivan", "Jonas", "Kim", "Lena", "Marco", "Nadia", "Omar", "Priya",
              "Quentin", "Rosa", "Sam", "Tessa", "Umut", "Vera", "Wes", "Yara", "Zoe"],
    "last": ["Adler", "Brandt", "Costa", "Dorn", "Ekwueme", "Fischer", "Grün",
             "Hoffman", "Ito", "Jansen", "Kovacs", "Lindt", "Meyer", "Novak",
             "Okafor", "Petrov", "Quist", "Rossi", "Schmidt", "Tanaka", "Ueda",
             "Vogel", "Weber", "Yilmaz", "Zhang"],
}
write("names.json", names)

print("All data files generated.")

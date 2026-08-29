[← Back to Main README](../../../../README.md)

# AI Agent Calendar Dataset Generation Specification
**Document ID:** `AGENT_CALENDAR_DATASET_INSTRUCTIONS.md`  
**Target Audience:** Autonomous AI Agents (Claude, ChatGPT, Gemini, Local LLM Agents, Research & Coding Subagents)  
**Scope:** Country-Agnostic, Religion-Agnostic, Culture-Agnostic, Calendar-System-Agnostic

---

## 1. Primary Objective

This document is a **standalone, deterministic instruction manual** for an AI agent. 

Your mission as an agent reading this document is to research, calculate, structure, validate, and output an authoritative, machine-readable calendar dataset tailored to the **user's specified geographic, religious, cultural, and temporal scope**, without assuming any default country, religion, or calendar system.

You must be able to execute this workflow independently without human intervention, maintaining strict standards of **factual provenance, algorithmic correctness, and honest representation of uncertainty**.

---

## 2. Core Architectural Principle: The Hierarchical Scope Chain

Never assume: *"There is one universal calendar for this country or religion."*

Before collecting or calculating any data point, you must traverse and resolve the **Hierarchical Scope Chain**:

```
[ COUNTRY ]
    └── [ REGION / STATE / PROVINCE ]
            └── [ COMMUNITY / ETHNICITY ]
                    └── [ RELIGION / DENOMINATION ]
                            └── [ CALENDAR SYSTEM & EPOCH ]
                                    └── [ GOVERNING AUTHORITY ]
                                            └── [ EVENT TYPE & STATUS ]
```

### Scope Chain Rules:
1. **Never Flatten Regional Differences:** A holiday observed only in Bavaria (Germany), Karnataka (India), or Quebec (Canada) must be scoped to that specific region. Do not mark regional holidays as nationwide.
2. **Never Homogenize Religious Traditions:** Within Islam (Sunni vs. Shia / local moon-sighting vs. Umm al-Qura calculation), Christianity (Western Gregorian vs. Eastern Orthodox Julian / Revised Julian), Judaism (Rabbinic vs. Karaite), Buddhism (Theravada vs. Mahayana), or Hinduism (Amanta vs. Purnimanta / Drik vs. Surya Siddhanta), conventions vary significantly. Always explicitly identify the tradition and authority.
3. **Never Merge Conflicting Observances:** If two communities observe an event on different dates or using different calculation methods, record both as distinct entries with explicit provenance metadata.

---

## 3. User Scope Discovery

First, parse or solicit the user's requirements across these 5 dimensions:

| Dimension | Description | Examples |
| :--- | :--- | :--- |
| **1. Geographic Scope** | Target country, state/province, canton, prefecture, territory, or municipality. | `ISO: JP` (Japan nationwide), `ISO: IN-JH` (Jharkhand, India), `ISO: DE-BY` (Bavaria, Germany), `ISO: US` (Federal). |
| **2. Religious Scope** | Targeted faith traditions, denominations, or secular only. | Secular only, All recognized national faiths, Catholic + Lutheran, Sunni Islam, Mahayana Buddhism, Vaishnava Hindu. |
| **3. Cultural & Civic Scope**| Traditional, indigenous, civic, harvest, or commercial events. | Indigenous peoples' observances, civic commemorations, seasonal solstices/equinoxes. |
| **4. Event Categories** | Public holidays, bank closures, optional/restricted holidays, observances, astronomical. | Public statutory holidays, optional leaves, astronomical moon phases, tax year markers. |
| **5. Temporal Range** | Start year to End year. | `2026–2035`, `2026–2040`, `2026–3069`. |

> [!IMPORTANT]
> **Default Assumption Rule:** If the user does not specify a country or religion, **you must prompt the user to specify their target scope**. Never silently default to India, the United States, Christianity, Islam, or Hinduism.

---

## 4. Source Discovery & Authority Hierarchy

You must gather data exclusively by prioritizing the highest-authority sources available for the target scope:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Tier 1: National Government (Official Gazettes, Ministries, Legislation)│
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 2: Regional/State Government (State Gazettes, Provincial Orders)    │
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 3: Official Religious Authorities (Ecclesiastical Councils, Boards)│
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 4: Scientific & Astronomical Institutions (IMD, NASA, USNO, HMNAO) │
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 5: International Organizations (UN, UNESCO, WHO, ILO)              │
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 6: Reputable Specialized Academic & Ephemeris Registries          │
├─────────────────────────────────────────────────────────────────────────┤
│ Tier 7: General Discovery & Cross-Checking Websites                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Hierarchy Breakdown:
* **Tier 1 (National Government):** Official gazettes, Ministry of Personnel/Interior/Labour, statutory acts, national calendar bodies (e.g., Cabinet Office of Japan, UK Cabinet Office, DoPT India, US OPM).
* **Tier 2 (Regional Government):** State/provincial legislative acts and executive holiday notifications.
* **Tier 3 (Religious Authorities):** Central religious councils, recognized national synods, grand mufti offices, rabbinical courts, rashtriya panchang committees.
* **Tier 4 (Scientific/Astronomical):** National astronomical observatories, ephemeris computation services (VSOP87, JPL DE440, USNO, IMD Positional Astronomy Centre).
* **Tier 5 (International):** United Nations observances, international treaty days.
* **Tier 6 (Specialist Academic):** Peer-reviewed calendrical algorithms (e.g., Jean Meeus *Astronomical Algorithms*, Dershowitz & Reingold *Calendrical Calculations*).
* **Tier 7 (General Web):** Search results, blogs, Wikipedia. **Allowed only for initial event discovery. Never cite Tier 7 as the primary source of truth.**

---

## 5. Source Validation & Record Keeping

For every source consulted, extract and record:
* `id`: Stable identifier (e.g., `src-gov-dopt-2026`, `src-astronomy-jpl`).
* `name`: Formal title of document/publication.
* `url`: Direct canonical URL.
* `organization`: Authoring agency or religious body.
* `authority_level`: `government_national`, `government_regional`, `religious_central`, `scientific`, `international`, or `specialist`.
* `is_official`: Boolean (`true` for Tiers 1–3).
* `published_date`: ISO date of official publication.
* `retrieval_date`: ISO date when data was retrieved by the agent.
* `applicability`: Geographic regions, religions, or calendar systems covered.

---

## 6. Event Taxonomy & Daily Life Test

### Event Categories:
1. **Government & Statutory:** Public holidays, statutory bank holidays, government office closures, restricted/optional holidays.
2. **National & Civic:** Independence days, constitution days, veterans/memorial days, republic days.
3. **Religious & Devotional:** Major festivals, fasting periods (Lent, Ramadan, Paryushan, Yom Kippur), feast days, new year observances.
4. **Cultural & Seasonal:** Harvest celebrations, seasonal new years, traditional folk festivals, solstice/equinox celebrations.
5. **Astronomical:** Solar/lunar eclipses, equinoxes, solstices, lunar phases (new moon, full moon, supermoons).
6. **Calendar-Specific:** Lunisolar months, tithis, nakshatras, Hijri months, Hebrew months, solar terms (24 Solar Terms).
7. **Civic & Practical:** Financial year start/end dates, tax deadlines, daylight saving time (DST) transitions.

### The "Daily Life" Test:
Before including any event, evaluate:
> *"Would a person living, working, or observing traditions in this region/community genuinely benefit from seeing this date on their calendar?"*

* **Include:** Official holidays, major community feasts, practical civic deadlines, and traditional holidays.
* **Exclude:** Fabricated marketing "days" (e.g. "International Pizza Day"), unverified internet trivia, or obscure commemorations lacking statutory or cultural recognition.

---

## 7. Religious Calendar Rules & Moon-Sighting Uncertainty

1. **Solar vs. Lunisolar vs. Pure Lunar:**
   * **Solar (Gregorian, Julian, Solar Hijri, Bahá'í, Coptic, Ethiopian):** Fixed or mathematically predictable seasonal alignments.
   * **Lunisolar (Hebrew, Hindu Vikram/Shaka, Chinese, Buddhist, Burmese):** Governed by solar longitude + lunar synodic months, intercalary leap months (Adhika Masa, Embolismic months), and sunrise tithi conventions (*Udaya Tithi*).
   * **Pure Lunar (Islamic / Hijri):** 12 lunar months (~354.36 days per year).
2. **Moon-Sighting Uncertainty Protocol:**
   * Pure lunar dates (such as Islamic Eid-ul-Fitr, Eid-ul-Adha, Muharram) or regional lunisolar festivals that depend on physical crescent sighting (*Hilal*) must be documented with:
     * `date_status`: `"estimated"` or `"provisional"` (for future years) or `"official_verified"` (for current year once declared).
     * `notes`: Stating the astronomical prediction basis and that local visual sighting may shift the observance by ±1 day.
3. **Calculation Convention Transparency:**
   * Document whether Hindu festivals use **Drik Panchang** (modern planetary ephemeris) or **Surya Siddhanta** (traditional spherical astronomy), **Amanta** (month ends on New Moon) or **Purnimanta** (month ends on Full Moon).
   * Document whether Christian Easter uses the **Gregorian algorithm** (Western Catholic/Protestant) or the **Julian computus + Dionysian lunar cycle** (Eastern Orthodox).

---

## 8. Date Status Taxonomy

Every date entry in the dataset must carry an explicit `date_status` property:

| Status | Definition | Example |
| :--- | :--- | :--- |
| `official_verified` | Explicitly published in an official government gazette, legislative bulletin, or authorized decree. | 2026 National Gazetted Holiday list from DoPT / Cabinet Office. |
| `recurring_rule` | Follows an unambiguous, invariant legal or calendar rule. | US Thanksgiving (4th Thursday of November), Japanese Culture Day (Nov 3). |
| `calculated` | Generated using an astronomical, lunisolar, or perpetual algorithmic formula. | Vernal Equinox 2032, Easter Sunday 2045, Lunar Adhika Masa 2037. |
| `provisional` | Expected date based on customary scheduling, awaiting official formal gazette release. | Public holidays for the upcoming year published in provisional draft form. |
| `estimated` | Approximated via astronomical projection, subject to visual sighting or local declaration. | Islamic Hijri festival dates 5 years in advance. |
| `unknown` | Cannot responsibly be determined without official future executive action. | Future election dates, ad-hoc state mourning days, future one-time bank holidays. |

> [!CAUTION]
> **Strict Anti-Fabrication Rule:** NEVER upgrade `estimated` or `calculated` to `official_verified`. Never invent future government holidays for years where no gazette exists.

---

## 9. Calculation Provenance Standards

Whenever dates are algorithmically calculated, you must attach a complete `calculation` object:

```json
{
  "method": "astronomical_ephemeris",
  "calendar_system": "Hindu Lunisolar (Drik Ganita)",
  "algorithm": "VSOP87 / Lahiri Ayanamsha (23.85° at J2000)",
  "parameters": {
    "tithi": "Purnima",
    "hindu_month": "Shravana",
    "ayanamsa": "Lahiri",
    "udaya_tithi_applied": true
  },
  "coordinates": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "timezone": "Asia/Kolkata"
  },
  "assumptions": "Calculated for sunrise at Indian standard meridian (82.5° E).",
  "sighting_dependent": false
}
```

---

## 10. Canonical Event JSON Schema

Each event must adhere to this standardized schema:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "id": "IN-2026-DIWALI",
  "name": "Diwali (Deepavali)",
  "local_names": [
    { "language": "hi", "text": "दीपावली" },
    { "language": "ta", "text": "தீபாவளி" }
  ],
  "aliases": [
    "Festival of Lights",
    "Deepavali"
  ],
  "date": "2026-11-08",
  "start_datetime": "2026-11-08T00:00:00+05:30",
  "end_datetime": "2026-11-08T23:59:59+05:30",
  "country": "IN",
  "regions": [ "ALL" ],
  "calendar_system": "Hindu Lunisolar",
  "categories": [ "religious", "cultural", "government" ],
  "religions": [ "Hinduism", "Jainism", "Sikhism" ],
  "traditions": [ "Sanatana Dharma" ],
  "scope": "national",
  "importance": "major",
  "is_public_holiday": true,
  "is_restricted_holiday": false,
  "date_status": "official_verified",
  "calculation": null,
  "sources": [
    "src-gov-dopt-2026",
    "src-panchang-rashtriya-2026"
  ],
  "retrieved_at": "2026-08-29",
  "timezone": "Asia/Kolkata",
  "description": "Diwali is the festival of lights celebrated on Amavasya of the month of Kartika.",
  "notes": "Gazetted public holiday across India."
}
```

---

## 11. Source Manifest Schema (`sources.json`)

```json
{
  "manifest_version": "1.0.0",
  "generated_at": "2026-08-29T16:15:00Z",
  "geographic_scope": "IN",
  "temporal_scope": "2026-2035",
  "sources": [
    {
      "id": "src-gov-dopt-2026",
      "name": "DoPT Official Holiday List 2026 (O.M. F.No.12/2/2025-JCA)",
      "url": "https://dopt.gov.in/holiday-list-2026",
      "organization": "Department of Personnel and Training, Ministry of Personnel, Public Grievances and Pensions, Government of India",
      "authority_level": "government_national",
      "is_official": true,
      "published_date": "2025-06-15",
      "retrieved_at": "2026-08-29",
      "coverage": "All Central Government offices and national gazetted holidays across India."
    }
  ]
}
```

---

## 12. Conflict Resolution & Reporting

When two authoritative sources provide conflicting dates:
1. **Analyze Root Cause:**
   * Is it a difference in **geographic jurisdiction** (e.g. State holiday declared on Monday vs. Federal holiday on Tuesday)?
   * Is it a **calendar computation rule** difference (e.g. *Udaya Tithi* at sunrise vs. exact tithi timing during midnight)?
   * Is it **astronomical prediction vs. visual moon-sighting**?
   * Is it **civil observed holiday** (e.g. Monday substitute) vs. **actual anniversary** (Sunday)?
2. **Resolution Protocol:**
   * If both dates are legitimate under different conventions, **preserve both entries** with clear `scope`, `notes`, and `date_status`.
   * Generate an accompanying `CONFLICT_REPORT.md`:

```markdown
# Calendrical Conflict Report

## Conflict #1: Raksha Bandhan 2026
* **Date Option A:** 2026-08-27 (Purnima tithi starts 09:08 AM)
* **Date Option B:** 2026-08-28 (Udaya Tithi Purnima sunrise observance)
* **Root Cause:** Bhadra Kaal prevails during daytime on Aug 27 until 08:34 PM, prohibiting Rakhi ceremonies during daylight hours. The Udaya Tithi on Aug 28 morning (05:57 AM to 09:48 AM) is the canonical observance.
* **Resolution:** Canonical national observance assigned to `2026-08-28` (`date_status: "official_verified"`, DoPT O.M. F.No.12/2/2025-JCA).
```

---

## 13. Data Quality & Multi-Stage Validation Rules

Before finalizing the dataset, your execution pipeline must pass all validation gates:

```
[ Gate 1: JSON Schema & Datatypes ]
    └── [ Gate 2: ISO Country/Region Codes (ISO 3166-1 / 3166-2) ]
            └── [ Gate 3: Date Validity & Leap Year Alignment ]
                    └── [ Gate 4: Day-of-Week Consistency ]
                            └── [ Gate 5: Provenance Integrity (Source ID link) ]
                                    └── [ Gate 6: Status Truthfulness (No fake official tags) ]
```

1. **Temporal Consistency:** Ensure all February 29 dates occur only in valid leap years.
2. **Duplicate Prevention:** Events sharing the same canonical entity, region, and date must be consolidated with aliases rather than duplicated.
3. **No Dangling References:** Every source ID listed in an event's `sources` array must exist in `sources.json`.

---

## 14. Output File Structure

Organize the generated artifacts in a clean, self-contained directory tree:

```
calendar-dataset-[scope]/
├── README.md                  # Scope, summary statistics, usage instructions
├── sources.json               # Full provenance source manifest
├── calendar-systems.json      # Definitions and parameters of calendar systems used
├── CONFLICT_REPORT.md         # Documented discrepancies and resolutions
├── VALIDATION_REPORT.md       # Quality gate validation results
└── events/
    ├── 2026.json              # Yearly event data (or 2026.jsonl)
    ├── 2027.json
    └── ...
```

---

## 15. Standard 20-Step Agent Execution Workflow

When invoked with a user prompt, execute these 20 steps sequentially:

```
 1. Parse user scope (Country, Region, Religion, Categories, Years).
 2. Verify all parameters; if ambiguous or missing, solicit clarification.
 3. Identify all applicable calendar systems and epochs.
 4. Identify Tier 1 to Tier 4 authoritative institutions for that scope.
 5. Discover primary source URLs and gazette publications.
 6. Inspect and extract statutory national public holidays.
 7. Inspect and extract regional/state holidays.
 8. Inspect and calculate religious, cultural, and community observances.
 9. Compute astronomical events (eclipses, equinoxes, solstices) with coordinates.
10. Calculate future algorithmically derived dates where authoritative rules exist.
11. Assign rigorous date_status to every single event.
12. Attach complete calculation parameters to all computed dates.
13. Attach source citations to every externally referenced event.
14. Identify conflicts and resolve them transparently without data loss.
15. Populate canonical names, aliases, and local language translations.
16. Run 6-gate data quality validation check.
17. Generate sources.json manifest.
18. Generate yearly event JSON files.
19. Compile CONFLICT_REPORT.md and VALIDATION_REPORT.md.
20. Deliver the final validated dataset package to the user.
```

---

## 16. Strict Negative Prohibitions ("What NOT to Do")

* **NEVER** fabricate dates, holidays, or government decrees.
* **NEVER** treat search snippets or Wikipedia as primary authoritative proof.
* **NEVER** assume a national holiday applies to every state or province.
* **NEVER** assume one religious denomination represents all believers.
* **NEVER** convert `estimated` or `calculated` dates into `official_verified`.
* **NEVER** invent future elections or future administrative public holidays.
* **NEVER** add frivolous marketing days just to pad the dataset size.
* **NEVER** merge two distinct festivals because their names sound similar.
* **NEVER** hide uncertainty or moon-sighting variances.
* **NEVER** hard-code default countries or religions.

---
**End of Specification.**

[← Back to Main README](../../../../README.md)

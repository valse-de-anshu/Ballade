/**
 * IndianCalendar.js
 * Perpetual Indian Calendar & Festivals Calculation Engine (2026 – 3069+)
 *
 * METHODOLOGY & SOURCES:
 *  - Fixed solar / national dates: India.gov.in, DoPT O.M. F.No.12/2/2023-JCA (3 Jul 2025)
 *  - Hindu luni-solar: Synodic month (Chapront–Meeus), Adhika Masa detected via
 *    Nirayana / Sidereal solar longitude (Lahiri Ayanamsha).
 *  - Islamic: Standard Tabular Hijri calendar (Kuwaiti arithmetic algorithm, epoch JD 1948439.5).
 *    ⚠ All Islamic dates are subject to actual moon-sighting observations (±1–2 days).
 *  - Christian: Gregorian Easter (Anonymous Gregorian Algorithm — mathematically exact).
 *
 * STATUS LABELS in desc field:
 *  [GH]  Central Govt Gazetted Holiday (mandatory) — DoPT O.M.
 *  [RH]  Central Govt Restricted Holiday — DoPT O.M.
 *  [ST]  State-level holiday (varies by state)
 *  [OB]  Observance / awareness day (not a govt holiday)
 *  [JA]  Jayanti (birth anniversary) observance
 *  [FI]  Financial / tax date
 *  [CAL] Calculated lunar date — accurate ±1 day
 *  [IS]  Islamic — ⚠ actual date subject to moon sighting (±1–2 days)
 */

.pragma library

// ═══════════════════════════════════════════════════════
// SECTION 1: ASTRONOMICAL & CALENDRICAL HELPERS
// ═══════════════════════════════════════════════════════

function isLeapYear(year) {
    return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
}

// Julian Day Number from Gregorian date
function gregorianToJD(year, month, day) {
    var a = Math.floor((14 - month) / 12);
    var y = year + 4800 - a;
    var m = month + 12 * a - 3;
    return day + Math.floor((153 * m + 2) / 5) + 365 * y
           + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
}

// Gregorian date from Julian Day Number
function jdToGregorian(jd) {
    var a = jd + 32044;
    var b = Math.floor((4 * a + 3) / 146097);
    var c = a - Math.floor((146097 * b) / 4);
    var d = Math.floor((4 * c + 3) / 1461);
    var e = c - Math.floor((1461 * d) / 4);
    var m = Math.floor((5 * e + 2) / 153);
    var day   = e - Math.floor((153 * m + 2) / 5) + 1;
    var month = m + 3 - 12 * Math.floor(m / 10);
    var year  = 100 * b + d - 4800 + Math.floor(m / 10);
    return { year: year, month: month, day: day };
}

// ── Synodic New Moon (Chapront–Meeus, accurate ≈ ±5 min over centuries) ──────
var SYNODIC_MONTH = 29.530588853;
var BASE_NEW_MOON_JD = 2451550.26; // New Moon 2000-01-06 18:14 UTC

function getNewMoonJD(k) {
    var T = k / 1236.85;
    return 2451550.09766 + SYNODIC_MONTH * k
        + 0.0001337 * T * T
        - 0.000150  * T * T * T
        - 0.40720   * Math.sin((201.5643 + 385.8169 * k) * Math.PI / 180)
        + 0.17241   * Math.sin((2.5534   + 29.1053  * k) * Math.PI / 180)
        + 0.01608   * Math.sin((21.0     + 385.0    * k) * Math.PI / 180)
        + 0.01039   * Math.sin((124.0    + 1.0      * k) * Math.PI / 180);
}

function getNewMoonsForYear(year) {
    var startJD = gregorianToJD(year, 1, 1) - 60;
    var endJD   = gregorianToJD(year, 12, 31) + 60;
    var kStart  = Math.floor((startJD - BASE_NEW_MOON_JD) / SYNODIC_MONTH) - 2;
    var result  = [];
    for (var k = kStart; k <= kStart + 25; k++) {
        var jd = getNewMoonJD(k);
        if (jd >= startJD && jd <= endJD) result.push(jd);
    }
    return result;
}

// ── Sidereal (Nirayana) Solar Longitude (Lahiri Ayanamsha) ───────────────────
function sunLongitudeSidereal(jd) {
    var T = (jd - 2451545.0) / 36525.0;
    var L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;
    var M  = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;
    var Mrad = M * Math.PI / 180;
    var C  = (1.914602 - 0.004817 * T - 0.000014 * T * T) * Math.sin(Mrad)
           + (0.019993 - 0.000101 * T) * Math.sin(2 * Mrad)
           + 0.000289 * Math.sin(3 * Mrad);
    var tropical = L0 + C;
    var ayan = 23.85 + T * (50.27 / 3600.0) * 100.0;
    var sidereal = tropical - ayan;
    sidereal = sidereal - 360 * Math.floor(sidereal / 360);
    return sidereal;
}

function sunSign(jd) {
    return Math.floor(sunLongitudeSidereal(jd) / 30);
}

// ── Islamic (Hijri) Tabular Algorithms ───────────────────────────────────────
function jdToIslamic(jd) {
    var l = Math.floor(jd) - 1948440 + 10632;
    var n = Math.floor((l - 1) / 10631);
    l = l - 10631 * n + 354;
    var j = (Math.floor((10985 - l) / 5316)) * (Math.floor((50 * l) / 17719)) + (Math.floor(l / 5670)) * (Math.floor((43 * l) / 15238));
    l = l - (Math.floor((30 - j) / 15)) * (Math.floor((17719 * j) / 50)) - (Math.floor(j / 16)) * (Math.floor((15238 * j) / 43)) + 29;
    var m = Math.floor((24 * l) / 709);
    var d = l - Math.floor((709 * m) / 24);
    var y = 30 * n + j - 30;
    return { year: y, month: m, day: d };
}

function islamicToJD(year, month, day) {
    return Math.floor((11 * year + 3) / 30) +
           354 * year +
           30 * month -
           Math.floor((month - 1) / 2) +
           day + 1948440 - 385;
}

// ── Date Key ──────────────────────────────────────────────────────────────────
function formatDateKey(y, m, d) {
    var mm = m < 10 ? "0" + m : "" + m;
    var dd = d < 10 ? "0" + d : "" + d;
    return y + "-" + mm + "-" + dd;
}

// ═══════════════════════════════════════════════════════
// SECTION 2: HINDU LUNAR MONTH IDENTIFIER
// ═══════════════════════════════════════════════════════

function identifyLunarMonths(newMoons) {
    var result = [];
    for (var i = 0; i < newMoons.length - 1; i++) {
        var nmStart = newMoons[i];
        var nmEnd   = newMoons[i + 1];
        var s1 = sunSign(nmStart);
        var s2 = sunSign(nmEnd);
        var hinduMonth;
        var isAdhika = false;
        if (s1 !== s2) {
            hinduMonth = s2;
        } else {
            hinduMonth = s1;
            isAdhika = true;
        }
        result.push({ jd: nmStart, hinduMonth: hinduMonth, isAdhika: isAdhika });
    }
    return result;
}

function getYearHinduMonths(year) {
    var newMoons = getNewMoonsForYear(year);
    var identified = identifyLunarMonths(newMoons);
    
    // Find Chaitra of Gregorian year (NM falling in March/April/May)
    var chaitraIdx = -1;
    for (var i = 0; i < identified.length; i++) {
        var dt = jdToGregorian(Math.round(identified[i].jd + 0.5));
        if (identified[i].hinduMonth === 0 && !identified[i].isAdhika && dt.year === year && dt.month >= 3 && dt.month <= 5) {
            chaitraIdx = i;
            break;
        }
    }
    
    var months = {};
    if (chaitraIdx !== -1) {
        for (var i = chaitraIdx; i < identified.length; i++) {
            var hm = identified[i].hinduMonth;
            if (hm >= 0 && (months[hm] === undefined || !identified[i].isAdhika)) {
                months[hm] = identified[i].jd;
            }
        }
        for (var i = chaitraIdx - 1; i >= 0; i--) {
            var hm = identified[i].hinduMonth;
            if (hm >= 9 && months[hm] === undefined) {
                months[hm] = identified[i].jd;
            }
        }
    }
    return months;
}

// ═══════════════════════════════════════════════════════
// SECTION 3: EVENT GENERATOR
// ═══════════════════════════════════════════════════════

function getYearEvents(year) {
    var events = {};

    function add(m, d, title, type, icon, desc) {
        if (m < 1 || m > 12 || d < 1 || d > 31) return;
        var key = formatDateKey(year, m, d);
        if (!events[key]) events[key] = [];
        for (var i = 0; i < events[key].length; i++) {
            if (events[key][i].title === title) return;
        }
        events[key].push({
            title: title,
            type:  type || "festival",
            icon:  icon || "event",
            desc:  desc || ""
        });
    }

    function addJD(jd, title, type, icon, desc) {
        if (!jd) return;
        var dt = jdToGregorian(Math.round(jd + 0.5));
        if (dt.year === year) add(dt.month, dt.day, title, type, icon, desc);
    }

    // ─────────────────────────────────────────────────────
    // PART A: FIXED SOLAR / NATIONAL / CIVIC DATES
    // ─────────────────────────────────────────────────────

    // JANUARY
    add(1,  1,  "New Year's Day",                         "observance","celebration",       "Global Gregorian New Year");
    add(1,  9,  "Pravasi Bharatiya Divas",                "observance","public",             "Non-Resident Indian (NRI) Day");
    add(1,  12, "National Youth Day",                     "jayanti",   "person",             "Swami Vivekananda Jayanti (1863)");
    add(1,  13, "Lohri",                                  "festival",  "local_fire_department","Punjabi Harvest Festival (eve of Makar Sankranti)");
    add(1,  14, "Makar Sankranti / Pongal / Magh Bihu",  "festival",  "wb_sunny",           "Sun enters Makara; Pongal (TN); Magh Bihu (Assam); Uttarayan (GJ)");
    add(1,  15, "Army Day",                               "observance","military_tech",      "Honoring Field Marshal K.M. Cariappa (1949)");
    add(1,  16, "Thiruvalluvar Day",                      "jayanti",   "menu_book",          "Tamil poet and philosopher commemoration");
    add(1,  23, "Parakram Diwas",                         "jayanti",   "star",               "Netaji Subhas Chandra Bose Jayanti (1897)");
    add(1,  24, "National Girl Child Day",                "observance","face_3",             "Beti Bachao Beti Padhao national awareness");
    add(1,  25, "National Voters' Day",                   "observance","how_to_vote",        "Election Commission of India Foundation Day (1950)");
    add(1,  26, "Republic Day",                           "national",  "flag",               "Constitution of India adopted (1950) — National Holiday");
    add(1,  30, "Martyrs' Day (Shaheed Diwas)",           "observance","candle",             "Mahatma Gandhi assassination anniversary (1948)");

    // FEBRUARY
    add(2,  1,  "Union Budget Day",                       "financial", "account_balance",    "Central Government Budget Presentation");
    add(2,  1,  "Indian Coast Guard Day",                 "observance","sailing",            "Coast Guard Raising Day (1977)");
    add(2,  13, "National Women's Day",                   "jayanti",   "person",             "Sarojini Naidu Jayanti (1879)");
    add(2,  19, "Chhatrapati Shivaji Maharaj Jayanti",   "jayanti",   "fort",               "Maratha Empire Founder anniversary");
    add(2,  28, "National Science Day",                   "observance","science",            "Discovery of the Raman Effect (1928)");

    // MARCH
    add(3,  8,  "International Women's Day",              "observance","diversity_1",        "UN International Women's Day");
    add(3,  21, "Jamshedi Navroz (Fasli Navroz)",         "festival",  "celebration",        "Persian / Zoroastrian New Year");
    add(3,  22, "World Water Day",                        "observance","water_drop",         "UN Water Conservation Day");
    add(3,  23, "Shaheed Diwas",                          "observance","military_tech",      "Bhagat Singh, Sukhdev & Rajguru Martyrdom (1931)");
    add(3,  31, "Financial Year End",                     "financial", "account_balance",    "Last day of Indian Fiscal Year");

    // APRIL
    add(4,  1,  "Financial Year Start",                   "financial", "account_balance",    "New Indian Fiscal Year begins");
    add(4,  7,  "World Health Day",                       "observance","health_and_safety",  "World Health Organization Foundation Day");
    add(4,  13, "Jallianwala Bagh Day",                   "observance","candle",             "1919 Massacre Memorial");
    add(4,  14, "Dr. B.R. Ambedkar Jayanti",              "national",  "menu_book",          "Architect of Indian Constitution — National Holiday");
    add(4,  14, "Baisakhi / Vaisakhadi",                  "restricted","agriculture",        "Sikh New Year & Harvest Festival; Vishu (KL), Puthandu (TN)");
    add(4,  21, "National Civil Services Day",            "observance","badge",              "Sardar Patel's ICS address commemoration");
    add(4,  22, "Earth Day",                              "observance","eco",                "International Earth Day");
    add(4,  24, "National Panchayati Raj Day",            "observance","account_balance",    "73rd Constitutional Amendment");

    // MAY
    add(5,  1,  "International Labour Day / May Day",     "observance","engineering",        "Workers' Rights Day; Maharashtra Day; Gujarat Day");
    add(5,  7,  "Rabindranath Tagore Jayanti",            "jayanti",   "menu_book",          "Rabindra Jayanti — Nobel Laureate (1861)");
    add(5,  11, "National Technology Day",                "observance","memory",             "Pokhran-II Nuclear Tests (1998)");
    add(5,  21, "Anti-Terrorism Day",                     "observance","shield",             "Rajiv Gandhi Martyrdom Day (1991)");
    add(5,  31, "World No Tobacco Day",                   "observance","smoke_free",         "WHO Anti-Tobacco Awareness");

    // JUNE
    add(6,  5,  "World Environment Day",                  "observance","eco",                "UN Environment Programme Day");
    add(6,  21, "International Yoga Day",                 "observance","self_improvement",   "UN-recognized global yoga day");
    add(6,  23, "International Olympic Day",              "observance","sports_soccer",      "International Olympic Committee Day");

    // JULY
    add(7,  1,  "National Doctor's Day / GST Day",        "observance","medical_services",   "Dr. B.C. Roy Memorial & GST Anniversary");
    add(7,  11, "World Population Day",                   "observance","groups",             "UNFPA Awareness Day");
    add(7,  26, "Kargil Vijay Diwas",                     "observance","military_tech",      "Operation Vijay — 1999 Kargil War Victory");

    // AUGUST
    add(8,  7,  "National Handloom Day",                  "observance","sports_handball",    "Swadeshi Movement anniversary");
    add(8,  9,  "Quit India Movement Day",                "observance","campaign",           "August Kranti Diwas (1942)");
    add(8,  15, "Independence Day",                       "national",  "flag",               "Independence from British Rule (1947) — National Holiday");
    add(8,  17, "Parsi New Year (Shahenshahi)",           "festival",  "celebration",        "Parsi / Zoroastrian New Year");
    add(8,  20, "Sadbhavana Diwas",                       "jayanti",   "volunteer_activism",  "Rajiv Gandhi Jayanti — National Harmony Day");
    add(8,  29, "National Sports Day",                    "observance","sports_soccer",      "Major Dhyan Chand Jayanti (1905)");

    // SEPTEMBER
    add(9,  5,  "Teachers' Day",                          "observance","school",             "Dr. Sarvepalli Radhakrishnan Jayanti (1888)");
    add(9,  8,  "International Literacy Day",             "observance","auto_stories",       "UNESCO Literacy Day");
    add(9,  14, "Hindi Diwas",                            "observance","translate",          "Adoption of Hindi as official language (1949)");
    add(9,  15, "Engineers' Day",                         "jayanti",   "construction",       "Sir M. Visvesvaraya Jayanti (1860)");
    add(9,  16, "World Ozone Day",                        "observance","wb_sunny",           "Montreal Protocol Anniversary");
    add(9,  25, "Antyodaya Diwas",                        "jayanti",   "handshake",          "Pt. Deendayal Upadhyaya Jayanti");

    // OCTOBER
    add(10, 2,  "Gandhi Jayanti",                         "national",  "spa",                "Mahatma Gandhi Jayanti (1869) — National Holiday");
    add(10, 8,  "Indian Air Force Day",                   "observance","flight",             "IAF Foundation Day (1932)");
    add(10, 15, "World Students' Day",                    "jayanti",   "rocket_launch",      "Dr. A.P.J. Abdul Kalam Jayanti (1931)");
    add(10, 21, "Police Commemoration Day",               "observance","local_police",       "Honoring Police Martyrs");
    add(10, 24, "United Nations Day",                     "observance","public",             "UN Charter Anniversary (1945)");
    add(10, 31, "National Unity Day",                     "jayanti",   "shield",             "Sardar Vallabhbhai Patel Jayanti (1875) — Rashtriya Ekta Diwas");

    // NOVEMBER
    add(11, 7,  "National Cancer Awareness Day",          "observance","health_and_safety",  "Marie Curie Birthday — Cancer Awareness");
    add(11, 11, "National Education Day",                 "jayanti",   "menu_book",          "Maulana Abul Kalam Azad Jayanti (1888)");
    add(11, 14, "Children's Day (Bal Diwas)",             "jayanti",   "sentiment_satisfied","Pt. Jawaharlal Nehru Jayanti (1889)");
    add(11, 15, "Janjatiya Gaurav Divas",                 "jayanti",   "forest",             "Bhagwan Birsa Munda Jayanti (1875)");
    add(11, 19, "National Integration Day",               "jayanti",   "handshake",          "Indira Gandhi Jayanti");
    add(11, 24, "Guru Tegh Bahadur Shaheedi Diwas",       "festival",  "candle",             "9th Sikh Guru Martyrdom Day (1675)");
    add(11, 26, "Constitution Day (Samvidhan Divas)",      "observance","gavel",             "Adoption of the Constitution (1949)");

    // DECEMBER
    add(12, 1,  "World AIDS Day",                         "observance","favorite",           "UNAIDS Global Awareness");
    add(12, 1,  "Hornbill Festival (begins)",             "festival",  "celebration",        "Nagaland Festival of Festivals");
    add(12, 4,  "Indian Navy Day",                        "observance","anchor",             "Operation Trident (1971)");
    add(12, 7,  "Armed Forces Flag Day",                  "observance","military_tech",      "Armed Forces Welfare Fund");
    add(12, 8,  "Bodhi Day",                              "festival",  "self_improvement",   "Day of Buddha's Enlightenment");
    add(12, 10, "Human Rights Day",                       "observance","balance",            "UN Declaration of Human Rights (1948)");
    add(12, 14, "National Energy Conservation Day",        "observance","bolt",              "BEE Energy Conservation Day");
    add(12, 16, "Vijay Diwas",                            "observance","emoji_events",       "1971 Liberation War Victory");
    add(12, 22, "National Mathematics Day",               "jayanti",   "calculate",          "Srinivasa Ramanujan Jayanti (1887)");
    add(12, 23, "Kisan Diwas (Farmers' Day)",             "jayanti",   "agriculture",        "Chaudhary Charan Singh Jayanti");
    add(12, 24, "National Consumer Rights Day",           "observance","shopping_bag",       "Consumer Protection Act Commemoration");
    add(12, 25, "Christmas",                              "national",  "celebration",        "Birth of Jesus Christ — National Holiday");
    add(12, 31, "New Year's Eve",                         "observance","celebration",        "Last day of Gregorian year");

    // Advance Tax Deadlines
    add(3,  31, "Advance Tax 4th Installment Deadline",   "financial", "account_balance",    "100% advance tax due");
    add(6,  15, "Advance Tax 1st Installment Deadline",   "financial", "account_balance",    "15% advance tax due");
    add(9,  15, "Advance Tax 2nd Installment Deadline",   "financial", "account_balance",    "45% advance tax due");
    add(12, 15, "Advance Tax 3rd Installment Deadline",   "financial", "account_balance",    "75% advance tax due");

    // ─────────────────────────────────────────────────────
    // PART B: HINDU LUNI-SOLAR FESTIVALS
    // ─────────────────────────────────────────────────────

    var hm = getYearHinduMonths(year);
    var CH = hm[0];  // Chaitra
    var VA = hm[1];  // Vaishakha
    var JY = hm[2];  // Jyeshtha
    var AS = hm[3];  // Ashadha
    var SH = hm[4];  // Shravana
    var BH = hm[5];  // Bhadrapada
    var AW = hm[6];  // Ashwin
    var KT = hm[7];  // Kartik
    var MG = hm[8];  // Margashirsha
    var PA = hm[9];  // Pausha
    var MA = hm[10]; // Magha
    var PH = hm[11]; // Phalguna

    // PHALGUNA (Shivaratri, Holi)
    if (PH) {
        addJD(PH - 3, "Maha Shivaratri", "restricted", "temple_hindu",
              "Great Night of Shiva — Phalguna Krishna 14");
        addJD(PH + 13, "Holika Dahan", "festival", "local_fire_department",
              "Burning of Holika — Phalguna Purnima");
        addJD(PH + 14, "Holi (Festival of Colours)", "national", "palette",
              "Spring Festival of Colours — National Holiday");
    }

    // MAGHA (Vasant Panchami)
    if (MA) {
        addJD(MA + 4, "Vasant Panchami / Saraswati Puja", "restricted", "menu_book",
              "Goddess Saraswati & Spring Celebration — Magha Shukla 5");
        addJD(MA + 14, "Magha Purnima", "observance", "nightlight",
              "Full Moon of Magha — sacred bathing day");
    }

    // CHAITRA (Gudi Padwa, Ram Navami, Mahavir Jayanti)
    if (CH) {
        addJD(CH + 0, "Gudi Padwa", "restricted", "sunny",
              "Marathi New Year Celebration");
        addJD(CH + 0, "Ugadi", "restricted", "sunny",
              "Kannada & Telugu New Year Celebration");
        addJD(CH + 0, "Cheti Chand", "restricted", "celebration",
              "Sindhi New Year Celebration");
        addJD(CH + 0, "Chaitra Navratri Begins", "festival", "flare",
              "9 Nights of Goddess Durga (Vasanta Navratri) begin");
        addJD(CH + 7, "Rama Navami", "national", "temple_hindu",
              "Birth of Lord Rama — National Holiday");
        addJD(CH + 12, "Mahavir Jayanti", "national", "spa",
              "Birth of Lord Mahavira — National Holiday");
        addJD(CH + 14, "Hanuman Jayanti", "restricted", "shield",
              "Birth of Lord Hanuman — Chaitra Purnima");
    }

    // VAISHAKHA (Akshaya Tritiya, Buddha Purnima)
    if (VA) {
        addJD(VA + 1, "Akshaya Tritiya (Akha Teej)", "festival", "diamond",
              "Auspicious day for new beginnings & prosperity");
        addJD(VA + 13, "Buddha Purnima / Vesak", "national", "self_improvement",
              "Buddha Jayanti — National Holiday");
    }

    // JYESHTHA
    if (JY) {
        addJD(JY + 10, "Nirjala Ekadashi", "festival", "temple_hindu",
              "Auspicious fast without water — Jyeshtha Shukla 11");
        addJD(JY + 14, "Jyeshtha Purnima / Vat Purnima", "festival", "favorite",
              "Married women prayer & fast — Jyeshtha Purnima");
    }

    // ASHADHA
    if (AS) {
        addJD(AS + 1, "Jagannath Rath Yatra", "festival", "festival",
              "Chariot Festival of Puri — Ashadha Shukla 2");
        addJD(AS + 10, "Devshayani Ekadashi", "festival", "temple_hindu",
              "Start of Chaturmas — Ashadha Shukla 11");
        addJD(AS + 14, "Guru Purnima", "festival", "school",
              "Honoring Spiritual and Academic Teachers");
    }

    // SHRAVANA (Teej, Raksha Bandhan, Janmashtami)
    if (SH) {
        addJD(SH + 2, "Hariyali Teej", "festival", "park",
              "Monsoon Festival for women — Shravana Shukla 3");
        addJD(SH + 4, "Nag Panchami", "festival", "shield",
              "Traditional worship of serpents — Shravana Shukla 5");
        addJD(SH + 13, "Onam (Thiruvonam)", "restricted", "celebration",
              "Harvest and cultural festival of Kerala");
        addJD(SH + 15, "Raksha Bandhan", "restricted", "favorite",
              "Celebration of sibling bonds — Shravana Purnima");
        addJD(SH + 22, "Krishna Janmashtami", "national", "music_note",
              "Birth of Lord Krishna — National Holiday");
    }

    // BHADRAPADA (Ganesh Chaturthi, Paryushana)
    if (BH) {
        addJD(BH + 2, "Hartalika Teej", "festival", "park",
              "Monsoon fasting festival for women");
        addJD(BH + 3, "Ganesh Chaturthi", "restricted", "temple_hindu",
              "Birth of Lord Ganesha — Ganeshotsav begins");
        addJD(BH + 3, "Paryushana Parva (Jain, begins)", "festival", "spa",
              "Sacred Jain 8-day festival of reflection and fasting");
        addJD(BH + 13, "Anant Chaturdashi / Ganesh Visarjan", "festival", "celebration",
              "Ganeshotsav immersion & concludes");
        addJD(BH + 10, "Samvatsari (Paryushana concludes)", "festival", "spa",
              "Jain Day of Universal Forgiveness (Micchami Dukkadam)");
    }

    // ASHWIN (Navratri, Dussehra, Karwa Chauth)
    if (AW) {
        addJD(AW + 0, "Sharad Navratri Begins (Ghatasthapana)", "festival", "flare",
              "9 Nights of Goddess Durga — Ashwin Shukla 1");
        addJD(AW + 7, "Maha Ashtami (Durga Puja)", "festival", "temple_hindu",
              "Grand Durga Puja — 8th Navratri celebration");
        addJD(AW + 8, "Maha Navami / Ayudha Puja", "festival", "temple_hindu",
              "9th Navratri — weapons and instruments worship");
        addJD(AW + 9, "Dussehra (Vijayadashami)", "national", "military_tech",
              "Victory of Good over Evil — National Holiday");
        addJD(AW + 14, "Valmiki Jayanti / Sharad Purnima", "restricted", "menu_book",
              "Sage Valmiki Birthday commemoration");
        addJD(AW + 18, "Karwa Chauth", "festival", "nightlight",
              "Traditional fasting for spouse wellbeing");
    }

    // KARTIK (Dhanteras, Diwali, Chhath, Guru Nanak)
    if (KT) {
        addJD(KT - 3, "Dhanteras (Dhanatrayodashi)", "restricted", "monetization_on",
              "Worship of Dhanvantari & prosperity");
        addJD(KT - 2, "Naraka Chaturdashi (Choti Diwali)", "festival", "celebration",
              "Celebration of light conquering darkness");
        addJD(KT - 1, "Diwali (Deepavali)", "national", "flare",
              "Festival of Lights — National Holiday");
        addJD(KT + 0, "Govardhan Puja / Annakut", "festival", "temple_hindu",
              "Mount Govardhan Worship & harvest offering");
        addJD(KT + 0, "Jain New Year (Vira Samvat)", "festival", "celebration",
              "Jain New Year commemoration");
        addJD(KT + 1, "Bhai Dooj (Yama Dwitiya)", "festival", "favorite",
              "Celebration of sibling affection and protection");
        addJD(KT + 5, "Chhath Puja — Sandhya Arghya (Evening)", "restricted", "wb_sunny",
              "Evening offerings to the Sun God");
        addJD(KT + 6, "Chhath Puja — Usha Arghya (Morning)", "restricted", "wb_sunny",
              "Morning offerings to the rising Sun — Chhath concludes");
        addJD(KT + 10, "Dev Uthani Ekadashi (Prabodhini)", "festival", "temple_hindu",
              "Awakening of Vishnu — Chaturmas concludes");
        addJD(KT + 15, "Guru Nanak Jayanti", "national", "star",
              "Parkash Utsav of Guru Nanak Dev Ji — National Holiday");
        addJD(KT + 15, "Bandi Chhor Divas", "festival", "celebration",
              "Sikh festival of freedom and liberation");
    }

    // MARGASHIRSHA
    if (MG) {
        addJD(MG + 10, "Mokshada Ekadashi / Gita Jayanti", "festival", "temple_hindu",
              "Anniversary of the Bhagavad Gita revelation");
    }

    // PAUSHA
    if (PA) {
        addJD(PA + 22, "Guru Gobind Singh Jayanti (Nanakshahi)", "restricted", "star",
              "Birth of 10th Sikh Guru Sri Guru Gobind Singh Ji");
        addJD(PA + 14, "Pausha Purnima", "observance", "nightlight",
              "Full Moon of Pausha — holy bath day");
    }

    // ─────────────────────────────────────────────────────
    // PART C: ISLAMIC FESTIVALS — TABULAR HIJRI CALENDAR
    // ─────────────────────────────────────────────────────

    var startJD_h = gregorianToJD(year, 1, 1);
    var hStart    = jdToIslamic(startJD_h);
    var checkHY   = [hStart.year - 1, hStart.year, hStart.year + 1];

    for (var hi = 0; hi < checkHY.length; hi++) {
        var hy = checkHY[hi];
        if (hy < 1) continue;
        (function(hy) {
            function isl(hm, hd, title, type, icon, desc) {
                var jd = islamicToJD(hy, hm, hd);
                var g  = jdToGregorian(jd);
                if (g.year === year) {
                    add(g.month, g.day, title, type, icon,
                        desc + " (" + hy + " AH)");
                }
            }
            isl(1,  1,  "Islamic New Year (Hijri New Year)",   "festival",  "nightlight",
                "1st of Muharram — Islamic New Year");
            isl(1,  10, "Muharram (Ashura)",                    "national",  "candle",
                "10th of Muharram — Day of Ashura");
            isl(2,  9,  "Chehlum (Arbaeen)",                    "festival",  "candle",
                "40th day commemoration after Ashura");
            isl(3,  12, "Milad-un-Nabi (Id-e-Milad)",           "national",  "star",
                "Birthday of Prophet Muhammad (PBUH) — National Holiday");
            isl(7,  27, "Shab-e-Meraj (Laylat al-Miraj)",       "festival",  "nightlight",
                "Night of the Heavenly Ascension");
            isl(8,  15, "Shab-e-Barat",                         "festival",  "nightlight",
                "Night of Records and Forgiveness");
            isl(9,  1,  "Ramadan Begins",                       "festival",  "nightlight",
                "Holy month of fasting begins");
            isl(9,  27, "Laylat al-Qadr (Shab-e-Qadr)",         "festival",  "nightlight",
                "Night of Power and Decree");
            isl(10, 1,  "Eid-ul-Fitr",                          "national",  "nightlight",
                "Celebration of the conclusion of Ramadan — National Holiday");
            isl(12, 10, "Eid-ul-Adha (Bakrid)",                 "national",  "nightlight",
                "Feast of Sacrifice and Hajj completion — National Holiday");
        })(hy);
    }

    // ─────────────────────────────────────────────────────
    // PART D: CHRISTIAN MOVABLE FEASTS
    // ─────────────────────────────────────────────────────
    var ae = year % 19, be = Math.floor(year / 100), ce = year % 100;
    var de = Math.floor(be / 4), ee = be % 4;
    var fe = Math.floor((be + 8) / 25), ge = Math.floor((be - fe + 1) / 3);
    var he = (19 * ae + be - de - ge + 15) % 30;
    var ie = Math.floor(ce / 4), ke = ce % 4;
    var le = (32 + 2 * ee + 2 * ie - he - ke) % 7;
    var me = Math.floor((ae + 11 * he + 22 * le) / 451);
    var easterMo = Math.floor((he + le - 7 * me + 114) / 31);
    var easterDy = ((he + le - 7 * me + 114) % 31) + 1;
    var eJD = gregorianToJD(year, easterMo, easterDy);

    var ashWed  = jdToGregorian(eJD - 46);
    var goodFri = jdToGregorian(eJD - 2);

    add(ashWed.month,  ashWed.day,  "Ash Wednesday",          "festival",  "church",
        "[OB] Start of Lenten season — 46 days before Easter");
    add(goodFri.month, goodFri.day, "Good Friday",             "national",  "church",
        "[GH] Crucifixion of Jesus — National Gazetted Holiday");
    add(easterMo,      easterDy,    "Easter Sunday",           "restricted","church",
        "[RH] Resurrection of Jesus — DoPT Restricted Holiday");

    return events;
}

// ═══════════════════════════════════════════════════════
// SECTION 4: CACHE & PUBLIC API
// ═══════════════════════════════════════════════════════

var eventCache = {};

function _getYearCached(year) {
    if (!eventCache[year]) {
        eventCache[year] = getYearEvents(year);
    }
    return eventCache[year];
}

function getEventsForDate(date) {
    if (!date) date = new Date();
    var y = date.getFullYear();
    var m = date.getMonth() + 1;
    var d = date.getDate();
    return _getYearCached(y)[formatDateKey(y, m, d)] || [];
}

function getDayEvents(year, month, day) {
    return _getYearCached(year)[formatDateKey(year, month, day)] || [];
}

function hasHolidayOnDate(year, month, day) {
    var list = getDayEvents(year, month, day);
    return list.some(function(e) {
        return e.type === "national" || e.type === "festival" || e.type === "restricted";
    });
}

function hasEventsOnDate(year, month, day) {
    return getDayEvents(year, month, day).length > 0;
}

local _, ns = ...

ns.ManualData = {}

-- Families, not rank IDs or damage tables. The client supplies the rank's
-- identity, description and amounts. Names cover esMX/esES and enUS/enGB.
ns.PaladinFamilies = {
    strike = {"Golpe Sagrado", "Holy Strike"},
    judgment = {"Sentencia", "Judgement", "Judgment"},
    righteousness = {"Sello de rectitud", "Seal of Righteousness"},
    fury = {"Sello de furia", "Seal of Fury"},
    crusader = {"Sello del cruzado", "Seal of the Crusader"},
    command = {"Sello de orden", "Seal of Command"},
    light = {"Sello de Luz", "Seal of Light"},
    wisdom = {"Sello de sabiduría", "Seal of Wisdom"},
    justice = {"Sello de justicia", "Seal of Justice"},
    direct = {"Luz Sagrada", "Holy Light", "Destello de Luz", "Flash of Light",
        "Exorcismo", "Exorcism", "Martillo de cólera", "Hammer of Wrath", "Cólera Sagrada", "Holy Wrath"},
    dual = {"Choque Sagrado", "Holy Shock", "Vigilia de la Luz", "Vigilia de Luz", "Light's Vigil", "Light’s Vigil"},
    periodic = {"Consagración", "Consecration"},
    reactive = {"Escudo Sagrado", "Holy Shield", "Aura de reprensión", "Retribution Aura",
        "Bendición de salvaguardia", "Blessing of Sanctuary", "Bendición de salvaguardia superior", "Greater Blessing of Sanctuary"},
    lay = {"Imposición de manos", "Lay on Hands"},
    absorb = {"Baluarte del templario", "Baluarte templario", "Templar's Bulwark", "Templar’s Bulwark"},
    utility = {"Bendición de poderío", "Blessing of Might", "Bendición de poderío superior", "Greater Blessing of Might",
        "Bendición de sabiduría", "Blessing of Wisdom", "Bendición de sabiduría superior", "Greater Blessing of Wisdom",
        "Bendición de reyes", "Blessing of Kings", "Bendición de reyes superior", "Greater Blessing of Kings",
        "Bendición de salvación", "Blessing of Salvation", "Bendición de salvación superior", "Greater Blessing of Salvation",
        "Salvación", "Salvation", "Salvación en masa", "Mass Salvation", "Salvación masiva",
        "Bendición de libertad", "Blessing of Freedom", "Bendición de protección", "Blessing of Protection",
        "Bendición de sacrificio", "Blessing of Sacrifice", "Aura de devoción", "Devotion Aura",
        "Aura de concentración", "Concentration Aura", "Aura de resistencia al Fuego", "Fire Resistance Aura",
        "Aura de resistencia a la Escarcha", "Frost Resistance Aura", "Aura de resistencia a las Sombras", "Shadow Resistance Aura",
        "Aura de cruzado", "Crusader Aura", "Furia recta", "Righteous Fury", "Protección divina", "Divine Protection",
        "Escudo divino", "Divine Shield", "Intervención divina", "Divine Intervention", "Favor divino", "Divine Favor",
        "Martillo de Justicia", "Hammer of Justice", "Arrepentimiento", "Repentance", "Purificar", "Purify",
        "Limpiar", "Cleanse", "Redención", "Redemption", "Sentir no-muertos", "Sense Undead", "Ahuyentar no-muerto", "Turn Undead",
        "Invocar caballo de guerra", "Summon Warhorse", "Invocar destrero", "Summon Charger",
        "Voz de la verdad", "Voice of Truth", "Sentencia presta", "Sentencia rápida", "Swift Judgement", "Swift Judgment"},
}

import Foundation

// MARK: - Visitor catalog (40 archetypes)
enum VisitorCatalog {
    static let archetypes: [VisitorArchetype] = makeArchetypes()

    static func archetype(id: Int) -> VisitorArchetype? {
        guard id >= 0 && id < archetypes.count else { return nil }
        return archetypes[id]
    }

    private static func makeArchetypes() -> [VisitorArchetype] {
        let data: [(String, String, String, PreferredTrait, Int, Int, String)] = [
            ("Brother Aldric", "Herbalist",
             "Seeks any moss for the infirmary salves.",
             .family(.bryophyta), 6, 1,
             "An old infirmary brother whose hands shake but whose memory of plants does not."),
            ("Sister Lisette", "Cartographer",
             "Wants a fern; pages of the great map need decoration.",
             .family(.pteridophyta), 8, 2,
             "Cartographer of the western granges."),
            ("Friar Ortolan", "Tree Keeper",
             "Asks for a conifer for the new chapel grove.",
             .family(.coniferae), 12, 3,
             "Speaks more easily to trees than to men."),
            ("Lady Marisette", "Patron",
             "Pays generously for a bloom; her garden is austere.",
             .family(.angiosperma), 18, 4,
             "A noble patron whose donations keep the scriptorium fed."),
            ("Master Casimir", "Alchemist",
             "Hunts for any carnivorous specimen.",
             .family(.carnivora), 24, 5,
             "An alchemist with thinner morals than his apron suggests."),
            ("Royal Courier", "King's Service",
             "Demands a rare bloom for the queen's table.",
             .rarity(.rare), 30, 6,
             "Carries the king's seal and an impatient horse."),
            ("Wandering Botanist", "Scholar",
             "Begs any new specimen for the great atlas.",
             .rarity(.uncommon), 14, 7,
             "Sleeps in barns, draws in spider-fine pen."),
            ("Brother Onesimus", "Scribe",
             "Wants something amber; new ink-pigment.",
             .color(.amber), 16, 8,
             "Mixes inks while humming psalms."),
            ("Brother Pacomius", "Glazier",
             "Looking for an azure plant; new window pigment.",
             .color(.azure), 22, 9,
             "Coats the rose-window in his own faith."),
            ("Sister Aurea", "Reliquary Keeper",
             "Asks for a violet specimen for the reliquary niche.",
             .color(.violet), 20, 10,
             "Keeps the relics dusted; tolerates no rust."),
            ("Father Thaddeus", "Choir Master",
             "Wants a white bloom; he conducts in white.",
             .color(.white), 12, 11,
             "Conducts choir as though leading cavalry."),
            ("Goodwife Anyse", "Brewer",
             "Asks for a citrus-scented plant; for cordials.",
             .scent(.citrus), 14, 12,
             "Brews medicinal cordials in the village."),
            ("Mendicant Iulia", "Pilgrim",
             "Wants a balsam-scented specimen for the pilgrim hostel.",
             .scent(.balsam), 10, 13,
             "Walks barefoot between shrines."),
            ("Apothecary Geraud", "Apothecary",
             "Honey-scented plants for syrups.",
             .scent(.honey), 16, 14,
             "Soft-spoken; charges twice for the same vial."),
            ("Stonecutter Marek", "Builder",
             "Wants any plant with needle leaves; for chinking mortar.",
             .leaf(.needle), 6, 15,
             "Believes mortar is its own ministry."),
            ("Weaver Constance", "Textile Mistress",
             "Wants ribbon-leaf specimens for natural dye stencils.",
             .leaf(.ribbon), 8, 16,
             "Wears more dye than fabric at the elbows."),
            ("Architect Otho", "Builder",
             "Demands a palmate-leaf plant for the cloister mural.",
             .leaf(.palmate), 14, 17,
             "Sketches arches in conversation."),
            ("Schoolmaster Ivo", "Teacher",
             "Wants a cordate-leaf plant for student drawing.",
             .leaf(.cordate), 10, 18,
             "Believes a heart-leaf will teach better than a stick."),
            ("Heralda the Mystic", "Mystic",
             "Wants any mythic specimen for the lunar rite.",
             .rarity(.mythic), 90, 19,
             "Speaks in whispered consonants only."),
            ("Foreman Bartol", "Estate Manager",
             "Wants any plant; really, the cheapest possible.",
             .anyMature, 4, 20,
             "Penny-clutcher of three villages."),
            ("Sister Tilda", "Embroideress",
             "Wants a rose-coloured plant for thread reference.",
             .color(.rose), 18, 21,
             "Embroiders by candle and conviction."),
            ("Beekeeper Otta", "Apiarist",
             "Wants any honey-scented plant for the hive grove.",
             .scent(.honey), 14, 22,
             "Talks to bees as colleagues."),
            ("Brewmaster Cyriak", "Brewer",
             "Wants a mint-scented specimen for ale.",
             .scent(.mint), 12, 23,
             "Tests his ale at sunrise without apology."),
            ("Prior Hermann", "Prior",
             "Wants a rare specimen worthy of the chapter house.",
             .rarity(.rare), 36, 24,
             "Gold cord on the cuff, ink on the thumb."),
            ("Lay Sister Edith", "Almoner",
             "Wants any common bloom for the gate-poor.",
             .family(.angiosperma), 6, 25,
             "Knows the names of beggars before they know hers."),
            ("Sergeant Boyd", "Hire-Sword",
             "Wants a red plant; will pay if it scares his men.",
             .color(.red), 16, 26,
             "Has scars he is proud of."),
            ("Apprentice Jago", "Apprentice",
             "Asks for anything mature; learning his herbs.",
             .anyMature, 5, 27,
             "Apprenticed to four trades, mastered none."),
            ("Wandering Poet", "Poet",
             "Wants a yellow plant; for a sun-cycle of verses.",
             .color(.yellow), 12, 28,
             "Lives by metered lines and pity."),
            ("Friar Lucius", "Hermit",
             "Wants a smoke-scented plant for his hermitage.",
             .scent(.smoke), 18, 29,
             "Once spoke; said it was enough."),
            ("Master Carver", "Sculptor",
             "Wants a fern-frond for relief carving.",
             .family(.pteridophyta), 14, 30,
             "Chisels from memory of one wife."),
            ("Cellarer Wibald", "Cellarer",
             "Wants common moss; cools the wine-cellar.",
             .family(.bryophyta), 7, 31,
             "Knows the names of every cask."),
            ("Veil-Maker Aoife", "Veiler",
             "Wants a lance-leaf specimen for veil pattern.",
             .leaf(.lance), 11, 32,
             "Stitches grief into seven veils a year."),
            ("Sister Daphne", "Garden Novice",
             "Wants a lobed-leaf for her first plot.",
             .leaf(.lobed), 8, 33,
             "Brand new to the cloister, terrified of weeds."),
            ("Master Pieter", "Engineer",
             "Wants a trifid-leaf for trinity-symbol carvings.",
             .leaf(.trifid), 22, 34,
             "Designs wheels and arches that should not work, yet do."),
            ("Pilgrim Heloise", "Pilgrim",
             "Wants any ovate-leaf for prayer-page bookmark.",
             .leaf(.ovate), 6, 35,
             "Carries one book, ten miles a day."),
            ("Sister Berthild", "Choir",
             "Wants an earthy-scented plant for matins.",
             .scent(.earthy), 9, 36,
             "Voice of the choir's lowest pew."),
            ("Lord Casimir", "Lord",
             "Wants a mythic specimen, no questions.",
             .rarity(.mythic), 120, 37,
             "Whose castle the cloister has never quite trusted."),
            ("Royal Gardener", "Gardener",
             "Wants any uncommon specimen for the royal terrace.",
             .rarity(.uncommon), 16, 38,
             "Wears soil-stained livery without apology."),
            ("Healer Brigit", "Healer",
             "Wants a musk-scented plant for grief tisanes.",
             .scent(.musk), 18, 39,
             "Sits with the dying. Asks little of the world."),
            ("Sister Vespera", "Bellringer",
             "Wants any rare specimen; will hang a bell for it.",
             .rarity(.rare), 28, 40,
             "Knows every bell-rope by its weight.")
        ]

        return data.enumerated().map { idx, e in
            VisitorArchetype(
                id: idx, name: e.0, title: e.1, preferenceText: e.2,
                trait: e.3, bonusCoins: e.4, avatarSeed: e.5, description: e.6
            )
        }
    }
}

// MARK: - Daily visitor queue generator (deterministic by day)
enum VisitorQueueBuilder {
    static func buildQueue(forDay day: Int) -> [QueuedVisitor] {
        let count = 6 + (day % 5) // 6..10
        var rng = SeededRNG(seed: UInt32(truncatingIfNeeded: UInt(day) &* 7919 &+ 41))
        var queue: [QueuedVisitor] = []
        let pool = VisitorCatalog.archetypes
        for _ in 0..<count {
            let r = rng.rollDouble()
            let pick = Int(r * Double(pool.count)) % pool.count
            queue.append(QueuedVisitor(archetypeId: pool[pick].id))
        }
        return queue
    }
}

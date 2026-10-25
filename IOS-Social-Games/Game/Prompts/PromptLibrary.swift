import Foundation

// MARK: - Categories

nonisolated enum PromptCategory:
    String,
    CaseIterable,
    Codable,
    Sendable
{
    case foodAndDrink = "Food & drink"
    case places = "Places"
    case activities = "Activities"
    case jobs = "Jobs"
    case animals = "Animals"
    case householdObjects = "Household objects"
    case travel = "Travel"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case nature = "Nature"

    case musicalInstruments = "Musical instruments"
    case clothing = "Clothing"
    case technology = "Technology"
    case school = "School & university"
    case celebrations = "Celebrations"
    case fantasy = "Fantasy & legends"
    case space = "Space"
    case vehicles = "Vehicles"
    case tools = "Tools & DIY"
    case humanBody = "The human body"

    case weather = "Weather"
    case buildings = "Buildings & structures"
    case games = "Games"
    case hobbies = "Hobbies"
    case desserts = "Desserts & sweets"
    case fruit = "Fruit"
    case vegetables = "Vegetables"
    case accessories = "Accessories"
    case water = "On the water"
    case music = "Music"
}

// MARK: - Prompt model

nonisolated struct GamePrompt: Sendable {
    let text: String
    let category: PromptCategory
}

// MARK: - Library

nonisolated enum PromptLibrary {
    private static let promptsByCategory: [
        PromptCategory: [String]
    ] = [
        // MARK: Food & drink

        .foodAndDrink: [
            "Pizza",
            "Sushi",
            "Fish and chips",
            "Spaghetti",
            "Pancakes",
            "Burger",
            "Curry",
            "Coffee",
            "Hot chocolate",
            "Lemonade",
            "Cheese",
            "Popcorn",
            "Baked beans",
            "Scrambled eggs",
            "Garlic bread",
            "Soup",
            "Sandwich",
            "Milkshake",
            "Burrito",
            "Roast dinner"
        ],

        // MARK: Places

        .places: [
            "Library",
            "Supermarket",
            "Cinema",
            "Hospital",
            "Museum",
            "Zoo",
            "Restaurant",
            "Gym",
            "Swimming pool",
            "Post office",
            "Police station",
            "Shopping centre",
            "Hotel",
            "Theme park",
            "Hair salon",
            "Dentist",
            "Pet shop",
            "Bowling alley",
            "Nightclub",
            "Garden centre"
        ],

        // MARK: Activities

        .activities: [
            "Cooking dinner",
            "Dancing",
            "Gardening",
            "Fishing",
            "Camping",
            "Shopping",
            "Reading",
            "Baking",
            "Karaoke",
            "Wrapping presents",
            "Walking the dog",
            "Washing the car",
            "Building a snowman",
            "Having a picnic",
            "Flying a kite",
            "Making a sandcastle",
            "Doing laundry",
            "Moving house",
            "Putting up a tent",
            "Taking a selfie"
        ],

        // MARK: Jobs

        .jobs: [
            "Teacher",
            "Doctor",
            "Firefighter",
            "Chef",
            "Pilot",
            "Police officer",
            "Dentist",
            "Farmer",
            "Electrician",
            "Hairdresser",
            "Actor",
            "Journalist",
            "Mechanic",
            "Astronaut",
            "Librarian",
            "Plumber",
            "Veterinarian",
            "Photographer",
            "Architect",
            "Delivery driver"
        ],

        // MARK: Animals

        .animals: [
            "Dog",
            "Cat",
            "Elephant",
            "Penguin",
            "Dolphin",
            "Giraffe",
            "Lion",
            "Octopus",
            "Rabbit",
            "Owl",
            "Crocodile",
            "Kangaroo",
            "Hedgehog",
            "Flamingo",
            "Tortoise",
            "Panda",
            "Shark",
            "Butterfly",
            "Bat",
            "Snail"
        ],

        // MARK: Household objects

        .householdObjects: [
            "Toaster",
            "Kettle",
            "Sofa",
            "Mirror",
            "Vacuum cleaner",
            "Washing machine",
            "Pillow",
            "Toothbrush",
            "Clock",
            "Lamp",
            "Remote control",
            "Fridge",
            "Iron",
            "Curtains",
            "Bookshelf",
            "Doorbell",
            "Radiator",
            "Coat hanger",
            "Dishwasher",
            "Laundry basket"
        ],

        // MARK: Travel

        .travel: [
            "Suitcase",
            "Passport",
            "Airport",
            "Train station",
            "Road trip",
            "Beach holiday",
            "Ski holiday",
            "City break",
            "Backpacking",
            "Boarding pass",
            "Camping holiday",
            "Cruise holiday",
            "Tour guide",
            "Souvenir",
            "Duty-free shopping",
            "Hotel buffet",
            "Travel pillow",
            "Luggage carousel",
            "Campsite",
            "Postcard"
        ],

        // MARK: Sports

        .sports: [
            "Football",
            "Tennis",
            "Basketball",
            "Golf",
            "Cricket",
            "Rugby",
            "Boxing",
            "Swimming",
            "Cycling",
            "Skiing",
            "Skateboarding",
            "Badminton",
            "Bowling",
            "Ice hockey",
            "Table tennis",
            "Archery",
            "Gymnastics",
            "Volleyball",
            "Wrestling",
            "Surfing"
        ],

        // MARK: Entertainment

        .entertainment: [
            "Horror film",
            "Comedy film",
            "Magic show",
            "Music festival",
            "Rock concert",
            "Ballet",
            "Circus",
            "Escape room",
            "Talent show",
            "Quiz show",
            "Podcast",
            "Comic book",
            "Puppet show",
            "Stand-up comedy",
            "Soap opera",
            "Documentary",
            "Musical",
            "Cartoon",
            "Reality television",
            "Fireworks display"
        ],

        // MARK: Nature

        .nature: [
            "Volcano",
            "Waterfall",
            "Desert",
            "Rainforest",
            "Ocean",
            "Mountain",
            "River",
            "Cave",
            "Iceberg",
            "Sunflower",
            "Cactus",
            "Coral reef",
            "Forest",
            "Mushroom",
            "Pine cone",
            "Seashell",
            "Glacier",
            "Valley",
            "Bamboo",
            "Venus flytrap"
        ],

        // MARK: Musical instruments

        .musicalInstruments: [
            "Electric guitar",
            "Acoustic guitar",
            "Bass guitar",
            "Piano",
            "Drum kit",
            "Violin",
            "Trumpet",
            "Saxophone",
            "Flute",
            "Clarinet",
            "Harp",
            "Accordion",
            "Ukulele",
            "Banjo",
            "Bagpipes",
            "Harmonica",
            "Tambourine",
            "Xylophone",
            "Cello",
            "Triangle"
        ],

        // MARK: Clothing

        .clothing: [
            "Raincoat",
            "Hoodie",
            "Jeans",
            "T-shirt",
            "Wedding dress",
            "Suit",
            "Pyjamas",
            "Swimming costume",
            "Scarf",
            "Gloves",
            "Beanie",
            "Baseball cap",
            "Wellies",
            "Trainers",
            "Slippers",
            "Dressing gown",
            "Leather jacket",
            "Apron",
            "Tie",
            "Dungarees"
        ],

        // MARK: Technology

        .technology: [
            "Smartphone",
            "Laptop",
            "Tablet",
            "Smartwatch",
            "Printer",
            "Headphones",
            "Keyboard",
            "Computer mouse",
            "Webcam",
            "Drone",
            "Virtual reality headset",
            "Games console",
            "USB stick",
            "Wi-Fi router",
            "Projector",
            "Microphone",
            "Power bank",
            "3D printer",
            "Robot vacuum",
            "Walkie-talkie"
        ],

        // MARK: School & university

        .school: [
            "Homework",
            "Exam",
            "School uniform",
            "Whiteboard",
            "Textbook",
            "School assembly",
            "Lunch queue",
            "Science experiment",
            "School trip",
            "Graduation",
            "Lecture",
            "Group project",
            "Pencil case",
            "Calculator",
            "Report card",
            "Detention",
            "Sports day",
            "School bus",
            "Timetable",
            "Student accommodation"
        ],

        // MARK: Celebrations

        .celebrations: [
            "Birthday party",
            "Wedding",
            "Christmas",
            "Halloween",
            "New Year’s Eve",
            "Easter egg hunt",
            "Baby shower",
            "Graduation party",
            "Anniversary",
            "Housewarming",
            "Surprise party",
            "Fancy-dress party",
            "Retirement party",
            "Street party",
            "Bonfire Night",
            "Engagement party",
            "School prom",
            "Carnival",
            "Parade",
            "Garden party"
        ],

        // MARK: Fantasy & legends

        .fantasy: [
            "Dragon",
            "Unicorn",
            "Wizard",
            "Witch",
            "Vampire",
            "Werewolf",
            "Mermaid",
            "Fairy",
            "Ghost",
            "Zombie",
            "Goblin",
            "Troll",
            "Giant",
            "Phoenix",
            "Genie",
            "Centaur",
            "Magic wand",
            "Crystal ball",
            "Flying broomstick",
            "Invisibility cloak"
        ],

        // MARK: Space

        .space: [
            "Moon",
            "Sun",
            "Mars",
            "Saturn",
            "Rocket",
            "Space station",
            "Satellite",
            "Black hole",
            "Comet",
            "Asteroid",
            "Meteor shower",
            "Galaxy",
            "Spacesuit",
            "Lunar rover",
            "Telescope",
            "Alien",
            "Flying saucer",
            "Solar eclipse",
            "Milky Way",
            "Zero gravity"
        ],

        // MARK: Vehicles

        .vehicles: [
            "Sports car",
            "Motorbike",
            "Double-decker bus",
            "Ambulance",
            "Fire engine",
            "Tractor",
            "Campervan",
            "Limousine",
            "Taxi",
            "Lorry",
            "Aeroplane",
            "Helicopter",
            "Hot-air balloon",
            "Steam train",
            "Tram",
            "Bicycle",
            "Electric scooter",
            "Go-kart",
            "Snowmobile",
            "Forklift"
        ],

        // MARK: Tools & DIY

        .tools: [
            "Hammer",
            "Screwdriver",
            "Electric drill",
            "Saw",
            "Spanner",
            "Pliers",
            "Tape measure",
            "Spirit level",
            "Paintbrush",
            "Paint roller",
            "Ladder",
            "Sandpaper",
            "Glue gun",
            "Torch",
            "Wheelbarrow",
            "Shovel",
            "Rake",
            "Axe",
            "Workbench",
            "Toolbox"
        ],

        // MARK: The human body

        .humanBody: [
            "Heart",
            "Brain",
            "Lungs",
            "Skeleton",
            "Teeth",
            "Tongue",
            "Eyebrow",
            "Eyelashes",
            "Knee",
            "Elbow",
            "Belly button",
            "Fingernail",
            "Thumb",
            "Shoulder",
            "Spine",
            "Stomach",
            "Rib cage",
            "Ankle",
            "Ear",
            "Nose"
        ],

        // MARK: Weather

        .weather: [
            "Thunderstorm",
            "Rainbow",
            "Snow",
            "Hail",
            "Fog",
            "Drizzle",
            "Heatwave",
            "Blizzard",
            "Tornado",
            "Hurricane",
            "Frost",
            "Sleet",
            "Lightning",
            "Gale",
            "Sandstorm",
            "Rain cloud",
            "Sunshine",
            "Humidity",
            "Drought",
            "Black ice"
        ],

        // MARK: Buildings & structures

        .buildings: [
            "Castle",
            "Lighthouse",
            "Skyscraper",
            "Windmill",
            "Treehouse",
            "Igloo",
            "Pyramid",
            "Bridge",
            "Dam",
            "Stadium",
            "Cathedral",
            "Barn",
            "Greenhouse",
            "Bungalow",
            "Block of flats",
            "Watchtower",
            "Garage",
            "Shed",
            "Gazebo",
            "Underground bunker"
        ],

        // MARK: Games

        .games: [
            "Chess",
            "Monopoly",
            "Scrabble",
            "Snakes and ladders",
            "Hide-and-seek",
            "Tag",
            "Charades",
            "Bingo",
            "Poker",
            "Dominoes",
            "Jenga",
            "Twister",
            "Musical chairs",
            "Pass the parcel",
            "Rock paper scissors",
            "Noughts and crosses",
            "Hopscotch",
            "Draughts",
            "Battleships",
            "Pictionary"
        ],

        // MARK: Hobbies

        .hobbies: [
            "Birdwatching",
            "Stamp collecting",
            "Coin collecting",
            "Pottery",
            "Origami",
            "Woodworking",
            "Scrapbooking",
            "Calligraphy",
            "Model building",
            "Candle making",
            "Jewellery making",
            "Embroidery",
            "Crochet",
            "Stargazing",
            "Metal detecting",
            "Trainspotting",
            "Flower arranging",
            "Geocaching",
            "Model railway",
            "Aquarium keeping"
        ],

        // MARK: Desserts & sweets

        .desserts: [
            "Chocolate brownie",
            "Cheesecake",
            "Apple crumble",
            "Sticky toffee pudding",
            "Doughnut",
            "Cupcake",
            "Jelly",
            "Trifle",
            "Tiramisu",
            "Waffle",
            "Ice cream sundae",
            "Candy floss",
            "Toffee apple",
            "Marshmallow",
            "Fudge",
            "Lollipop",
            "Gummy bears",
            "Macaron",
            "Chocolate éclair",
            "Meringue"
        ],

        // MARK: Fruit

        .fruit: [
            "Apple",
            "Banana",
            "Orange",
            "Strawberry",
            "Raspberry",
            "Blueberry",
            "Pineapple",
            "Watermelon",
            "Mango",
            "Peach",
            "Pear",
            "Cherry",
            "Grape",
            "Kiwi",
            "Lemon",
            "Lime",
            "Coconut",
            "Pomegranate",
            "Grapefruit",
            "Passion fruit"
        ],

        // MARK: Vegetables

        .vegetables: [
            "Carrot",
            "Potato",
            "Broccoli",
            "Cauliflower",
            "Cabbage",
            "Lettuce",
            "Spinach",
            "Onion",
            "Garlic",
            "Leek",
            "Celery",
            "Asparagus",
            "Brussels sprouts",
            "Parsnip",
            "Turnip",
            "Beetroot",
            "Radish",
            "Kale",
            "Sweet potato",
            "Artichoke"
        ],

        // MARK: Accessories

        .accessories: [
            "Sunglasses",
            "Wristwatch",
            "Necklace",
            "Bracelet",
            "Earrings",
            "Ring",
            "Handbag",
            "Backpack",
            "Wallet",
            "Purse",
            "Belt",
            "Hairband",
            "Hair clip",
            "Cufflinks",
            "Brooch",
            "Keyring",
            "Pocket watch",
            "Bow tie",
            "Suspenders",
            "Glasses case"
        ],

        // MARK: On the water

        .water: [
            "Sailing boat",
            "Speedboat",
            "Canoe",
            "Kayak",
            "Submarine",
            "Ferry",
            "Cruise ship",
            "Jet ski",
            "Paddleboard",
            "Surfboard",
            "Lifeboat",
            "Fishing boat",
            "Gondola",
            "Raft",
            "Pedalo",
            "Anchor",
            "Life jacket",
            "Diving board",
            "Snorkel",
            "Wetsuit"
        ],

        // MARK: Music

        .music: [
            "Lullaby",
            "National anthem",
            "Christmas carol",
            "Nursery rhyme",
            "Love song",
            "Guitar solo",
            "Drum solo",
            "Choir",
            "Orchestra",
            "Boy band",
            "Rock band",
            "DJ",
            "Music video",
            "Vinyl record",
            "Cassette tape",
            "Recording studio",
            "Rehearsal",
            "Encore",
            "Mosh pit",
            "Sheet music"
        ]
    ]

    // MARK: - Selection

    static func random() -> GamePrompt {
        guard let category = PromptCategory.allCases.randomElement(),
              let text = promptsByCategory[category]?.randomElement()
        else {
            return GamePrompt(
                text: "Coffee",
                category: .foodAndDrink
            )
        }

        return GamePrompt(
            text: text,
            category: category
        )
    }

    // MARK: - Library information

    static var categoryCount: Int {
        PromptCategory.allCases.count
    }

    static var promptCount: Int {
        promptsByCategory.values.reduce(0) {
            $0 + $1.count
        }
    }

    static func prompts(
        in category: PromptCategory
    ) -> [GamePrompt] {
        (promptsByCategory[category] ?? []).map { text in
            GamePrompt(
                text: text,
                category: category
            )
        }
    }
}

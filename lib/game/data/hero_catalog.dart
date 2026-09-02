class HeroDefinition {
  final String id;
  final String name;
  final String role;
  final String description;
  final int price;
  final int hp;
  final int damage;
  final double speed;
  final int skillDamage;
  final bool starter;

  const HeroDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.price,
    required this.hp,
    required this.damage,
    required this.speed,
    required this.skillDamage,
    this.starter = false,
  });
}

const heroCatalog = <HeroDefinition>[
  HeroDefinition(id: 'astra', name: 'Astra', role: 'Fighter', description: 'Pejuang seimbang dengan serangan cepat.', price: 0, hp: 320, damage: 28, speed: 185, skillDamage: 75, starter: true),
  HeroDefinition(id: 'bronn', name: 'Bronn', role: 'Tank', description: 'Pelindung garis depan dengan HP besar.', price: 700, hp: 520, damage: 22, speed: 145, skillDamage: 95),
  HeroDefinition(id: 'nyx', name: 'Nyx', role: 'Assassin', description: 'Lincah, cepat dan berbahaya dari jarak dekat.', price: 1200, hp: 260, damage: 42, speed: 225, skillDamage: 125),
  HeroDefinition(id: 'lyra', name: 'Lyra', role: 'Mage', description: 'Penyihir dengan burst area yang kuat.', price: 1500, hp: 285, damage: 34, speed: 170, skillDamage: 145),
  HeroDefinition(id: 'kael', name: 'Kael', role: 'Marksman', description: 'Penembak jarak jauh dengan damage konsisten.', price: 1800, hp: 275, damage: 48, speed: 180, skillDamage: 115),
  HeroDefinition(id: 'mira', name: 'Mira', role: 'Support', description: 'Pendukung tim dengan skill pemulihan.', price: 1000, hp: 350, damage: 20, speed: 175, skillDamage: 60),
  HeroDefinition(id: 'orion', name: 'Orion', role: 'Warrior', description: 'Petarung berat dengan serangan dahsyat.', price: 2200, hp: 460, damage: 55, speed: 155, skillDamage: 155),
  HeroDefinition(id: 'zeno', name: 'Zeno', role: 'Mage', description: 'Pengendali energi dengan serangan area.', price: 2500, hp: 300, damage: 39, speed: 165, skillDamage: 175),
];

const skinCatalog = <Map<String, Object>>[
  {'id': 'astra_default', 'hero': 'astra', 'name': 'Astra Classic', 'price': 0},
  {'id': 'astra_neon', 'hero': 'astra', 'name': 'Astra Neon', 'price': 900},
  {'id': 'bronn_iron', 'hero': 'bronn', 'name': 'Bronn Iron Guard', 'price': 1100},
  {'id': 'nyx_shadow', 'hero': 'nyx', 'name': 'Nyx Shadow', 'price': 1400},
  {'id': 'lyra_arcane', 'hero': 'lyra', 'name': 'Lyra Arcane', 'price': 1600},
];

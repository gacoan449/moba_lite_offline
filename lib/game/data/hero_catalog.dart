class HeroDefinition {
  final String id,name,role,description; final int price,hp,damage,skillDamage; final double speed; final bool starter;
  const HeroDefinition({required this.id,required this.name,required this.role,required this.description,required this.price,required this.hp,required this.damage,required this.speed,required this.skillDamage,this.starter=false});
}
const heroCatalog=<HeroDefinition>[
 HeroDefinition(id:'astra',name:'Astra',role:'Fighter',description:'Pejuang energi seimbang.',price:0,hp:380,damage:34,speed:210,skillDamage:95,starter:true),
 HeroDefinition(id:'bronn',name:'Bronn',role:'Tank',description:'Benteng garis depan.',price:700,hp:650,damage:24,speed:155,skillDamage:105),
 HeroDefinition(id:'nyx',name:'Nyx',role:'Assassin',description:'Pemburu bayangan lincah.',price:1200,hp:300,damage:48,speed:245,skillDamage:150),
 HeroDefinition(id:'lyra',name:'Lyra',role:'Mage',description:'Pengendali kristal.',price:1500,hp:320,damage:38,speed:180,skillDamage:175),
 HeroDefinition(id:'kael',name:'Kael',role:'Marksman',description:'Penembak presisi.',price:1800,hp:310,damage:52,speed:195,skillDamage:135),
 HeroDefinition(id:'mira',name:'Mira',role:'Support',description:'Penyembuh tim.',price:1000,hp:390,damage:23,speed:185,skillDamage:70),
 HeroDefinition(id:'orion',name:'Orion',role:'Warrior',description:'Petarung brutal.',price:2200,hp:540,damage:58,speed:165,skillDamage:165),
 HeroDefinition(id:'zeno',name:'Zeno',role:'Mage',description:'Penyihir petir.',price:2500,hp:330,damage:43,speed:175,skillDamage:190),
 HeroDefinition(id:'rivena',name:'Rivena',role:'Fighter',description:'Duelist pedang plasma.',price:1600,hp:430,damage:47,speed:205,skillDamage:125),
 HeroDefinition(id:'drax',name:'Drax',role:'Tank',description:'Golem baja.',price:1900,hp:720,damage:27,speed:135,skillDamage:115),
 HeroDefinition(id:'selene',name:'Selene',role:'Marksman',description:'Pemanah cahaya.',price:2100,hp:300,damage:55,speed:205,skillDamage:145),
 HeroDefinition(id:'vex',name:'Vex',role:'Assassin',description:'Pembunuh teleport.',price:2300,hp:285,damage:61,speed:255,skillDamage:180),
 HeroDefinition(id:'ember',name:'Ember',role:'Mage',description:'Pengendali api.',price:1700,hp:340,damage:40,speed:180,skillDamage:205),
 HeroDefinition(id:'talon',name:'Talon',role:'Fighter',description:'Lancer garis depan.',price:1400,hp:450,damage:45,speed:190,skillDamage:135),
 HeroDefinition(id:'nora',name:'Nora',role:'Support',description:'Penjaga hutan.',price:1300,hp:420,damage:25,speed:180,skillDamage:90),
 HeroDefinition(id:'kaida',name:'Kaida',role:'Assassin',description:'Rogue berantai.',price:2600,hp:295,damage:64,speed:260,skillDamage:195),
 HeroDefinition(id:'atlas',name:'Atlas',role:'Tank',description:'Raksasa batu.',price:2800,hp:780,damage:30,speed:125,skillDamage:130),
 HeroDefinition(id:'luma',name:'Luma',role:'Mage',description:'Pengguna gravitasi.',price:2400,hp:350,damage:45,speed:170,skillDamage:215),
 HeroDefinition(id:'ragnar',name:'Ragnar',role:'Warrior',description:'Berserker tangguh.',price:3000,hp:560,damage:62,speed:175,skillDamage:175),
 HeroDefinition(id:'iris',name:'Iris',role:'Marksman',description:'Gunner futuristik.',price:2700,hp:315,damage:58,speed:215,skillDamage:155),
];
const skinCatalog=<Map<String,Object>>[
 {'id':'astra_default','hero':'astra','name':'Astra Classic','price':0},{'id':'astra_neon','hero':'astra','name':'Astra Neon','price':900},{'id':'bronn_iron','hero':'bronn','name':'Bronn Iron Guard','price':1100},{'id':'nyx_shadow','hero':'nyx','name':'Nyx Shadow','price':1400},{'id':'lyra_arcane','hero':'lyra','name':'Lyra Arcane','price':1600},
];

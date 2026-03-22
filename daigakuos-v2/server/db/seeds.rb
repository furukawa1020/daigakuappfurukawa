MokoTemplate.destroy_all

templates = [
  { code: 'moko_egg', name: 'モコたまご (Egg)', description: 'まだ何の変哲もないタマゴ。集中すると孵化するかも？', image_url: 'assets/moko_phases/egg.png', required_level: 1, phase: 1 },
  { code: 'moko_baby', name: 'ベビーモコ (Baby)', description: '殻を破って生まれた小さなモコ。', image_url: 'assets/moko_phases/baby.png', required_level: 2, phase: 2 },
  { code: 'moko_child', name: 'キッズモコ (Child)', description: '少し成長して活発になったモコ。', image_url: 'assets/moko_phases/child.png', required_level: 5, phase: 3 },
  { code: 'moko_teen', name: 'ティーンモコ (Teen)', description: '反抗期に入ったモコ。集中力が試される。', image_url: 'assets/moko_phases/teen.png', required_level: 10, phase: 4 },
  { code: 'moko_adult', name: 'マスターモコ (Adult)', description: '立派に成長した大人モコ。あなたを常に支える。', image_url: 'assets/moko_phases/adult.png', required_level: 20, phase: 5 },
  { code: 'moko_king', name: 'キングモコ (King)', description: 'すべてのモコの頂点に立つ王様。', image_url: 'assets/moko_phases/king.png', required_level: 50, phase: 6 },
  
  # New Expansions
  { code: 'moko_angel', name: 'エンジェルモコ', description: '早朝の集中セッションを重ねると現れる神秘のモコ。', image_url: 'assets/moko_special/angel.png', required_level: 15, phase: 0 },
  { code: 'moko_devil', name: 'デビルモコ', description: '深夜に限界を超えて集中すると現れるダークなモコ。', image_url: 'assets/moko_special/devil.png', required_level: 15, phase: 0 },
  { code: 'moko_sakura', name: 'サクラモコ', description: '春限定で出現するお花見好きなモコ。', image_url: 'assets/moko_special/sakura.png', required_level: 25, phase: 0 },
  { code: 'moko_ninja', name: '忍者モコ', description: '影のように静かに集中するプロフェッショナルモコ。', image_url: 'assets/moko_special/ninja.png', required_level: 30, phase: 0 }
]

MokoTemplate.create!(templates)
puts "Seeded #{MokoTemplate.count} Moko templates."

# ruby_native/core/skill_registry.rb

class SkillRegistry
  @skills = {}

  def self.define(&block)
    builder = SkillBuilder.new
    builder.instance_eval(&block)
    @skills.merge!(builder.skills)
  end

  def self.get(id)
    @skills[id]
  end

  def self.all
    @skills
  end
end

class SkillBuilder
  attr_reader :skills

  def initialize
    @skills = {}
  end

  def skill(id, &block)
    definition = SkillDefinition.new(id)
    definition.instance_eval(&block)
    @skills[id] = definition.to_h
  end
end

class SkillDefinition
  def initialize(id)
    @id = id
    @data = { id: id.to_s, name: id.to_s.capitalize }
  end

  def name(val); @data[:name] = val; end
  def damage(val); @data[:base_damage] = val; end
  def type(val); @data[:type] = val; end
  def message(val); @data[:message] = val; end
  def drain_stamina(val); @data[:drain_stamina] = val; end

  def to_h
    @data
  end
end

# --- DEFINE THE SORCERY ---
SkillRegistry.define do
  skill :normal_attack do
    name "薙ぎ払い"
    damage 15
    type :physical
  end

  skill :data_void do
    name "データの虚無"
    damage 5
    type :mental
    message "意識の同期が途切れる..."
  end

  skill :chaos_breath do
    name "カオス・ブレス"
    damage 30
    type :chaos
    message "混沌の息吹が細胞を蝕む！"
  end

  skill :entropy_surge do
    name "エントロピー暴走"
    damage 50
    type :ultimate
    message "世界が崩壊の淵に立つ！"
  end
end

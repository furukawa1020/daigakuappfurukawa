class MokoDefinition
  attr_reader :moko_id, :behaviors

  def initialize(moko_id)
    @moko_id = moko_id
    @behaviors = {}
  end

  # DSL method to define on_sync behavior
  def on_sync(&block)
    @behaviors[:on_sync] = block
  end

  # DSL method to define evolution rules
  def evolution_rule(&block)
    @behaviors[:evolution_rule] = block
  end

  def self.define(moko_id, &block)
    definition = new(moko_id)
    definition.instance_eval(&block)
    Registry.register(moko_id, definition)
  end

  class Registry
    @definitions = {}
    
    def self.register(id, definition)
      @definitions[id] = definition
    end
    
    def self.get(id)
      @definitions[id]
    end
  end
end

class MokoDefinition
  attr_reader :moko_id, :on_sync_block, :evolution_block, :on_global_event_block

  def initialize(moko_id)
    @moko_id = moko_id
  end

  # DSL methods
  def on_sync(&block); @on_sync_block = block; end
  def evolution_rule(&block); @evolution_block = block; end
  def on_global_event(&block); @on_global_event_block = block; end

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

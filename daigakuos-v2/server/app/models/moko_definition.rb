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

  # DSL method to  def on_sync(&block); @on_sync = block; end
  def evolution_rule(&block); @evolution_rule = block; end
  def on_global_event(&block); @on_global_event = block; end
  
  attr_reader :on_sync_block, :evolution_block, :on_global_event_block
  
  def initialize(name)
    @name = name
  end

  def define(&block)
    instance_eval(&block)
    @on_sync_block = @on_sync
    @evolution_block = @evolution_rule
    @on_global_event_block = @on_global_event
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

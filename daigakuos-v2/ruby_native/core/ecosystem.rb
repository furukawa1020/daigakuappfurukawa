# ruby_native/core/ecosystem.rb
class Ecosystem
  # 🍏 Metabolic Simulation: Task Rot and Oxygen
  MAX_TOXINS = 100.0
  MAX_OXYGEN = 100.0

  def self.tick(state, elapsed_hours)
    # 🌫️ Calculate Rot (Toxins)
    # The more tasks are in the "backlog" (chaos_level), the more toxins are produced per hour.
    chaos = state[:user][:chaos_level] || 0.0
    order = state[:user][:order_level] || 0.0
    
    # 🍏 Base Rot: Chaos induces toxin production.
    # High chaos = faster rot.
    rot_multiplier = 2.0 + (chaos * 8.0)
    new_toxins = (state[:environment][:toxins] || 0.0) + (rot_multiplier * elapsed_hours)
    
    # 🌿 Base Oxygen: Order (Streak) induces oxygen production.
    oxygen_multiplier = 1.0 + (order * 5.0)
    new_oxygen = (state[:environment][:oxygen] || 0.0) + (oxygen_multiplier * elapsed_hours)

    # ⚖️ Equilibrium
    # Oxygen neutralizes Toxins over time.
    neutralization = (new_oxygen / 10.0) * elapsed_hours
    
    state[:environment][:toxins] = [new_toxins - neutralization, 0.0].max.clamp(0.0, MAX_TOXINS)
    state[:environment][:oxygen] = [new_oxygen - (new_toxins / 20.0), 0.0].max.clamp(0.0, MAX_OXYGEN)

    # 🌑 Global Entropy Impact
    state[:global_entropy] = (state[:environment][:toxins] / MAX_TOXINS).clamp(0.0, 1.0)
    
    state
  end

  def self.apply_metabolic_effects(user_state, env_state)
    toxin_ratio = env_state[:toxins] / MAX_TOXINS
    oxygen_ratio = env_state[:oxygen] / MAX_OXYGEN

    # 🌫️ Toxins drain max stamina and cause slow HP decay.
    user_state[:max_stamina] = (100.0 * (1.0 - toxin_ratio * 0.3)).to_i
    user_state[:hp_decay_rate] = (toxin_ratio * 2.0) # HP per hour
    
    # 🍏 Oxygen boosts resonance and recovery.
    user_state[:stamina_recovery_bonus] = (oxygen_ratio * 5.0) # Stamina per hour
    
    user_state
  end
end

# ruby_native/core/alchemist.rb

class Alchemist
  RECIPES = {
    ['moko_herb', 'moko_honey'] => 'moko_potion',
    ['blueprint_alpha', 'blueprint_beta'] => 'ancient_focus_core',
    ['toxin_residue', 'order_crystal'] => 'neutralizing_shimmer',
    ['monster_bone', 'iron_ore'] => 'moko_blade_v2',
    ['toxin_residue', 'moko_honey'] => 'probiotic_brew',
    ['moko_herb', 'monster_bone'] => 'prebiotic_fiber'
  }

  def self.combine(item_a, item_b)
    # Sort keys to ensure order doesn't matter
    ingredients = [item_a, item_b].sort
    
    result_item = RECIPES[ingredients]
    
    if result_item
      {
        success: true,
        item: result_item,
        message: "【成功】新しいアイテム「#{result_item}」を錬成しました！🐾"
      }
    else
      {
        success: false,
        message: "【失敗】不純物が混ざり、錬成に失敗しました..."
      }
    end
  end
end

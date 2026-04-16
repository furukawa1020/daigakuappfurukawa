class RaidReportService
  # Generates a summary report of a global raid battle.
  
  def self.generate_summary(raid)
    return "No raid found." unless raid
    
    participants = raid.participants_data
    total_damage = participants.values.sum
    
    report = "⚔️ **Raid Report: #{raid.title}** ⚔️\n"
    report += "---------------------------------\n"
    report += "Status: #{raid.status.upcase}\n"
    report += "Total Focus Damage: #{total_damage}\n"
    report += "Number of Heroes: #{participants.keys.size}\n\n"
    
    report += "**Top Contributors:**\n"
    participants.to_a.sort_by { |_, dmg| -dmg }.first(5).each_with_index do |(name, dmg), i|
      report += "#{i+1}. #{name}: #{dmg} dmg\n"
    end
    
    report
  end

  def self.broadcast_final_report(raid)
    summary = generate_summary(raid)
    ActionCable.server.broadcast("raid_channel", {
      type: "final_report",
      raid_title: raid.title,
      summary: summary
    })
  end
end

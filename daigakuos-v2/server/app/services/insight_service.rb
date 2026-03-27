class InsightService
  def initialize(user)
    @user = user
  end

  def generate_focus_insights
    insights = []
    
    # Analyze best time of day
    best_time = analyze_peak_focus_hours
    insights << "あなたは #{best_time}時頃に最も集中できているようです。その時間を大切にしましょう！" if best_time

    # Analyze streak health
    if @user.streak_days > 7
      insights << "現在#{@user.streak_days}日間継続中！この勢いで頑張りましょう。"
    elsif @user.streak_days > 0
      insights << "継続は力なり！まずは3日間を目指しましょう。"
    end

    # Analyze Moko interactions
    favorite_moko = @user.moko_items.group(:name).count.max_by { |_, v| v }&.first
    insights << "#{favorite_moko}があなたのことを応援していますよ！" if favorite_moko

    insights
  end

  private

  def analyze_peak_focus_hours
    return nil if @user.focus_sessions.empty?
    
    # Group by hour and count
    hours = @user.focus_sessions.pluck(:start_time).map { |t| t.in_time_zone.hour }
    counts = hours.group_by(&:itself).transform_values(&:count)
    counts.max_by { |_, v| v }&.first
  end
end

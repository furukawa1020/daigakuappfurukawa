class RankingService
  CACHE_KEY = "global_leaderboard_v1"
  CACHE_EXPIRY = 1.hour

  def self.top_100
    # Use ActiveSupport::Cache to store the leaderboard for performance.
    # This prevents hitting the database with heavy ORDER BY/LIMIT queries on every request.
    # The cache is automatically invalidated after 1 hour.
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
      User.order(level: :desc, xp: :desc)
          .limit(100)
          .select(:id, :username, :level, :xp, :streak)
          .as_json
    end
  end

  def self.invalidate_cache
    Rails.cache.delete(CACHE_KEY)
  end
end

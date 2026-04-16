class MokoGiftJob < ApplicationJob
  queue_as :default

  def perform(sender_id)
    sender = User.find_by(id: sender_id)
    return unless sender

    # Find a potential recipient (active in the last 24h)
    recipient = User.where.not(id: sender.id)
                    .where('last_sync_at > ?', 24.hours.ago)
                    .sample
    
    return unless recipient

    # Decide on a gift (e.g., 5-20 coins)
    gift_amount = rand(5..20)
    recipient.update!(coins: recipient.coins + gift_amount)
    
    # Broadcast the news!
    msg = "#{sender.username}のモコが、#{recipient.username}のモコに#{gift_amount}コインをプレゼントしました！🎁"
    msg = MokoGrammarService.mokofize(msg)

    # Record the event for the recipient
    recipient.social_events.create!(
      event_type: "gift_received",
      metadata: { from: sender.username, amount: gift_amount, message: msg }
    )
    
    ActionCable.server.broadcast("activity_feed", {
      type: "moko_gift",
      message: msg,
      occurred_at: Time.current
    })
    
    Rails.logger.info "[MokoGift] #{sender.username} sent #{gift_amount} coins to #{recipient.username}"
  end
end

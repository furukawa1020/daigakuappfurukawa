ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
  duration = (finish - start) * 1000 # convert to ms
  Rails.logger.info "[PERF] #{payload[:method]} #{payload[:path]} - #{duration.round(2)}ms (Status: #{payload[:status]})"
end

ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
  duration = (finish - start) * 1000 # convert to ms
  if duration > 100 # log slow queries
    Rails.logger.warn "[SLOW SQL] #{payload[:sql]} - #{duration.round(2)}ms"
  end
end

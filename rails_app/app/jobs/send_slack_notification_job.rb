# frozen_string_literal: true

# Send a message to the provided webhook URL in credentials
class SendSlackNotificationJob
  include Sidekiq::Job

  sidekiq_options queue: 'high'

  def perform(message)
    webhook_url = Settings.slack.webhook_url
    return if webhook_url.blank?

    slack = Faraday.new(webhook_url, headers: { 'Content-Type' => 'application/json' })
    message = "#{Rails.env}: #{message}" # Prepend environment name
    response = slack.post('', "{text: '#{message}'}")
    response.body
  end
end

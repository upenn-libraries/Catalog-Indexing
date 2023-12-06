# frozen_string_literal: true

# Send a message to the provided webhook URL in credentials
class SendSlackNotificationJob
  include Sidekiq::Job

  def perform(message)
    webhook_url = Rails.application.credentials.slack_webhook_url
    return if webhook_url.blank?

    slack = Faraday.new(webhook_url, headers: { 'Content-Type' => 'application/json' })

    response = slack.post('', "{text: '#{message}'}")
    response.body
  end
end

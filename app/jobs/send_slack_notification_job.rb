class SendSlackNotificationJob
  include Sidekiq::Job

  def perform(message)
    webhook_url = Rails.application.credentials.slack_webhook_url
    return unless webhook_url.present?

    slack = Faraday.new(webhook_url, headers: {'Content-Type' => 'application/json'})

    response = slack.post('', "{text: '#{message}'}")
    response.body
  end
end
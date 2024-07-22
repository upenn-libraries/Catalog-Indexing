# frozen_string_literal: true

module Steps
  module Sftp
    # Step to initialize Sftp session to Alma files server
    class Session
      include Dry::Monads[:result]

      # @return [Dry::Monads::Result]
      def call(**args)
        Success(sftp_session: Sftp::Client.new, **args)
      rescue Sftp::Client::Error => e
        Failure("Problem connecting to the SFTP server: #{e.message}")
      end
    end
  end
end

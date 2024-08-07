# frozen_string_literal: true

module Steps
  module AlmaExport
    module Sftp
      # Step to initialize Sftp session to Alma files server
      class OpenSession
        include Dry::Monads[:result]

        # @return [Dry::Monads::Result]
        def call(**args)
          Success(sftp_session: ::Sftp::Client.new, **args)
        rescue ::Sftp::Client::Error => e
          Failure(exception: e)
        end
      end
    end
  end
end

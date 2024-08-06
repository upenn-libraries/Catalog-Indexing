# frozen_string_literal: true

module Steps
  module AlmaExport
    module Sftp
      # Step to close Sftp session to Alma files server
      class CloseSession
        include Dry::Monads[:result]

        # @param sftp_session [Sftp::Client]
        # @return [Dry::Monads::Result]
        def call(sftp_session:, **args)
          sftp_session.close_channel
          Success(**args)
        rescue ::Sftp::Client::Error => e
          Failure(exception: e)
        end
      end
    end
  end
end

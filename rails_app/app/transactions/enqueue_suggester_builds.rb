# frozen_string_literal: true

require 'dry/transaction'

# After an indexing operation is complete, decide whether to rebuild suggesters
# for the given AlmaExport and enqueue the corresponding build jobs. This should be easily adaptable
# to control future additional suggester builds.
class EnqueueSuggesterBuilds
  include Dry::Transaction(container: Container)

  step :check_suggester_builds_enabled
  step :enqueue_title_suggester_build

  private

  # Signal not to run the transaction unless suggester builds are enabled via the ConfigItem for this export type.
  #
  # @param alma_export [AlmaExport]
  # @return [Dry::Monads::Result]
  def check_suggester_builds_enabled(alma_export:)
    config_key = alma_export.full? ? :build_suggesters_after_full : :build_suggesters_after_incremental
    return Success(alma_export: alma_export, bypass: true) unless ConfigItem.value_for(config_key)

    Success(alma_export: alma_export, bypass: false)
  end

  # Enqueue the title suggester build job if configured to do so, returning the appropriate message.
  #
  # @param alma_export [AlmaExport]
  # @return [Dry::Monads::Result]
  def enqueue_title_suggester_build(alma_export:, bypass:)
    return Success(message: 'Suggester builds disabled.') if bypass

    BuildTitleSuggestDictionaryJob.perform_async if build_title_suggester?(alma_export)

    Success(message: 'Suggester builds enqueued.')
  end

  # Whether the title suggester should be rebuilt for the given export. This checks the application
  # settings.
  #
  # @param alma_export [AlmaExport]
  # @return [Boolean]
  def build_title_suggester?(alma_export)
    settings = Settings.suggester.title
    return settings.build_after_full if alma_export.full?

    settings.build_after_incremental
  end
end

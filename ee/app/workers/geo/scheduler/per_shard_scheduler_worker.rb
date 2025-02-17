# frozen_string_literal: true

module Geo
  module Scheduler
    class PerShardSchedulerWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :geo_replication

      # These workers are enqueued every minute by sidekiq-cron. If one of them
      # is already enqueued or running, then there isn't a strong case for
      # enqueuing another. And there are edge cases where enqueuing another
      # would exacerbate a problem. See
      # https://gitlab.com/gitlab-org/gitlab/-/issues/328057.
      deduplicate :until_executed

      def perform; end
    end
  end
end

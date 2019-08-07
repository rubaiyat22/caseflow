# frozen_string_literal: true

BATCH_SIZE = 1000

class UpdateCachedAppealsAttributesJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper
  queue_as :low_priority

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = UpdateCachedAppealsAttributesJob.name.underscore

  def perform
    start_time = Time.zone.now

    cache_ama_appeals
    cache_legacy_appeals

    record_runtime(start_time)
  rescue StandardError => error
    log_error(start_time, error)
  end

  def cache_ama_appeals
    appeals_ids_to_cache = Task.open.where(appeal_type: Appeal.name).pluck(:appeal_id).uniq

    appeals_to_cache = Appeal.find(appeals_ids_to_cache).map do |appeal|
      {
        appeal_id: appeal.id,
        docket_type: appeal.docket_type,
        docket_number: appeal.docket_number,
        appeal_type: Appeal.name,
        case_type: Appeal.type,
        is_aod: Appeal.aod
      }
    end

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type, :case_type, :is_aod] }

    increment_appeal_count(appeals_to_cache.length, Appeal.name)
  end

  def cache_legacy_appeals
    legacy_appeals = LegacyAppeal.find(Task.open.where(appeal_type: LegacyAppeal.name).pluck(:appeal_id).uniq)

    cache_legacy_appeal_postgres_data(legacy_appeals)
    cache_legacy_appeal_vacols_data(legacy_appeals)

    increment_appeal_count(legacy_appeals.length, LegacyAppeal.name)
  end

  def cache_legacy_appeal_postgres_data(legacy_appeals)
    values_to_cache = legacy_appeals.map do |appeal|
      {
        appeal_id: appeal.id,
        appeal_type: LegacyAppeal.name,
        vacols_id: appeal.vacols_id,
        docket_type: appeal.docket_name # "legacy"
      }
    end

    CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type] }
  end

  def cache_legacy_appeal_vacols_data(legacy_appeals)
    legacy_appeals.pluck(:vacols_id).in_groups_of(BATCH_SIZE, false).each do |vacols_ids|
      values_to_cache = VACOLS::Folder.where(ticknum: vacols_ids)
        .pluck(:ticknum, :tinum)
        .map do |vacols_folder|
        { vacols_id: vacols_folder[0], docket_number: vacols_folder[1] }
      end
      values_to_cache.each do |value|
        bfac = VACOLS::Case.where(bfkey: value[:vacols_id]).pluck(:bfac)
        value[:case_type] = VACOLS::Case::BFAC_TYPE_CACHE_KEY[bfac[0]]
        aod = VACOLS::Case.joins(VACOLS::Case::JOIN_AOD)
          .where(bfkey: value[:vacols_id])
          .pluck(:aod)
        value[:is_aod] = !!aod[0]
      end

      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:vacols_id],
                                                                      columns: [:docket_number, :case_type, :is_aod] }
    end
  end

  def increment_appeal_count(count, appeal_type)
    count.times do
      DataDogService.increment_counter(
        app_name: APP_NAME,
        metric_group: METRIC_GROUP_NAME,
        metric_name: "appeals_to_cache",
        attrs: {
          type: appeal_type
        }
      )
    end
  end

  def record_runtime(start_time)
    job_duration_seconds = Time.zone.now - start_time

    DataDogService.emit_gauge(
      app_name: APP_NAME,
      metric_group: METRIC_GROUP_NAME,
      metric_name: "runtime",
      metric_value: job_duration_seconds
    )
  end

  def log_error(start_time, err)
    duration = time_ago_in_words(start_time)
    msg = "UpdateCachedAppealsAttributesJob failed after running for #{duration}. Fatal error: #{err.message}"

    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    slack_service.send_notification(msg)

    record_runtime(start_time)
  end
end

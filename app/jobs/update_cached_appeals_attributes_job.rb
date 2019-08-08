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
    appeals = Appeal.find(Task.open.where(appeal_type: Appeal.name).pluck(:appeal_id).uniq)
    veteran_names_to_cache = veteran_names_for_appeals(appeals)

    appeals_to_cache = appeals.map do |appeal|
      regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
      {
        appeal_id: appeal.id,
        docket_type: appeal.docket_type,
        docket_number: appeal.docket_number,
        appeal_type: Appeal.name,
        closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE,
        veteran_name: veteran_names_to_cache[appeal.veteran_file_number]
      }
    end

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                     columns: [
                                                                       :closest_regional_office_city,
                                                                       :veteran_name
                                                                     ] }

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
      regional_office = RegionalOffice::CITIES[appeal.closest_regional_office]
      {
        appeal_id: appeal.id,
        appeal_type: LegacyAppeal.name,
        vacols_id: appeal.vacols_id,
        docket_type: appeal.docket_name, # "legacy"
        closest_regional_office_city: regional_office ? regional_office[:city] : COPY::UNKNOWN_REGIONAL_OFFICE
      }
    end

    CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:appeal_id, :appeal_type],
                                                                    columns: [:closest_regional_office_city] }
  end

  def cache_legacy_appeal_vacols_data(legacy_appeals)
    legacy_appeals.pluck(:vacols_id).in_groups_of(BATCH_SIZE, false).each do |vacols_ids|
      vacols_folders = VACOLS::Folder.where(ticknum: vacols_ids).pluck(:ticknum, :tinum, :ticorkey)
      veteran_names_to_cache = veteran_names_for_correspondent_ids(vacols_folders.map { |folder| folder[2] })

      values_to_cache = vacols_folders.map do |vacols_folder|
        {
          vacols_id: vacols_folder[0],
          docket_number: vacols_folder[1],
          veteran_name: veteran_names_to_cache[vacols_folder[2]]
        }
      end

      CachedAppeal.import values_to_cache, on_duplicate_key_update: { conflict_target: [:vacols_id],
                                                                      columns: [:docket_number, :veteran_name] }
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

  private

  def veteran_names_for_appeals(appeals)
    Veteran.where(file_number: appeals.pluck(:veteran_file_number)).map do |veteran|
      # Matches how last names are split and sorted on the front end (see: TaskTable.detailsColumn.getSortValue)
      [veteran.file_number, "#{veteran.last_name.split(' ').last}, #{veteran.first_name}"]
    end.to_h
  end

  def veteran_names_for_correspondent_ids(correspondent_ids)
    # folders is an array of [ticknum, tinum, ticorkey] for each folder
    VACOLS::Correspondent.where(stafkey: correspondent_ids).map do |corr|
      [corr.stafkey, "#{corr.snamel.split(' ').last}, #{corr.snamef}"]
    end.to_h
  end
end

# frozen_string_literal: true

class IntakeStartValidator
  def initialize(intake:)
    @intake = intake
  end

  def validate
    return false unless validate_file_number

    validate_veteran
    validate_intake

    !intake.error_code
  end

  private

  attr_reader :intake

  delegate :veteran_file_number, :veteran, :error_code, :errors, to: :intake

  def validate_veteran
    if !veteran
      intake.error_code = :veteran_not_found
    elsif !veteran.accessible?
      set_veteran_accessible_error
    elsif !user_may_modify_veteran_file?
      intake.error_code = :veteran_not_modifiable
    elsif veteran.incident_flash?
      intake.error_code = :incident_flash
    end
  end

  def validate_intake
    if duplicate_intake_in_progress
      intake.error_code = :duplicate_intake_in_progress
      intake.store_error_data(processed_by: duplicate_intake_in_progress.user.full_name)
    end
  end

  def validate_file_number
    if !file_number_valid?
      intake.error_code = :invalid_file_number
    elsif file_number_reserved?
      intake.error_code = :reserved_veteran_file_number
    end

    !error_code
  end

  def set_veteran_accessible_error
    return unless !veteran.accessible?

    intake.error_code = veteran.multiple_phone_numbers? ? :veteran_has_multiple_phone_numbers : :veteran_not_accessible
  end

  def duplicate_intake_in_progress
    @duplicate_intake_in_progress ||=
      Intake.in_progress.find_by(type: intake.type, veteran_file_number: veteran_file_number)
  end

  def file_number_valid?
    return false unless veteran_file_number

    veteran_file_number =~ /^[0-9]{8,9}$/
  end

  def file_number_reserved?
    FeatureToggle.enabled?(:intake_reserved_file_number,
                           user: RequestStore[:current_user]) && veteran_file_number == "123456789"
  end

  def user_may_modify_veteran_file?
    BGSService.new.may_modify?(veteran_file_number)
  end
end

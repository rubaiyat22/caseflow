# frozen_string_literal: true

require "json"

class Api::V3::HigherLevelReviewPreintake
  attr_reader :higher_level_review

  unless (CATEGORIES_BY_BENEFIT_TYPE = JSON.parse(File.read("client/constants/ISSUE_CATEGORIES.json")))
    fail StandardError, "couldn't pull nonrating issue categories from ISSUE_CATEGORIES.json"
  end

  def initialize(hash)
    @errors = []

    attributes = params[:data][:attributes]
    relationships = params[:data][:relationships]
    included = params[:included]

    @receipt_date = attributes[:receipt_date]
    @informal_conference = attributes[:informal_conference]
    @same_office = attributes[:same_office]
    @legacy_opt_in_approved = attributes[:legacy_opt_in_approved]
    @benefit_type = attributes[:benefit_type]

    @veteran_file_number = relationships[:veteran][:data][:id]

    @claimant_participant_id = relationships.dig :claimant, :data, :id
    @claimant_payee_code = relationships.dig :claimant, :data, :meta, :payeeCode

    @request_issues = included.reduce([]) do |acc, included_item|
      next acc unless included_item[:type] == "RequestIssue"

      request_issue, error = json_api_included_request_issue_to_intake_data_hash(included_item)

      if error
        @errors << error
        next acc 
      end

      acc << request_issue
    end
  end

  def errors
    errors.empty? ? nil : errors
  end

  def complete_review!
    transaction do
      intake = Intake.build(
        user: current_user,
        veteran_file_number: @veteran_file_number,
        form_type: "higher_level_review"
      )

      render error unless intake.start!
      render error unless intake.review! review_params
      render error unless intake.complete! complete_params
      @higher_level_review = intake.detal
    end
  end

  private

  # returns a 2 element array: [params, error]
  # open question: where will attributes[:request_issue_ids] go?
  def json_api_included_request_issue_to_intake_data_hash(request_issue)
    attributes = request_issue[:attributes]

    if contests == "on_file_legacy_issue" && !@legacy_opt_in_approved
      return [
        nil,
        {
          status: 422,
          title: "Adding legacy issue without opting in",
          code: :adding_legacy_issue_without_opting_in
        }
      ]
    end

    category = attributes[:category]

    unless category.in? CATEGORIES_BY_BENEFIT_TYPE[@benefit_type] 
      return [
        nil,
        {
          status: 422,
          title: "Unknown category for benefit type",
          code: :unknown_category_for_benefit_type
        }
      ]
    end

    id = attributes[:id]
    identified = @benefit_type.present? && category.present?

    [
      {
        rating_issue_reference_id: contests == "on_file_rating_issue" ? id : nil,
        rating_issue_diagnostic_code: nil,
        decision_text: attributes[:decision_text],
        decision_date: attributes[:decision_date],
        nonrating_issue_category: category,
        benefit_type: @benefit_type,
        notes: attributes[:notes],
        is_unidentified: !identified,
        untimely_exemption: nil,
        untimely_exemption_notes: nil,
        ramp_claim_id: nil,
        vacols_id: contests == "on_file_legacy_issue" ? id : nil,
        vacols_sequence_id: nil,
        contested_decision_issue_id: contests == "on_file_decision_issue" ? id : nil,
        ineligible_reason: nil,
        ineligible_due_to_id: nil,
        edited_description: nil,
        correction_type: nil
      },
      nil
    ]
  end

  def review_params
    ActionController::Parameters.new(
      informal_conference: @informal_conference,
      same_office: @same_office,
      benefit_type: @benefit_type,
      receipt_date: @receipt_date,
      claimant: @claimant_participant_id,
      veteran_is_not_claimant: @claimant_participant_id.present? && @claimant_payee_code.present?,
      payee_code: @claimant_payee_code,
      legacy_opt_in_approved: @legacy_opt_in_approved
    )
  end

  def complete_params
    ActionController::Parameters.new request_issues: @request_issues
  end

end

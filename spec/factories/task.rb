# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    assigned_at { rand(30..35).days.ago }
    assigned_by { create(:user) }
    assigned_to { create(:user) }
    appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    action { nil }
    type { Task.name }

    trait :in_progress do
      status { Constants.TASK_STATUSES.in_progress }
      started_at { rand(1..10).days.ago }
    end

    trait :on_hold do
      status { Constants.TASK_STATUSES.on_hold }
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration { [30, 60, 90].sample }
    end

    trait :completed_hold do
      status { Constants.TASK_STATUSES.on_hold }
      started_at { rand(25..30).days.ago }
      placed_on_hold_at { rand(15..25).days.ago }
      on_hold_duration { 10 }
    end

    trait :completed do
      status { Constants.TASK_STATUSES.completed }
      started_at { rand(20..30).days.ago }
      placed_on_hold_at { rand(1..10).days.ago }
      on_hold_duration { [30, 60, 90].sample }
      closed_at { Time.zone.now }
    end

    factory :root_task, class: RootTask do
      type { RootTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
      assigned_to { Bva.singleton }
    end

    factory :distribution_task, class: DistributionTask do
      type { DistributionTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
      assigned_to { Bva.singleton }
      status { Constants.TASK_STATUSES.on_hold }
    end

    factory :generic_task, class: GenericTask do
      type { GenericTask.name }
      appeal { create(:appeal) }
    end

    factory :privacy_act_task, class: PrivacyActTask do
      type { PrivacyActTask.name }
      appeal { create(:appeal) }
    end

    factory :timed_hold_task, class: TimedHoldTask do
      type { TimedHoldTask.name }
      appeal { create(:appeal) }
      assigned_to { create(:user) }
      days_on_hold { rand(1..100) }
      parent { create(:generic_task) }
    end

    factory :colocated_task, class: ColocatedTask do
      type { ColocatedTask.name }
      parent { create(:generic_task) }

      factory :ama_colocated_task, class: ColocatedTask do
        appeal { create(:appeal) }
      end

      after(:build) do |task|
        example_instructions = {
          ihp: "Hello. It appears that the VSO has not reviewed this case and has not provided an IHP.",
          poa_clarification: "We received some correspondence from the Veteran's attorney in November " \
                             "indicating the attorney wants to withdraw from representation of the Veteran. " \
                             "I don't see any paperwork from the Veteran appointing a new rep or otherwise " \
                             "acknowledging the withdraw of the old one. Please contact the Veteran to " \
                             "clarify if they have current representation. If the Veteran no longer " \
                             "wishes the current representative to act on his behalf, please get that in writing.",
          hearing_clarification: "A March statement filed by the Veteran indicates that they desired " \
                                 "a 'Televideo conference hearing' for all their appeals. No hearing " \
                                 "was scheduled. Please clarify whether the Veteran still desires a " \
                                 "Board hearing, and, if so, please reroute as necessary to schedule one. Thanks!",
          aoj: "Please clarify whether the Veteran desires AOJ review of any evidence, to include VA " \
               "treatment records dated through June, submitted since an April statement of the case. Thank you!",
          extension: "The Veteran's POA submitted a letter requesting a 90 day extension. Please send " \
                     "letter granting the extension.",
          missing_hearing_transcripts: "Good evening, could you please return this to the hearing " \
                                       "branch as the hearing was just held and the transcripts are " \
                                       "not yet available. Thank you.",
          unaccredited_rep: "Unaccredited rep",
          foia: "The Veteran's representative submitted FOIA request in December of last year, which " \
                "was acknowledged the same month. To date, there has been no response provided. " \
                "Please follow up on the FOIA request.",
          retired_vlj: "VLJ Snuffy conducted the hearing in June. Since they are now retired, the " \
                       "Veteran needs to be provided notice of this and an opportunity to request " \
                       "hearing before another VLJ.",
          arneson: "email was sent re Arneson letter/ the Veteran needing to be offered a third hearing.",
          new_rep_arguments: "The Veteran recently switched to a new POA. Please determine if the " \
                             "new POA will provide new arguments for the issues on appeal.",
          pending_scanning_vbms: "There is a pending scanning banner in VBMS indicating documents " \
                                 "from November are pending scanning. The last documents uploaded " \
                                 "to the file are from October. Please hold the case in abeyance " \
                                 "for 2 weeks to allow the documents to be uploaded and the PSB to clear.",
          address_verification: "VACOLS and Caseflow lists two different addresses for the Veteran. " \
                                "From reviewing the recent documents in the file, it appears that " \
                                "the address in Caseflow is the most recent address. Please verify " \
                                "the Veteran's current address and update VACOLS if warranted.",
          schedule_hearing: "The Veteran has requested a Board hearing as to all appealed issues. " \
                            "To date, no Board hearing has been scheduled.",
          missing_records: "The Veteran had a Board Video Conference Hearing in September with " \
                          "Judge Snuffy. The Hearing transcripts are not of record.",
          translation: "There are multiple document files that still require translation from " \
                       "Spanish to English. The files in Spanish have been marked in Caseflow. " \
                       "Please have these documents translated. Thank you!",
          other: "Please request a waiver of AOJ consideration for new evidence"
        }

        # Create a RootTask for this appeal unless one already exists because ColocatedTasks with the schedule_hearing
        # action can create ScheduleHearingTasks which require the appeal to have a RootTask.
        # github.com/department-of-veterans-affairs/caseflow
        #   /blob/2bf6503e7f0888abc3222caaba499d8e7db14ae4/app/models/tasks/colocated_task.rb#L134
        RootTask.create!(appeal: task.appeal) unless task.appeal.root_task

        action = task.action || Constants::CO_LOCATED_ADMIN_ACTIONS.keys.sample
        task.update!(action: action, instructions: [example_instructions[action.to_sym]]) if task.instructions.empty?
      end
    end

    factory :ama_judge_task, class: JudgeAssignTask do
      type { JudgeAssignTask.name }
      appeal { create(:appeal) }
    end

    factory :disposition_task, class: DispositionTask do
      type { DispositionTask.name }
      assigned_to { Bva.singleton }
      appeal { create(:appeal) }
      parent { create(:hearing_task) }
    end

    factory :change_hearing_disposition_task, class: ChangeHearingDispositionTask do
      type { ChangeHearingDispositionTask.name }
      assigned_to { HearingAdmin.singleton }
      appeal { create(:appeal) }
    end

    factory :ama_judge_decision_review_task, class: JudgeDecisionReviewTask do
      type { JudgeDecisionReviewTask.name }
      appeal { create(:appeal) }
    end

    factory :ama_judge_quality_review_task, class: JudgeQualityReviewTask do
      type { JudgeQualityReviewTask.name }
      appeal { create(:appeal) }
    end

    factory :ama_judge_dispatch_return_task, class: JudgeDispatchReturnTask do
      type { JudgeDispatchReturnTask.name }
      appeal { create(:appeal) }
      parent { create(:root_task, appeal: appeal) }
    end

    factory :track_veteran_task, class: TrackVeteranTask do
      type { TrackVeteranTask.name }
      appeal { create(:appeal) }
    end

    factory :translation_task, class: TranslationTask do
      type { TranslationTask.name }
      appeal { create(:appeal) }
    end

    factory :hearing_task, class: HearingTask do
      type { HearingTask.name }
      assigned_to { Bva.singleton }
      appeal { create(:appeal) }
    end

    factory :schedule_hearing_task, class: ScheduleHearingTask do
      type { ScheduleHearingTask.name }
      appeal { create(:appeal) }
      assigned_to { Bva.singleton }
      parent { create(:hearing_task, appeal: appeal) }
    end

    factory :no_show_hearing_task, class: NoShowHearingTask do
      type { NoShowHearingTask.name }
      appeal { create(:appeal) }
      assigned_to { HearingsManagement.singleton }
      parent { create(:disposition_task, appeal: appeal) }
    end

    factory :evidence_submission_window_task, class: EvidenceSubmissionWindowTask do
      type { EvidenceSubmissionWindowTask.name }
      appeal { create(:appeal) }
      assigned_to { HearingsManagement.singleton }
      parent { create(:disposition_task, appeal: appeal) }
    end

    factory :ama_attorney_task, class: AttorneyTask do
      type { AttorneyTask.name }
      appeal { create(:appeal) }
      parent { create(:ama_judge_decision_review_task) }
      assigned_by { create(:user) }
      assigned_to { create(:user) }

      after(:build) do |_task, evaluator|
        if evaluator.assigned_by
          existing_staff_record = VACOLS::Staff.where(
            sdomainid: evaluator.assigned_by.css_id, svlj: "J", sactive: "A"
          ).first
          create(:staff, :judge_role, user: evaluator.assigned_by) if existing_staff_record.blank?
        end

        if evaluator.assigned_to
          existing_staff_record = VACOLS::Staff.where(sdomainid: evaluator.assigned_to.css_id, sactive: "A").first
          create(:staff, :attorney_role, user: evaluator.assigned_to) if existing_staff_record.blank?
        end
      end
    end

    factory :ama_judge_dispatch_return_to_attorney_task, class: AttorneyDispatchReturnTask do
      type { AttorneyDispatchReturnTask.name }
      appeal { create(:appeal) }
      parent { create(:ama_judge_decision_review_task) }
    end

    factory :transcription_task, class: TranscriptionTask do
      type { TranscriptionTask.name }
      appeal { create(:appeal) }
      parent { create(:root_task, appeal: appeal) }
      assigned_to { TranscriptionTeam.singleton }
    end

    factory :ama_vso_task, class: GenericTask do
      type { GenericTask.name }
      appeal { create(:appeal) }
      parent { create(:root_task) }
    end

    factory :qr_task, class: QualityReviewTask do
      type { QualityReviewTask.name }
      appeal { create(:appeal) }
      parent { create(:root_task) }
      assigned_by { nil }
      assigned_to { QualityReview.singleton }
    end

    factory :quality_review_task, class: QualityReviewTask do
      type { QualityReviewTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :bva_dispatch_task, class: BvaDispatchTask do
      type { BvaDispatchTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :hearing_admin_action_task, class: HearingAdminActionTask do
      type { HearingAdminActionTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :hearing_admin_action_incarcerated_veteran_task, class: HearingAdminActionIncarceratedVeteranTask do
      type { HearingAdminActionIncarceratedVeteranTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :hearing_admin_action_verify_address_task, class: HearingAdminActionVerifyAddressTask do
      type { HearingAdminActionVerifyAddressTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :informal_hearing_presentation_task, class: InformalHearingPresentationTask do
      type { InformalHearingPresentationTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :appeal_task, class: DecisionReviewTask do
      type { DecisionReviewTask.name }
      appeal { create(:appeal, benefit_type: "education") }
      assigned_by { nil }
    end

    factory :higher_level_review_task, class: DecisionReviewTask do
      type { DecisionReviewTask.name }
      appeal { create(:higher_level_review, benefit_type: "education") }
      assigned_by { nil }
    end

    factory :board_grant_effectuation_task, class: BoardGrantEffectuationTask do
      type { BoardGrantEffectuationTask.name }
      appeal { create(:appeal) }
      assigned_by { nil }
    end

    factory :veteran_record_request_task, class: VeteranRecordRequest do
      type { VeteranRecordRequest.name }
      appeal { create(:appeal) }
      parent { create(:root_task) }
      assigned_by { nil }
    end
  end
end

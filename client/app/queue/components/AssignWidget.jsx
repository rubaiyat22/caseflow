import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  setSavePending,
  resetSaveState,
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee,
  setSelectedAssigneeSecondary
} from '../uiReducer/uiActions';
import { requestDistribution } from '../QueueActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import _ from 'lodash';
import pluralize from 'pluralize';
import COPY from '../../../COPY.json';
import { sprintf } from 'sprintf-js';
import { fullWidth } from '../constants';
import QueueFlowModal from './QueueFlowModal';

const OTHER = 'OTHER';

class AssignWidget extends React.PureComponent {
  submit = () => {
    const { selectedAssignee, selectedAssigneeSecondary, selectedTasks } = this.props;

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_TASK_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_TASK_DETAIL });

      return;
    }

    if (selectedAssignee !== OTHER) {
      return this.assignTasks(selectedTasks, selectedAssignee);
    }

    if (!selectedAssigneeSecondary) {
      this.props.showErrorMessage(
        { title: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_TITLE,
          detail: COPY.ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL });

      return;
    }

    return this.assignTasks(selectedTasks, selectedAssigneeSecondary);
  }

  assignTasks = (selectedTasks, assigneeId) => {
    const {
      previousAssigneeId,
      userId
    } = this.props;

    this.props.setSavePending();

    return this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId,
        previousAssigneeId }).
      then(() => {
        this.props.resetSaveState();

        return this.props.showSuccessMessage({
          title: sprintf(COPY.ASSIGN_WIDGET_SUCCESS, {
            verb: this.props.assignedVerb || 'Assigned',
            numCases: selectedTasks.length,
            casePlural: pluralize('case', selectedTasks.length)
          })
        });
      }, () => {
        this.props.resetSaveState();

        const errorDetail = this.props.isModal && userId ?
          <React.Fragment>
            <Link to={`/queue/${userId}/assign`}>{COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL_MODAL}</Link>
          </React.Fragment> : COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_DETAIL;

        return this.props.showErrorMessage({
          title: COPY.ASSIGN_WIDGET_ASSIGNMENT_ERROR_TITLE,
          detail: errorDetail });
      });
  }

  requestDistributionSubmit = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
    // Note: the default value of "" will never be used, and will fail on the backend.
    // Even though this code path will never be hit unless we have a value for userId,
    // Flow complains without a default value.
    this.props.requestDistribution(this.props.userId || '');
  }

  render = () => {
    const {
      attorneysOfJudge,
      selectedAssignee,
      selectedAssigneeSecondary,
      attorneys,
      selectedTasks,
      savePending,
      distributionLoading
    } = this.props;
    const optionFromAttorney = (attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() });
    const options = attorneysOfJudge.map(optionFromAttorney).concat([{ label: COPY.ASSIGN_WIDGET_OTHER,
      value: OTHER }]);
    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);
    let optionsOther = [];
    let placeholderOther = COPY.ASSIGN_WIDGET_LOADING;
    let selectedOptionOther = null;

    if (attorneys.data) {
      optionsOther = attorneys.data.map(optionFromAttorney);
      placeholderOther = COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER;
      selectedOptionOther = _.find(optionsOther, (option) => option.value === selectedAssigneeSecondary);
    }

    if (attorneys.error) {
      placeholderOther = COPY.ASSIGN_WIDGET_ERROR_LOADING_ATTORNEYS;
    }

    const Widget = <React.Fragment>
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
        '& > *': { marginRight: '1rem',
          marginTop: '0',
          marginBottom: '16px' } })}>
        <p>{COPY.ASSIGN_WIDGET_DROPDOWN_PRIMARY_LABEL}</p>
        <SearchableDropdown
          name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_PRIMARY}
          hideLabel
          searchable
          options={options}
          placeholder={COPY.ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER}
          onChange={(option) => option && this.props.setSelectedAssignee({ assigneeId: option.value })}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        {selectedAssignee === OTHER &&
          <React.Fragment>
            <div {...fullWidth} {...css({ marginBottom: '0' })} />
            <p>{COPY.ASSIGN_WIDGET_DROPDOWN_SECONDARY_LABEL}</p>
            <SearchableDropdown
              name={COPY.ASSIGN_WIDGET_DROPDOWN_NAME_SECONDARY}
              hideLabel
              searchable
              options={optionsOther}
              placeholder={placeholderOther}
              onChange={(option) => option && this.props.setSelectedAssigneeSecondary({ assigneeId: option.value })}
              value={selectedOptionOther}
              styling={css({ width: '30rem' })} />
          </React.Fragment>}
        {!this.props.isModal && <Button
          onClick={this.submit}
          name={sprintf(
            COPY.ASSIGN_WIDGET_BUTTON_TEXT,
            { numCases: selectedTasks.length,
              casePlural: pluralize('case', selectedTasks.length) })}
          loading={savePending}
          loadingText={COPY.ASSIGN_WIDGET_LOADING} /> }
        {this.props.userId && this.props.showRequestCasesButton &&
          <div {...css({ marginLeft: 'auto' })}>
            <Button
              name="Request more cases"
              onClick={this.requestDistributionSubmit}
              loading={distributionLoading}
              classNames={['usa-button-secondary', 'cf-push-right']} />
          </div>
        }
      </div>
    </React.Fragment>;

    return this.props.isModal ? <QueueFlowModal title={COPY.ASSIGN_WIDGET_MODAL_TITLE} submit={this.submit}>
      {Widget}
    </QueueFlowModal> : Widget;
  }
}

const mapStateToProps = (state) => {
  const { attorneysOfJudge, attorneys, pendingDistribution } = state.queue;
  const { selectedAssignee, selectedAssigneeSecondary, featureToggles } = state.ui;
  const { savePending } = state.ui.saveState;

  return {
    attorneysOfJudge,
    selectedAssignee,
    selectedAssigneeSecondary,
    attorneys,
    distributionLoading: pendingDistribution !== null,
    savePending,
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSavePending,
  resetSaveState,
  setSelectedAssignee,
  setSelectedAssigneeSecondary,
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestDistribution
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(AssignWidget));

export const AssignWidgetModal = (connect(mapStateToProps, mapDispatchToProps)(AssignWidget));

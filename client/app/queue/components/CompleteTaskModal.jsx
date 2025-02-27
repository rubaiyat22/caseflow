import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import TextareaField from '../../components/TextareaField';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop } from '../constants';
import COPY from '../../../COPY.json';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import { taskActionData } from '../utils';

import QueueFlowModal from './QueueFlowModal';

const SEND_TO_LOCATION_MODAL_TYPE_ATTRS = {
  mark_task_complete: {
    buildSuccessMsg: (appeal, { assignerName }) => ({
      title: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteranFullName),
      detail: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, assignerName)
    }),
    title: () => COPY.MARK_TASK_COMPLETE_TITLE,
    getContent: ({ props, state, setState }) => {
      const taskConfiguration = taskActionData(props);

      return <React.Fragment>
        {
          taskConfiguration && taskConfiguration.modal_body
        }
        {
          (!taskConfiguration || !taskConfiguration.modal_hide_instructions) &&
          <TextareaField
            label="Instructions:"
            name="instructions"
            id="completeTaskInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          />
        }
      </React.Fragment>
      ;
    },
    buttonText: COPY.MARK_TASK_COMPLETE_BUTTON
  },
  send_colocated_task: {
    buildSuccessMsg: (appeal, { teamName }) => ({
      title: sprintf(
        COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION,
        appeal.veteranFullName, teamName
      )
    }),
    title: ({ teamName }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: ({ appeal, teamName }) => <React.Fragment>
      {sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, appeal.veteranFullName, appeal.veteranFileNumber)}&nbsp;
      <strong>{teamName}</strong>.
    </React.Fragment>,
    buttonText: COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
  }
};

class CompleteTaskModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      instructions: ''
    };
  }
  getTaskAssignerName = () => {
    const { task: { assignedBy } } = this.props;

    // Tasks created by the application (tasks for quality review or dispatch) will not have assigners.
    // TODO: Amend copy to better explain what is going on instead of having a blank field where we expect
    // to see somebody's name.
    if (!assignedBy.firstName.codePointAt(0)) {
      return '';
    }

    return `${String.fromCodePoint(assignedBy.firstName.codePointAt(0))}. ${assignedBy.lastName}`;
  };
  getContentArgs = () => ({
    assignerName: this.getTaskAssignerName(),
    teamName: this.props.task.label,
    appeal: this.props.appeal,
    props: this.props,
    state: this.state,
    setState: this.setState.bind(this)
  });

  submit = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          status: 'completed',
          instructions: this.state.instructions
        }
      }
    };
    const successMsg = SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].
      buildSuccessMsg(appeal, this.getContentArgs());

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    return <QueueFlowModal
      title={SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].title(this.getContentArgs())}
      button={SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].buttonText}
      submit={this.submit}
    >
      {this.props.task ? SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].
        getContent(this.getContentArgs()) : null}
    </QueueFlowModal>;
  };
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(CompleteTaskModal)));

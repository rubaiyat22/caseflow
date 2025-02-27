import { ACTIONS } from './actionTypes';

export const onReceiveRegionalOffices = (regionalOffices) => ({
  type: ACTIONS.RECEIVE_REGIONAL_OFFICES,
  payload: {
    regionalOffices
  }
});

export const onRegionalOfficeChange = (regionalOffice) => ({
  type: ACTIONS.REGIONAL_OFFICE_CHANGE,
  payload: {
    regionalOffice
  }
});

export const onReceiveHearingDays = (hearingDays) => ({
  type: ACTIONS.RECEIVE_HEARING_DAYS,
  payload: {
    hearingDays
  }
});

export const onFetchDropdownData = (dropdownName) => ({
  type: ACTIONS.FETCH_DROPDOWN_DATA,
  payload: {
    dropdownName
  }
});

export const onReceiveDropdownData = (dropdownName, data) => ({
  type: ACTIONS.RECEIVE_DROPDOWN_DATA,
  payload: {
    dropdownName,
    data
  }
});

export const onDropdownError = (dropdownName, errorMsg) => ({
  type: ACTIONS.DROPDOWN_ERROR,
  payload: {
    dropdownName,
    errorMsg
  }
});

export const onHearingOptionalTime = (optionalTime) => ({
  type: ACTIONS.HEARING_OPTIONAL_TIME_CHANGE,
  payload: {
    optionalTime
  }
});

export const onChangeFormData = (formName, formData) => ({
  type: ACTIONS.CHANGE_FORM_DATA,
  payload: {
    formName,
    formData
  }
});

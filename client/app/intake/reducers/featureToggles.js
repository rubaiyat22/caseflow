import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    withdrawDecisionReviews: {
      $set: Boolean(featureToggles.withdrawDecisionReviews)
    },
    editContentionText: {
      $set: Boolean(featureToggles.editContentionText)
    },
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) => (
  updateFromServerFeatures({
    useAmaActivationDate: false,
    withdrawDecisionReviews: false,
    editContentionText: false,
    correctClaimReviews: false
  }, data.featureToggles)
);

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};

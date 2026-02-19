// This is just a wrapper for preference type IDs to their components.
// Intentionally dumber than TGUI prefs.
// Keep it simple, stupid.

// If you change this, make sure to update the preferences define file too.

import {
  CheckboxInput,
  CheckboxInputInverse,
  FeatureColorInput,
  FeatureDropdownInput,
  FeatureIconnedDropdownInput,
  FeatureNumberInput,
  FeatureShortTextInput,
  FeatureTextInput,
  FeatureTriColorInput,
  FeatureValue,
} from '../PreferencesMenu/preferences/features/base';

export const PREFERENCE_ID_TO_COMPONENT: Record<
  string,
  FeatureValue<unknown, unknown, unknown>
> = {
  color: FeatureColorInput,
  checkbox: CheckboxInput,
  checkbox_inverse: CheckboxInputInverse,
  dropdown: FeatureDropdownInput,
  iconned_dropdown: FeatureIconnedDropdownInput,
  number: FeatureNumberInput,
  large_text: FeatureTextInput,
  short_text: FeatureShortTextInput,
  tri_color: FeatureTriColorInput,
};

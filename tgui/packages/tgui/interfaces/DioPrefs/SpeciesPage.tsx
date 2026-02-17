import { useBackend } from '../../backend';
import { PreferencesData } from './Preferences';

export const SpeciesPage = (props) => {
  const { data } = useBackend<PreferencesData>();
};

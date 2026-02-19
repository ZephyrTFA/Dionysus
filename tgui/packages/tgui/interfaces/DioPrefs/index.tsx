import { useBackend, useLocalState } from '../../backend';
import { Window } from '../../layouts';
import { PreferencesMenuData } from '../PreferencesMenu/data';
import { AppearancePage } from './AppearancePage';
import { CharacterSelect } from './CharacterSelectPage';
import { DioPrefsPage } from './Preferences';

export const DioPrefs = (props) => {
  const { data } = useBackend<PreferencesMenuData>();
  const [current_page] = useLocalState('DioPrefs_page', DioPrefsPage.SELECT);

  let page;

  switch (current_page) {
    case DioPrefsPage.SELECT:
      page = <CharacterSelect />;
      break;
    case DioPrefsPage.APPEARANCE:
      page = <AppearancePage />;
      break;
    default:
      page = <CharacterSelect />;
      break;
  }

  return (
    <Window title={current_page} theme="rounded_base" width={920} height={770}>
      {page}
    </Window>
  );
};

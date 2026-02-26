import { Button } from 'tgui-core/components';

import { useBackend, useLocalState } from '../../backend';
import { Stack } from '../../components';
import { Window } from '../../layouts';
import { PreferencesMenuData } from '../PreferencesMenu/data';
import { AppearancePage } from './AppearancePage';
import { CharacterSelect } from './CharacterSelectPage';
import { DioPrefsPage } from './Preferences';

export const DioPrefs = (props) => {
  const { data } = useBackend<PreferencesMenuData>();
  const [current_page, setCurrentPage] = useLocalState(
    'DioPrefs_page',
    DioPrefsPage.SELECT,
  );

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
      <Stack vertical fill>
        <Stack.Item>
          <Button onClick={() => setCurrentPage(DioPrefsPage.SELECT)}>
            Select
          </Button>
        </Stack.Item>
        <Stack.Item height="100%">{page}</Stack.Item>
      </Stack>
    </Window>
  );
};

import { useBackend, useLocalState } from '../../backend';
import { ByondUi, Stack } from '../../components';
import { PreferencesMenuData } from '../PreferencesMenu/data';

export enum DioPrefsPage {
  APPEARANCE = 'Appearance',
  JOBS = 'Jobs',
  LORE = 'Lore',
  MARKINGS = 'Markings',
  OOC = 'OOC',
  RECORDS = 'Records',
  SELECT = 'Select',
  SKILLS = 'Skills',
  SPECIES = 'Species',
}

export const CharacterPreview = (props) => {
  const { data } = useBackend<PreferencesMenuData>();
  const [current_page] = useLocalState('DioPrefs_page', DioPrefsPage.SELECT);

  return (
    <Stack vertical width="220px" height="100%" pt="5px" pb="5px">
      <Stack.Item>
        [1] [2] [3] [4]
        {current_page === DioPrefsPage.SPECIES && <> [M] [F]</>}
      </Stack.Item>
      <Stack.Item height="100%">
        <ByondUi
          width="220px"
          height="100%"
          params={{
            id: props.id,
            type: 'map',
          }}
        />
      </Stack.Item>
      <Stack.Item>{'<<< [BACKGROUND_NAME] >>>'}</Stack.Item>
    </Stack>
  );
};

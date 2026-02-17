import { useBackend, useLocalState } from '../../backend';
import { ByondUi, Stack } from '../../components';
import { Window } from '../../layouts';
import { CharacterSelect } from './CharacterSelectPage';

export type PreferencesData = {
  byondui_ref: String;
  characters: Object;
};

export const DioPrefs = (props) => {
  const { data } = useBackend<PreferencesData>();
  return (
    <Window>
      <CharacterSelect />
    </Window>
  );
};

export enum DioPrefsPage {
  APPEARANCE,
  JOBS,
  LORE,
  MARKINGS,
  OOC,
  RECORDS,
  SELECT,
  SKILLS,
  SPECIES,
}

export const CharacterPreview = (props) => {
  const { data } = useBackend<PreferencesData>();
  const [current_page] = useLocalState('DioPrefs_page', DioPrefsPage.SELECT);

  return (
    <Stack vertical>
      <Stack.Item>
        [1] [2] [3] [4]
        {current_page === DioPrefsPage.SPECIES && <> [M] [F]</>}
      </Stack.Item>
      <Stack.Item>
        <ByondUi
          className="DioPreferences__preview"
          params={{ id: data.byondui_ref }}
        />
      </Stack.Item>
      <Stack.Item />
    </Stack>
  );
};

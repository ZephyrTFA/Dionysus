import { Button } from 'tgui-core/components';

import { useBackend, useLocalState } from '../../backend';
import { Box, Stack } from '../../components';
import { Image } from '../../components/Image';
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
  const { data, act } = useBackend<PreferencesMenuData>();
  const [current_page] = useLocalState('DioPrefs_page', DioPrefsPage.SELECT);

  return (
    <Stack vertical height="100%" pt="5px" pb="5px">
      <Stack.Item>
        [1] [2] [3] [4]
        {current_page === DioPrefsPage.SPECIES && <> [M] [F]</>}
      </Stack.Item>
      <Stack.Item height="100%">
        {/* <ByondUi
          width="220px"
          height="100%"
          params={{
            id: props.id,
            type: 'map',
          }}
        /> */}
        <Image
          className="DioPrefs__CharacterPreview"
          src={`data:image/png;base64,${data.character_preview_icon}`}
        />
      </Stack.Item>
      <Stack.Item align="center" width="100%" basis="0" height="100px">
        <Button icon="arrow-left" ml="2px" />
        <Box inline align="center" width="107px">
          Background
        </Box>
        <Button icon="arrow-right" />
      </Stack.Item>
    </Stack>
  );
};

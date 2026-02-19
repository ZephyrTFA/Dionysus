import { useBackend, useLocalState } from '../../backend';
import { Section, Stack } from '../../components';
import { CharacterDoll, Part } from '../../components/CharacterDoll';
import { PreferencesMenuData } from '../PreferencesMenu/data';
import { CharacterPreview } from './Preferences';

// These consts make thinking about this 1000% easier.
const DOLL_SIZE = 32 * 10;
const CENTER = 32 * 0.484375;

export const AppearancePage = (props) => {
  const { data } = useBackend<PreferencesMenuData>();
  const [selectedPart, setSelectedPart] = useLocalState<null | Part>(
    'DioPrefs_selected_part',
    null,
  );

  return (
    <Stack fill>
      <Stack.Item>
        <CharacterDoll dollSize={DOLL_SIZE} parts={parts} center={CENTER} />
      </Stack.Item>
      <Stack.Item width="100%">
        <Stack vertical>
          <Section
            title={
              selectedPart
                ? `Organs of ${selectedPart?.name}`
                : 'No part selected'
            }
          >
            Part
          </Section>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <CharacterPreview />
      </Stack.Item>
    </Stack>
  );
};

// These are all in sprite-space pixels
// These should *probably* be DM-controlled in the future for species specific stuff...
// but I honestly don't see any species bucking this trend for now, and this has less moving parts.
const parts: Record<string, Part> = {
  HEAD: {
    name: 'Head',
    pos: { x: CENTER, y: 6, width: 10, height: 10 },
  },
  L_ARM: {
    name: 'Left Arm',
    pos: { x: CENTER + 7, y: 17, width: 5, height: 12 },
  },
  R_ARM: {
    name: 'Right Arm',
    pos: { x: CENTER - 7, y: 17, width: 5, height: 12 },
  },
  CROTCH: {
    name: 'Crotch',
    pos: { x: CENTER, y: 22, width: 9, height: 4 },
  },
  TORSO: {
    name: 'Torso',
    pos: { x: CENTER, y: 15.5, width: 9, height: 9 },
  },
  L_LEG: {
    name: 'Left Leg',
    pos: { x: CENTER + 5, y: 28, width: 10, height: 8 },
  },
  R_LEG: {
    name: 'Right Leg',
    pos: { x: CENTER - 5, y: 28, width: 10, height: 8 },
  },
};

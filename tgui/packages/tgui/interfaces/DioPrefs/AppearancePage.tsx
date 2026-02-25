import { useState } from 'react';

import { useBackend } from '../../backend';
import { Section, Stack } from '../../components';
import { CharacterDoll, Part } from '../../components/CharacterDoll';
import {
  createSetPreference,
  PreferencesMenuData,
} from '../PreferencesMenu/data';
import { FeatureChoicedServerData } from '../PreferencesMenu/preferences/features/base';
import { ServerPreferencesFetcher } from '../PreferencesMenu/ServerPreferencesFetcher';
import { MainFeature } from './Components';
import { CharacterPreview } from './Preferences';

// These consts make thinking about this 1000% easier.
const DOLL_SIZE = 32 * 10;
const CENTER = 32 * 0.484375;

export const AppearancePage = (props) => {
  const { data, act } = useBackend<PreferencesMenuData>();
  const [selectedPart, setSelectedPart] = useState<null | Part>(null);
  const [currentFeatureMenu, setCurrentFeatureMenu] = useState<null | string>(
    null,
  );

  return (
    <ServerPreferencesFetcher
      render={(serverData) => {
        return (
          <Stack fill>
            <Stack.Item>
              <CharacterDoll
                selectedPart={selectedPart}
                setSelectedPart={setSelectedPart}
                dollSize={DOLL_SIZE}
                parts={parts}
                center={CENTER}
              />
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
                  {!!selectedPart &&
                    !!serverData &&
                    !!data.character_preferences[selectedPart.id] &&
                    Object.entries(
                      data.character_preferences[selectedPart.id],
                    ).map((notName) => {
                      return (
                        <MainFeature
                          key={notName[0] + notName[1]}
                          catalog={
                            serverData[notName[0]] as FeatureChoicedServerData
                          }
                          currentValue={
                            data.character_preferences[selectedPart.id][
                              notName[0]
                            ]
                          }
                          handleClose={() => {
                            setCurrentFeatureMenu(null);
                          }}
                          handleOpen={() => {
                            setCurrentFeatureMenu(notName[0]);
                          }}
                          handleSelect={createSetPreference(act, notName[0])}
                          isOpen={currentFeatureMenu === notName[0]}
                          setRandomization={() => {}}
                        />
                      );
                    })}
                </Section>
              </Stack>
            </Stack.Item>
            <Stack.Item width="300px">
              <CharacterPreview id={data.character_preview_view} />
            </Stack.Item>
          </Stack>
        );
      }}
    />
  );
};

// These are all in sprite-space pixels
// These should *probably* be DM-controlled in the future for species specific stuff...
// but I honestly don't see any species bucking this trend for now, and this has less moving parts.
const parts: Part[] = [
  {
    id: 'head',
    name: 'Head',
    pos: { x: CENTER, y: 6, width: 10, height: 10 },
  },
  {
    id: 'left_arm',
    name: 'Left Arm',
    pos: { x: CENTER + 7, y: 17, width: 5, height: 12 },
  },
  {
    id: 'right_arm',
    name: 'Right Arm',
    pos: { x: CENTER - 7, y: 17, width: 5, height: 12 },
  },
  {
    id: 'groin',
    name: 'Groin',
    pos: { x: CENTER, y: 22, width: 9, height: 4 },
  },
  {
    id: 'torso',
    name: 'Torso',
    pos: { x: CENTER, y: 15.5, width: 9, height: 9 },
  },
  {
    id: 'left_leg',
    name: 'Left Leg',
    pos: { x: CENTER + 5, y: 28, width: 10, height: 8 },
  },
  {
    id: 'right_leg',
    name: 'Right Leg',
    pos: { x: CENTER - 5, y: 28, width: 10, height: 8 },
  },
];

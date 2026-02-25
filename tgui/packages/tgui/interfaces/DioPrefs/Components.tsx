import { classes } from 'common/react';
import { createSearch } from 'common/string';
import React, { useState } from 'react';
import { Popper } from 'tgui-core/components';

import { useBackend } from '../../backend';
import {
  Autofocus,
  Box,
  Button,
  Flex,
  Input,
  LabeledList,
  Stack,
  TrackOutsideClicks,
} from '../../components';
import { PreferencesMenuData, RandomSetting } from '../PreferencesMenu/data';
import {
  FeatureChoicedServerData,
  FeatureValueInput,
  SupplementalFeature,
} from '../PreferencesMenu/preferences/features/base';
import { RandomizationButton } from '../PreferencesMenu/RandomizationButton';
import { ServerPreferencesFetcher } from '../PreferencesMenu/ServerPreferencesFetcher';
import { PREFERENCE_ID_TO_COMPONENT } from './PreferenceTypes';

const CLOTHING_CELL_SIZE = 80;

const CLOTHING_SELECTION_CELL_SIZE = 80;
const CLOTHING_SELECTION_WIDTH = 4.4;
const CLOTHING_SELECTION_MULTIPLIER = 5.2;

export const MainFeature = (props: {
  catalog: FeatureChoicedServerData;
  currentValue: string;
  handleClose: () => void;
  handleOpen: () => void;
  handleSelect: (newClothing: string) => void;
  isOpen: boolean;
  randomization?: RandomSetting;
  setRandomization: (newSetting: RandomSetting) => void;
}) => {
  const { act, data } = useBackend<PreferencesMenuData>();

  const {
    catalog,
    currentValue,
    isOpen,
    handleOpen,
    handleClose,
    handleSelect,
    randomization,
    setRandomization,
  } = props;

  const supplementalFeatures = catalog.supplemental_features;

  return (
    <Popper
      isOpen={isOpen}
      placement="bottom-start"
      content={
        isOpen && (
          <TrackOutsideClicks onOutsideClick={props.handleClose}>
            <ChoicedSelection
              name={catalog.name}
              catalog={catalog}
              selected={currentValue}
              supplementalFeatures={supplementalFeatures}
              onClose={handleClose}
              onSelect={handleSelect}
            />
          </TrackOutsideClicks>
        )
      }
    >
      <Button
        onClick={(e) => {
          e.stopPropagation();
          if (isOpen) {
            handleClose();
          } else {
            handleOpen();
          }
        }}
        style={{
          height: `${CLOTHING_CELL_SIZE}px`,
          width: `${CLOTHING_CELL_SIZE}px`,
        }}
        position="relative"
        tooltip={catalog.name + ' (' + props.currentValue + ')'}
        tooltipPosition="right"
      >
        <Box
          className={classes([
            'preferences32x32',
            catalog.icons![currentValue],
            'centered-image',
          ])}
          style={{
            colorInterpolation: 'nearest-neighbor',
            transform: 'translateX(-50%) translateY(-50%) scale(2)',
          }}
        />

        {randomization && (
          <RandomizationButton
            dropdownProps={{
              dropdownStyle: {
                bottom: 0,
                position: 'absolute',
                right: '1px',
              },

              onOpen: (event) => {
                // We're a button inside a button.
                // Did you know that's against the W3C standard? :)
                event.cancelBubble = true;
                event.stopPropagation();
              },
            }}
            value={randomization}
            setValue={setRandomization}
          />
        )}
      </Button>
    </Popper>
  );
};

const ChoicedSelection = (props: {
  catalog: FeatureChoicedServerData;
  name: string;
  onClose: () => void;
  onSelect: (value: string) => void;
  selected: string;
  supplementalFeatures?: SupplementalFeature[];
}) => {
  const { act, data } = useBackend<PreferencesMenuData>();
  const [searchTerm, setSearchTerm] = useState<string>('');

  const { catalog, supplementalFeatures } = props;

  let selectedIndex = catalog.choices.findIndex((e) => e === props.selected);

  if (!catalog.icons) {
    return <Box color="red">Provided catalog had no icons!</Box>;
  }

  return (
    <ServerPreferencesFetcher
      render={(serverData) => (
        <Box
          style={{
            background: '#383838ff',
            // padding: '5px',
            border: 'solid 5px #646464ff',
            borderRadius: '1px',
            boxShadow: '5px 5px 20px black',

            height: `${
              CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_MULTIPLIER
            }px`,
            width: `${CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_WIDTH}px`,
          }}
        >
          <Stack vertical fill>
            <Stack.Item>
              <Stack fill>
                <Stack.Item>
                  <Button
                    icon="arrow-left"
                    onClick={() =>
                      props.onSelect(
                        catalog.choices[
                          selectedIndex - 1 < 0
                            ? catalog.choices.length - 1
                            : selectedIndex - 1
                        ],
                      )
                    }
                  />
                  <Button
                    icon="arrow-right"
                    onClick={() =>
                      props.onSelect(
                        catalog.choices[
                          selectedIndex + 2 > catalog.choices.length
                            ? 0
                            : selectedIndex + 1
                        ],
                      )
                    }
                  />
                </Stack.Item>
                <Stack.Item grow>
                  <Box
                    style={{
                      borderBottom: '1px solid #888',
                      fontWeight: 'bold',
                      fontSize: '14px',
                      textAlign: 'center',
                    }}
                  >
                    Select {props.name?.toLowerCase()}
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  <Button color="red" onClick={props.onClose}>
                    X
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            {supplementalFeatures && (
              <LabeledList>
                {supplementalFeatures.map((feature) => (
                  <LabeledList.Item
                    key={feature.key}
                    label={
                      (serverData &&
                        (serverData[feature.key] as Record<string, string>)
                          ?.name) ||
                      (feature.feature === 'tri_color' && 'Part Color')
                    }
                  >
                    {JSON.stringify(feature)}
                    <FeatureValueInput
                      act={(action, data) => {
                        act(action, data);
                        console.log(action + ' | ' + JSON.stringify(data));
                      }}
                      feature={PREFERENCE_ID_TO_COMPONENT[feature.feature]}
                      featureId={feature.key}
                      shrink
                      value={
                        data.character_preferences.supplemental_features[
                          feature.key
                        ]
                      }
                    />
                  </LabeledList.Item>
                ))}
              </LabeledList>
            )}

            <Stack.Item>
              <Input
                placeholder="Search..."
                style={{
                  margin: '0px 5px',
                  width: '95%',
                }}
                onInput={(_, value) => setSearchTerm(value)}
              />
            </Stack.Item>

            <Stack.Item overflowX="hidden" overflowY="scroll" height="100%">
              <Autofocus>
                <Flex wrap>
                  {catalog?.icons &&
                    searchInCatalog(searchTerm, catalog.icons).map(
                      ([name, image], index) => {
                        return (
                          <Flex.Item
                            key={index}
                            basis={`${CLOTHING_SELECTION_CELL_SIZE}px`}
                            style={{
                              padding: '5px',
                            }}
                          >
                            <Button
                              onClick={() => {
                                props.onSelect(name);
                              }}
                              selected={name === props.selected}
                              tooltip={name}
                              tooltipPosition="right"
                              style={{
                                height: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                                width: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                              }}
                            >
                              <Box
                                className={classes([
                                  'preferences32x32',
                                  image,
                                  'centered-image',
                                ])}
                                style={{
                                  transform:
                                    'translateX(-50%) translateY(-50%) scale(2)',
                                }}
                              />
                            </Button>
                          </Flex.Item>
                        );
                      },
                    )}
                </Flex>
              </Autofocus>
            </Stack.Item>
          </Stack>
        </Box>
      )}
    />
  );
};

const searchInCatalog = (searchText = '', catalog: Record<string, string>) => {
  let items = Object.entries(catalog);
  if (searchText) {
    items = items.filter(createSearch(searchText, ([name, _icon]) => name));
  }
  return items;
};

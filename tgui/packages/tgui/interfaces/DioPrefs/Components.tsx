import { classes } from 'common/react';
import React from 'react';
import { Popper } from 'tgui-core/components';

import { useBackend } from '../../backend';
import {
  Autofocus,
  Box,
  Button,
  Flex,
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
import { PREFERENCE_ID_TO_COMPONENT } from './PreferenceTypes';

const CLOTHING_CELL_SIZE = 80;

const CLOTHING_SELECTION_CELL_SIZE = 80;
const CLOTHING_SELECTION_WIDTH = 5.4;
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

  const { catalog, supplementalFeatures } = props;

  let selectedIndex = catalog.choices.findIndex((e) => e === props.selected);

  if (!catalog.icons) {
    return <Box color="red">Provided catalog had no icons!</Box>;
  }

  return (
    <Box
      style={{
        background: '#383838ff',
        // padding: '5px',
        border: 'solid 5px #646464ff',
        borderRadius: '1px',
        boxShadow: '5px black',

        height: `${
          CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_MULTIPLIER
        }px`,
        width: `${CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_WIDTH}px`,
      }}
    >
      <Stack vertical fill>
        <Stack.Item>
          <Stack fill>
            {supplementalFeatures &&
              supplementalFeatures.map((feature) => (
                <Stack.Item key={feature.key}>
                  <FeatureValueInput
                    act={act}
                    feature={PREFERENCE_ID_TO_COMPONENT[feature.feature]}
                    featureId={feature.key}
                    shrink
                    value={
                      data.character_preferences.supplemental_features[
                        feature.key
                      ]
                    }
                  />
                </Stack.Item>
              ))}

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

        <Stack.Item overflowX="hidden" overflowY="scroll">
          <Autofocus>
            <Flex wrap>
              {Object.entries(catalog.icons).map(([name, image], index) => {
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
              })}
            </Flex>
          </Autofocus>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

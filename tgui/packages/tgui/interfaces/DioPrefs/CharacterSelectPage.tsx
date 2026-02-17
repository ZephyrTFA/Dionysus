import { useBackend } from '../../backend';
import { Dropdown } from '../../components';

export type CharacterSelectData = {
  characters: {
    icon: String;
    name: String;
  }[];
};

export const CharacterSelect = (props) => {
  const { data } = useBackend<CharacterSelectData>();

  let chars: String[] = [];
  data.characters.forEach((char) => {
    chars.push(char.name);
  });
  return <Dropdown options={chars} />;
};

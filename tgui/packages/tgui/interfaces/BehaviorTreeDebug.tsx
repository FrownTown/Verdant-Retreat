import { useBackend } from '../backend';
import { Box, Section, Stack, LabeledList, Button, Collapsible } from 'tgui-core/components';
import { Window } from '../layouts';
import { useState } from 'react';

type NodeData = {
  type: string;
  name: string;
  state: number;
  children: NodeData[];
};

type Data = {
  has_ai: boolean;
  selecting: boolean;
  mob_name: string;
  blackboard: Record<string, string>;
  tree: NodeData;
  selected_count: number;
  selected_mobs: string[];
  spawn_categories: Record<string, Record<string, string>>;
};

const NODE_FAILURE = 0;
const NODE_SUCCESS = 1;
const NODE_RUNNING = 2;

const NodeView = (props: { node: NodeData | null }) => {
  const { node } = props;

  if (!node) {
    return null;
  }

  let color = 'grey';
  if (node.state === NODE_SUCCESS) color = 'green';
  else if (node.state === NODE_FAILURE) color = 'red';
  else if (node.state === NODE_RUNNING) color = 'blue';

  return (
    <Box mb={1}>
      <Box
        p={1}
        backgroundColor={color}
        textColor="white"
        style={{
          border: '1px solid black',
          borderRadius: '3px'
        }}
      >
        <Stack>
          <Stack.Item grow>
            {node.name}
          </Stack.Item>
          <Stack.Item>
            <Box fontSize="0.8em" opacity={0.8}>
              {node.type}
            </Box>
          </Stack.Item>
        </Stack>
      </Box>

      {node.children && node.children.length > 0 && (
        <Box ml={2} mt={0.5} pl={1} style={{ borderLeft: '1px solid rgba(255,255,255,0.2)' }}>
          {node.children.map((child, i) => (
            child && <NodeView key={i} node={child} />
          ))}
        </Box>
      )}
    </Box>
  );
};

const MobSpawner = (props) => {
  const { act, data } = useBackend<Data>(props);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());

  const toggleCategory = (category: string) => {
    const newExpanded = new Set(expandedCategories);
    if (newExpanded.has(category)) {
      newExpanded.delete(category);
    } else {
      newExpanded.add(category);
    }
    setExpandedCategories(newExpanded);
  };

  return (
    <Section title="Spawn Mobs">
      {Object.keys(data.spawn_categories || {}).map(category => (
        <Collapsible
          key={category}
          title={category}
          open={expandedCategories.has(category)}
          onClick={() => toggleCategory(category)}
        >
          <Stack vertical>
            {Object.keys(data.spawn_categories[category]).map(mobName => (
              <Stack.Item key={mobName}>
                <Button
                  fluid
                  onClick={() => {
                    console.log('Button clicked for:', mobName);
                    act('spawn_mob', { path: data.spawn_categories[category][mobName] });
                  }}
                >
                  {mobName}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Collapsible>
      ))}
      <Box mt={1} color="label" fontSize="0.9em">
        Hint: Mobs spawn at your location
      </Box>
    </Section>
  );
};

const SelectionPanel = (props) => {
  const { act, data } = useBackend<Data>(props);

  return (
    <Section title={`Selected Mobs (${data.selected_count || 0})`}>
      <Stack vertical>
        <Stack.Item>
          <Button
            fluid
            color="good"
            icon="mouse-pointer"
            onClick={() => act('start_selecting')}
          >
            Select Mob to Debug
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            color="bad"
            disabled={!data.selected_count}
            onClick={() => act('delete_selected')}
          >
            Delete Selected
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            disabled={!data.selected_count}
            onClick={() => act('clear_selection')}
          >
            Clear Selection
          </Button>
        </Stack.Item>
        {data.selected_mobs && data.selected_mobs.length > 0 && (
          <Stack.Item>
            <Box
              p={1}
              backgroundColor="rgba(255,255,255,0.05)"
              style={{ maxHeight: '150px', overflowY: 'auto', fontSize: '0.9em' }}
            >
              {data.selected_mobs.map((mobName, i) => (
                <Box key={i}>{mobName}</Box>
              ))}
            </Box>
          </Stack.Item>
        )}
      </Stack>
      <Box mt={1} color="label" fontSize="0.9em">
        Hint: Ctrl+Click to multi-select | Shift+Drag for box select
      </Box>
    </Section>
  );
};

export const BehaviorTreeDebug = (props) => {
  const { data } = useBackend<Data>(props);

  const title = data.has_ai ? `BT Debug: ${data.mob_name}` : "Behavior Tree Debugger";

  return (
    <Window title={title} width={1000} height={800}>
      <Window.Content scrollable>
        <Stack>
          <Stack.Item basis="65%">
            <Stack vertical>
              {data.has_ai ? (
                <>
                  <Stack.Item>
                    <Section title="Blackboard">
                      <LabeledList>
                        {Object.keys(data.blackboard || {}).length > 0 ? (
                          Object.keys(data.blackboard).map(key => (
                            <LabeledList.Item key={key} label={key}>
                              {data.blackboard[key]}
                            </LabeledList.Item>
                          ))
                        ) : (
                          <Box color="label">Empty</Box>
                        )}
                      </LabeledList>
                    </Section>
                  </Stack.Item>

                  <Stack.Item>
                    <Section title="Tree Structure">
                      {data.tree && <NodeView node={data.tree} />}
                    </Section>
                  </Stack.Item>
                </>
              ) : (
                <Stack.Item>
                  <Section title="No Mob Selected">
                    <Box p={2} textAlign="center">
                      <Box fontSize="1.1em" mb={1} color="label">
                        Click "Select Mob to Debug" to choose a mob
                      </Box>
                      <Box fontSize="0.9em" color="label">
                        Or spawn mobs using the panel on the right
                      </Box>
                    </Box>
                  </Section>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>

          <Stack.Item basis="35%">
            <Stack vertical>
              <Stack.Item>
                <SelectionPanel {...props} />
              </Stack.Item>
              <Stack.Item>
                <MobSpawner {...props} />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

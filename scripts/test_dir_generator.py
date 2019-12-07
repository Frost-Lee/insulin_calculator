import os
import json

class TestCase:
    def __init__(
        self, 
        food_name, 
        weight, 
        case_index, 
        background='Paper', 
        height=0.45, 
        pitch=0.0, 
        roll=0.0, 
        center_deviation=0.0
    ):
        self.food_name = food_name
        self.weight = weight
        self.case_index = case_index
        self.background = background
        self.height = height
        self.pitch = pitch
        self.roll = roll
        self.center_deviation = center_deviation
    
    def to_json_string(self):
        json_dict = {
            'food_name': self.food_name,
            'weight': self.weight,
            'background': self.background,
            'height': self.height,
            'angle': {
                'pitch': self.pitch,
                'roll': self.roll
            },
            'center_deviation': self.center_deviation
        }
        return json.dumps(json_dict, indent=4)
    
    def dir_name(self):
        return '{}_{}'.format('case', str(self.case_index))

FOOD_NAME = 'McDouble'
FOOD_WEIGHT = 0.132

path_dict = {
    'burger': {
        'reference': {
            TestCase(FOOD_NAME, FOOD_WEIGHT, 0)
        },
        'height_var': {
            TestCase(FOOD_NAME, FOOD_WEIGHT, 0, height=0.4),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 1, height=0.5),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 2, height=0.55),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 3, height=0.6)
        },
        'angle_var': {
            'pitch': {
                TestCase(FOOD_NAME, FOOD_WEIGHT, 0, pitch=-2.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 1, pitch=-4.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 2, pitch=-6.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 3, pitch=-8.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 4, pitch=-10.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 5, pitch=-15.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 6, pitch=-20.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 7, pitch=-25.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 8, pitch=-30.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 9, pitch=2.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 10, pitch=4.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 11, pitch=6.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 12, pitch=8.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 13, pitch=10.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 14, pitch=15.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 15, pitch=20.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 16, pitch=25.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 17, pitch=30.0)
            },
            'roll': {
                TestCase(FOOD_NAME, FOOD_WEIGHT, 0, roll=-2.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 1, roll=-4.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 2, roll=-6.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 3, roll=-8.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 4, roll=-10.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 5, roll=-15.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 6, roll=-20.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 7, roll=-25.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 8, roll=-30.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 9, roll=2.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 10, roll=4.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 11, roll=6.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 12, roll=8.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 13, roll=10.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 14, roll=15.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 15, roll=20.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 16, roll=25.0),
                TestCase(FOOD_NAME, FOOD_WEIGHT, 17, roll=30.0)
            }
        },
        'background_var': {
            TestCase(FOOD_NAME, FOOD_WEIGHT, 0, background='Wood table 76-660'),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 1, background='Cupboard 76-651'),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 2, background='Dining table 76-651'),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 3, background='Window table 76-651')
        },
        'position_var': {
            TestCase(FOOD_NAME, FOOD_WEIGHT, 0, center_deviation=0.02),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 1, center_deviation=0.04),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 2, center_deviation=0.06),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 3, center_deviation=0.08),
            TestCase(FOOD_NAME, FOOD_WEIGHT, 4, center_deviation=0.10),
        }
    }
}

def path_gen(path_dict, root_path):
    for key in path_dict:
        if type(path_dict[key]) is dict:
            yield from path_gen(path_dict[key], os.path.join(root_path, key))
        else:
            yield (path_dict[key], os.path.join(root_path, key))

for cases, path in path_gen(path_dict, '/Volumes/tsanchen/carbs_estimate/error_tolerance_test'):
    for case in cases:
        dir_path = os.path.join(path, case.dir_name())
        os.makedirs(dir_path)
        with open(os.path.join(dir_path, 'metadata.json'), 'w') as out_file:
            out_file.write(case.to_json_string())

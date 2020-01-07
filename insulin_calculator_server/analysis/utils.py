import os
import re
import json
import pathlib
import numpy as np
import pandas as pd
from PIL import Image

from . import config

def capture_storage_dirs(root_dir):
    """ Yielding all capture storage directory paths.

        This method yields all capture storage directory paths, which name is 
        specified by `config.CAPTURE_DIR_RE`.

    Args:
        root_dir: The root directory to find capture storage directories.
    
    Returns:
        A generator, each iteration will provide the absolute path of one capture 
            storage directory.
    """
    for root, dirs, files in os.walk(root_dir):
        for dir in dirs:
            if re.match(config.CAPTURE_DIR_RE, dir):
                yield os.path.join(root, dir)

def case_storage_dirs(root_dir):
    case_storage_dirs = set()
    for root, dirs, files in os.walk(root_dir):
        for dir in dirs:
            if re.match(config.CASE_DIR_RE, dir):
                case_storage_dirs.add(str(pathlib.Path(os.path.join(root, dir)).parent))
    return [*case_storage_dirs]

def get_result_df(reference_path, comparison_path, factor_extractor):
    """ Get a pandas data frame of influential factor and corresponding capture 
        estimation result.

    Args:
        reference_path: The path of reference group's capture storage.
        comparison_path: The path of comparison group's capture storage.
        factor_extractor: The function for extracting the influential factor from 
            the json object derived from metadata.json.
    
    Returns:
        A pandas data frame with 3 columns: factor, area, volume.
    """
    df = pd.DataFrame(columns=['factor', 'area', 'volume'])
    for path in [*capture_storage_dirs(reference_path)] + [*capture_storage_dirs(comparison_path)]:
        with open(os.path.join(path, 'result.json')) as result_if, open(os.path.join(path, '..', 'metadata.json')) as metadata_if:
            factor = factor_extractor(json.loads(metadata_if.read()))
            result = json.loads(result_if.read())
            df = df.append({
                'factor': factor,
                'area': result['areas'][0],
                'volume': result['volumes'][0]
            }, ignore_index=True)
    return df

def load_image(path):
    """ Load a colored image as numpy array with shape `(width, height, channel)`.

    Args:
        path: The path of the image file.
    """
    return np.array(Image.open(path))

def load_peripheral(path):
    """ Load the peripheral data of a capture as a json object.

    Args:
        path: The path of the peripheral data file.
    """
    with open(path) as in_file:
        return json.loads(in_file.read())

def format_result(results):
    """ Returning the formatted estimation result as a JSON string.

    Args:
        results: The estimation result, represented as a list of 2 float tuples. 
            Each tuple stand for `(area, volume)`.
    """
    json_dict = {
        "areas": [*map(lambda x: x[0], results)],
        "volumes": [*map(lambda x: x[1], results)]
    }
    return json.dumps(json_dict, indent=4)
 
class TestCase:
    """ The class for specifying a test case for food volume estimating.

    Attributes:
        food_name: The name of the food.
        weight: The weight of the food, in kilograms.
        case_index: The index of this test case.
        background: The table background of this test case.
        height: The camera height of this test case, in meters.
        pitch: The camera pitch of this test case, in degrees.
        roll: The camera roll of this test case, in degrees.
        center_deviation: The distance of the camera deviates from the image center 
            of this test case, in meters.
    """
    def __init__(
        self, 
        food_name, 
        weight, 
        case_index, 
        background='Paper', 
        height=0.50, 
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
        """ Returning a json string that represents this test case.
        """
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
        """ Returning the case directory name of this test case.
        """
        return '{}_{}'.format('case', str(self.case_index))

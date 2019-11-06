import os
import datetime
import json
import numpy as np
from PIL import Image


RECOGNITION_STORAGE_DIR = '/home/Frost/insulin_calculator_data/recognition_session_data/'
COLLECTION_STORAGE_DIR = '/home/Frost/insulin_calculator_data/collection_session_data/'


class SessionDataManager(object):
    """ The manager that handles file I/O for a session.
    Attributes:
        session_id: The id of the session. This value is supposed to be of type 
            `str`.
        session_dir: The storage directory path of this session.
        image: The color image input of the corresponding session, represented 
            as a fnumpy array.
        peripheral: The peripheral data input of the corresponding session, 
            represented as a json object
    """
    def __init__(self, session_id, collection_session=False):
        self.session_id = session_id
        self.session_dir = self._make_session_dir(COLLECTION_STORAGE_DIR if collection_session else RECOGNITION_STORAGE_DIR)
        self.image = None
        self.peripheral = None
    
    def _make_session_dir(self, root_dir):
        """ Create the session directory of this session. The directory is 
            `/root_dir/month/time/session_id`.
        
        Args:
            root_dir: The root directory of the stored data.
        Returns:
            The created session directory path.
        """
        now = datetime.datetime.now()
        session_dir = os.path.join(root_dir, *[
            '{}_{}'.format(*map(str, (now.year, now.month))),
            str(now.day),
            '{}_{}_{}_{}'.format(*map(str, (now.hour, now.minute, now.second, self.session_id)))
        ])
        os.makedirs(session_dir)
        return session_dir
    
    def register_image_file(self, image):
        """ Save the image to the session directory, then load it to memory as 
            a numpy array.
        Args:
            image: A `werkzeug.datastructures.FileStorage` object.
        """
        save_path = os.path.join(self.session_dir, 'image.jpg')
        image.save(save_path)
        self.image = np.array(Image.open(save_path))
    
    def register_peripheral_file(self, peripheral):
        """ Save the peripheral json to the session directory, then load it to 
            memory as a json object.
        Args:
            peripheral: A `werkzeug.datastructures.FileStorage` object.
        """
        save_path = os.path.join(self.session_dir, 'peripheral.json')
        peripheral.save(save_path)
        with open(save_path) as in_file:
            self.peripheral = json.loads(in_file.read())
    
    def register_collection_label(self, name, weight):
        """ Save a file to record the collection label, which includes the name 
            and weight of the food.
        
        Args:
            name: A string stand for the name of the food.
            weight: A string stand for the weight of the food, measured in pound.
        """
        save_path = os.path.join(self.session_dir, 'collection_label.txt')
        print(name)
        print(weight)
        with open(save_path, 'w') as in_file:
            in_file.write('{}: {}\n{}: {}'.format('name', name, 'weight', weight))
    
    def save_recognition_file(self, recognition_json):
        """ Store the recognition result for the session, which is represented 
            as a json string.
        
        Args:
            recognition_json: The recognition result to save. A json string.
        """
        save_path = os.path.join(self.session_dir, '{}.{}'.format('recognition', 'json'))
        with open(save_path, 'w') as out_file:
            out_file.write(recognition_json)

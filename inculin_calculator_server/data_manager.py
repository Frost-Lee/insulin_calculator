import os
import datetime
import json
import numpy as np
from PIL import Image


storage_dir = '/basepath/insulin_calculator_data/recognition_session_data/'


class Session_Data_Manager:
    """ The manager that handles file I/O for a session.

    Attributes:
        session_id: The id of the session. This value is supposed to be of type 
            `str`.
        session_dir: The storage directory path of this session.
        image: The color image input of the corresponding session, represented 
            as a numpy array.
        peripheral: The peripheral data input of the corresponding session, 
            represented as a json object
    """
    def __init__(self, session_id):
        self.session_id = session_id
        self.session_dir = _make_session_dir()
        self.image = None
        self.peripheral = None
    
    def _make_session_dir(self):
        """ Create the session directory of this session. The directory is 
            `/storage_dir/month/time/session_id`.
        
        Returns:
            The created session directory path.
        """
        now = datetime.datetime.now()
        session_dir = os.path.join(storage_dir, [
            '_'.join(map(str, (now.year, now.month))), 
            '_'.join(map(str, (now.day, now.hour, now.minute, now.second))),
            self.session_id
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
    
    def save_recognition_file(self, recognition_json):
        """ Store the recognition result for the session, which is represented 
            as a json object.
        
        Args:
            recognition_json: The recognition result to save. A json object.
        """
        save_path = os.path.join(self.session_dir, '.'.join(('recognition', 'json')))
        with open(save_path, 'w') as out_file:
            out_file.write(json.dumps(recognition_json, indent=4, sort_keys=True))

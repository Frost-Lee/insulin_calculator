import numpy as np
import json
from PIL import Image
import os

import fvolume.classification
import fvolume.estimation
import fvolume.recognition
import fdensitylib.density

def get_area_volume_estimate(image, peripheral):
    depth_map = np.array(peripheral['depth_data'])
    calibration = peripheral['calibration_data']
    attitude = peripheral['device_attitude']
    label_mask, boxes, buffers = fvolume.recognition.get_recognition_results(
        image,
        calibration
    )
    area_volumes = fvolume.estimation.get_area_volume(
        depth_map,
        calibration,
        attitude,
        label_mask
    )
    print(area_volumes)

if __name__ == '__main__':
    for root, dirs, files in os.walk('/Volumes/canchen/carbs_estimate/volume_accuracy_test/biscuit/angle_var/pitch_case_1'):
        for dir in dirs:
            print(dir)
            fvolume.recognition.SESSION_ID = dir
            image = np.array(Image.open(os.path.join(root, dir, 'image.jpg')))
            peripheral = json.loads(open(os.path.join(root, dir, 'peripheral.json')).read())
            get_area_volume_estimate(image, peripheral)
    # with open('/Users/Frost/Desktop/pizza/22_8_11_4BFF6449-E75D-4DBA-ADBE-5425942DFDD9/peripheral.json') as in_file:
    #     image = Image.open('/Users/Frost/Desktop/pizza/22_8_11_4BFF6449-E75D-4DBA-ADBE-5425942DFDD9/image.jpg')
    #     get_area_volume_estimate(np.array(image), json.loads(in_file.read()))

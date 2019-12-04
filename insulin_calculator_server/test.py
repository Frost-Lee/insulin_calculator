import numpy as np
import json
from PIL import Image
import os

# import fvolume
# import fdensitylib
import analysis

# def get_area_volume_estimate(image, peripheral):
#     depth_map = np.array(peripheral['depth_data'])
#     calibration = peripheral['calibration_data']
#     attitude = peripheral['device_attitude']
#     label_mask, boxes, buffers = fvolume.recognition.get_recognition_results(
#         image,
#         calibration
#     )
#     area_volumes = fvolume.estimation.get_area_volume(
#         depth_map,
#         calibration,
#         attitude,
#         label_mask
#     )
#     return area_volumes

# for path in analysis.utils.capture_storage_dirs('/Volumes/tsanchen/carbs_estimate/volume_accuracy_test/biscuit'):
#     print('\rProcessing: ', path, end='')
#     image = analysis.utils.load_image(os.path.join(path, 'image.jpg'))
#     peripheral = analysis.utils.load_peripheral(os.path.join(path, 'peripheral.json'))
#     result_json = analysis.utils.format_result(
#         get_area_volume_estimate(image, peripheral)
#     )
#     with open(os.path.join(path, 'result.json'), 'w') as out_file:
#         out_file.write(result_json)
df = analysis.utils.get_result_df(
    '/Volumes/tsanchen/carbs_estimate/volume_accuracy_test/biscuit/reference',
    '/Volumes/tsanchen/carbs_estimate/volume_accuracy_test/biscuit/position_var',
    lambda x: x['center_deviation']
)
df.to_csv('/Users/Frost/Desktop/a.csv')
analysis.visualize.visualize_result_df(df, '/Users/Frost/Desktop/a.jpg', 'volume')

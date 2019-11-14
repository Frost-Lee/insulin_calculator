import os

UNIFIED_IMAGE_SIZE = (512, 512)

FOOD_PROB_THRESHOLD = 0.5

FOOD_MIN_SIZE_THRESHOLD = UNIFIED_IMAGE_SIZE[0] / 16

CLASSIFIER_IMAGE_SIZE = (544, 544)

CLASSIFICATION_CANDIDATES = 5

RANSAC_THRESHOLD = 0.002

GRID_LEN = 2e-3

PACKAGE_ROOT_PATH = os.path.dirname(os.path.realpath(__file__))

SEG_MODEL_PATH = os.path.join(PACKAGE_ROOT_PATH, *['ml_model', 'unet_samplenorm.hdf5'])

UNDISTORT_DLL_PATH = os.path.join(PACKAGE_ROOT_PATH, *['c_core', 'undistort.so'])

CLASSIFIER_URL = 'https://api-2445582032290.production.gw.apicast.io/v1/foodrecognition?user_key=cf1ba06a7dcb3385b2347316408a74e8'

UNIFIED_IMAGE_SIZE = (512, 512)

BLOCK_REDUCT_WINDOW = (4, 4)

FOOD_PROB_THRESHOLD = 0.7

FOOD_MIN_SIZE_THRESHOLD = UNIFIED_IMAGE_SIZE[0] / BLOCK_REDUCT_WINDOW[0] / 8

CLASSIFIER_IMAGE_SIZE = (544, 544)

CLASSIFICATION_CANDIDATES = 5

RANSAC_THRESHOLD = 0.002

# SEG_MODEL_PATH = '/home/Frost/insulin_calculator/insulin_calculator_server/fvolume/model.hdf5'
SEG_MODEL_PATH = '/Users/Frost/Desktop/model_checkpoint_02_2.hdf5'

CLASSIFIER_URL = 'https://api-2445582032290.production.gw.apicast.io/v1/foodrecognition?user_key=cf1ba06a7dcb3385b2347316408a74e8'

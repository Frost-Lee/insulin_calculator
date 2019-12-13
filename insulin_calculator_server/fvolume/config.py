import os

# The image size used for colored image, depth map and segmentation mask.
UNIFIED_IMAGE_SIZE = (512, 512)

# The probability threshold for identifying food in the segmentation mask. If a 
# pixel's corresponding probability is above this threshold, it will be take as 
# food.
FOOD_PROB_THRESHOLD = 0.5

# The minimum size of the food. Food entities whose width or height are smaller 
# than this threshold will be removed.
FOOD_MIN_SIZE_THRESHOLD = UNIFIED_IMAGE_SIZE[0] / 16

# The commercial classifier's input image size, depending on https://dev.caloriemama.ai.
CLASSIFIER_IMAGE_SIZE = (544, 544)

# The maximum entities for classification.
MAX_ENTITIES_THRESHOLD = 5

# The number of candidates to return. For each food entity, this amount of candidate 
# classifications will be returned.
CLASSIFICATION_CANDIDATES = 5

# The threshold for RANSAC for plane detection. See https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.RANSACRegressor.html.
RANSAC_THRESHOLD = 0.002

# The edge length of the grid when calculating the volume of food entity. In meters.
GRID_LEN = 2e-3

# The root path of this package.
PACKAGE_ROOT_PATH = os.path.dirname(os.path.realpath(__file__))

# The path of the food segmentation model.
SEG_MODEL_PATH = os.path.join(PACKAGE_ROOT_PATH, *['ml_model', 'unet.hdf5'])

# The path of the shared object for image undistorting.
UNDISTORT_DLL_PATH = os.path.join(PACKAGE_ROOT_PATH, *['c_core', 'undistort.so'])

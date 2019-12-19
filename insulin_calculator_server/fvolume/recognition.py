import skimage.measure
import numpy as np
import cv2
import io
import matplotlib.pyplot as plt
import keras
import tensorflow as tf

from . import config
from . import utils
from . import recorder

segmentation_model = keras.models.load_model(config.SEG_MODEL_PATH)

import os
FILE_DIR = None

def _get_segmentation(image):
    """ Returning the raw segmentation mask for the image. Each pixel's value 
        stands for the probability of this pixel being food.

    Args:
        image: The image to predict, represented as a numpy array with shape
            `(*configure.UNIFIED_IMAGE_SIZE, 3)`.

    Returns:
        The segmentation mask with shape `config.UNIFIED_IMAGE_SIZE`.
    """
    global segmentation_model
    def center_normalize(image):
        mean = np.mean(cv2.resize(image, (512, 512)), axis=(0, 1))
        std = np.std(cv2.resize(image, (512, 512)), axis=(0, 1))
        return (image - mean) / std
    predicted_result = segmentation_model.predict(
        np.reshape(center_normalize(image), (1, *config.UNIFIED_IMAGE_SIZE, 3))
    )[0]
    return np.reshape(
        predicted_result,
        config.UNIFIED_IMAGE_SIZE
    )


def _get_entity_labeling(image, mask):
    """ Getting the entity labeling that cover the food entities in the image.

    Args:
        image: The colored image, represented as a numpy array with shape 
            `(width, height, 3)`.
        mask: The food segmentation mask. A numpy array with the same resolution 
            with `image`, each pixel stands for the probability of the 
            corresponding pixel in `image` being food.
    
    Returns:
        `(label_mask, boxes)`
        `label_mask` is a 2d numpy array that mark different entities in the image 
            with positive integers starting from 0, while 0 stand for background. 
            The pixels with a probability greater than `config.FOOD_PROB_THRESHOLD` 
            will be considered as food. The size of `label_mask` is reduced from `image`.
        `boxes` is a list of entity boxes having the same order with `label_mask`. 
            Each entity box is represented as a 2x2 2d list, which stands for 
            `[[min width, max width], [min height, max height]]`. Background is not 
            included in `boxes`. The coordinate is relative to `label_mask`.
    """
    # TODO(canchen.lee@gmail.com): Consider using the colored image along with 
    # the mask to generate entity boxes, which separate enties within one connected 
    # component.
    bin_func = np.vectorize(lambda x: 0 if x < config.FOOD_PROB_THRESHOLD else 1)
    binary_mask = bin_func(mask)
    label_mask = skimage.measure.label(binary_mask, connectivity=2, background=0)
    boxes = [[
            *map(lambda x: (min(x), max(x) + 1), np.where(label_mask == entity))
        ] for entity in np.unique(label_mask)
    ]
    invalid_entity_indices = [
        index 
        for index, box in enumerate(boxes) 
        if min(box[0][1] - box[0][0], box[1][1] - box[1][0]) < config.FOOD_MIN_SIZE_THRESHOLD
    ]
    label_mask[np.isin(label_mask, invalid_entity_indices)] = 0
    boxes = [box for index, box in enumerate(boxes) if index not in invalid_entity_indices]
    return label_mask, boxes[1:]


def _index_crop(array, i, multiplier):
    """ Cropping an image with a specified width and height index range as well 
        as a multiplier. The cropped image will be a square image that cover the 
        region specified by the index while having the minimum area.

    Args:
        array: A 3d numpy array with shape (width, height, 3).
        i: The crop index, represented as a 2x2 2d list, such as which stands for 
            `[[min width, max width], [min height, max height]]`.
        multiplier: The multiplier of the index. Considering the index is calculated 
            on an image which might have different resolution with the original 
            image, this parameter is used to compensate the gap. The value should 
            be resolution of `array` / resolution of the image where `i` is calculated.
    
    Returns:
        The cropped image, represented as a numpy array.
    """
    width, height = abs(i[0][0] - i[0][1]), abs(i[1][0] - i[1][1])
    array_width, array_height, _ = array.shape
    def get_offset(i_range, margin, width):
        if i_range[0] - margin >= 0 and i_range[1] + margin < array_width:
            return 0
        elif i_range[0] - margin < 0:
            return margin - i_range[0]
        else:
            return width - i_range[1] - margin
    margin = abs(height - width) / 2.0
    if width < height:
        offset = get_offset(i[0], margin, array_width)
        return array[
            int((i[0][0]-margin+offset)*multiplier) : int((i[0][1]+margin+offset)*multiplier), 
            int(i[1][0]*multiplier) : int(i[1][1]*multiplier),
            0:3
        ]
    elif width > height:
        offset = get_offset(i[1], margin, array_height)
        return array[
            int(i[0][0]*multiplier) : int(i[0][1]*multiplier), 
            int((i[1][0]-margin+offset)*multiplier) : int((i[1][1]+margin+offset)*multiplier),
            0:3
        ]
    else:
        return array[
            int(i[0][0]*multiplier) : int(i[0][1]*multiplier), 
            int(i[1][0]*multiplier) : int(i[1][1]*multiplier), 
            0:3
        ]


def get_recognition_results(image, calibration):
    """ Get the recognition result of the color image with corresponding mask.

    Get a list of image buffers with the cropped food image in `image`. Images 
        in the list are all resized to `config.CLASSIFIER_IMAGE_SIZE`.
    
    Args:
        image: The raw resolution colored square image, represented as a numpy array.
        calibration: The camera calibration data when capturing the image.
    
    Returns:
        A tuple `(label_mask, boxes, buffers)`.
        `label_mask` is a 2d numpy array that mark different entities in the image 
            with ascending integers starting from 0, while 0 stand for background. 
            The pixels with a probability greater than `config.FOOD_PROB_THRESHOLD` 
            will be considered as food.
        `remapped_boxes` is a list of entity boxes. Each entity box is represented 
            as a list, which stands for `[width min, width max, height min, height max]`. 
            Background is not included in `boxes`. Values in the list are relative, 
            that is the value divided by the length of the corresponding edge.
        `buffers` is a list of image buffers, each image is the cropped food 
            image in `image`, and are all resized to `config.CLASSIFIER_IMAGE_SIZE`.
    """
    preprocessed_image = utils.preprocess_image(image, calibration)
    regulated_image = utils.regulate_image(preprocessed_image)
    mask = _get_segmentation(regulated_image)
    label_mask, boxes = _get_entity_labeling(regulated_image, mask)
    multiplier = image.shape[0] / config.UNIFIED_IMAGE_SIZE[0]
    recorder.record([regulated_image, label_mask], 'image_and_mask')
    images = [
        cv2.resize(
            _index_crop(utils.center_crop(preprocessed_image), box, multiplier),
            config.CLASSIFIER_IMAGE_SIZE
        ) for box in boxes
    ]
    # TODO(canchen.lee@gmail.com): Map the boxes back to match the undistorted coordinate.
    remapped_boxes = [[float(item / label_mask.shape[0]) for tp in box for item in tp] for box in boxes]
    buffers = [io.BytesIO() for _ in range(len(images))]
    [plt.imsave(buffer, image, format='jpeg') for buffer, image in zip(buffers, images)]
    return label_mask, remapped_boxes, buffers

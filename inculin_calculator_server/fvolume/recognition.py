import skimage.measure
import numpy as np
import cv2
import io
import matplotlib.pyplot as plt
import keras

from . import config

# segmentation_model = keras.models.load_model(config.SEG_MODEL_PATH)
# segmentation_model._make_predict_function()
segmentation_model = None


def _get_segmentation(image):
    """ Return the segmentation mask for the image.

    Args:
        image: The image to predict, represented as a numpy array with shape 
            `(*configure.UNIFIED_IMAGE_SIZE, 3)`.
    
    Returns:
        The segmentation mask with shape `config.UNIFIED_IMAGE_SIZE`.
    """
    global segmentation_model
    if segmentation_model is None:
        segmentation_model = keras.models.load_model(config.SEG_MODEL_PATH)
    def center_normalize(image):
        mean_list = np.reshape(np.array([32.768, 32.768, 32.768]), (1, 1, 3))
        std_list = np.reshape(np.array([72.57518, 66.39548, 61.829777]), (1, 1, 3))
        return (image - mean_list) / std_list
    return np.reshape(
        segmentation_model.predict(np.reshape(center_normalize(image), (1, *config.UNIFIED_IMAGE_SIZE, 3)))[0], 
        config.UNIFIED_IMAGE_SIZE
    )


def _get_entity_labeling(image, mask):
    """ Getting the entity labeling that cover the food entities in the image.

    Args:
        image: The colored image, represented as a numpy array with shape `(width, 
            height, 3)`.
        mask: The food segmentation mask. A numpy array with the same resolution 
            with `image`, and each pixel stands for the probability of the 
            corresponding pixel in `image` being food.
    
    Returns:
        A tuple, `(label_mask, boxes)`.
        `label_mask` is a 2d numpy array that mark different entities in the image 
        with ascending integers starting from 0, while 0 stand for background. 
        The pixels with a probability greater than `config.FOOD_PROB_THRESHOLD` 
        will be considered as food.
        `boxes` is a list of entity boxes having the same order with `label_mask`. 
        Each entity box is represented as a list of tuples, which stands for 
        `[(min width, max width), (min height, max height)]`. Background is not 
        included in `boxes`.
        Note that the coordinates of both return values are reduced according to 
        `config.BLOCK_REDUCT_WINDOW`. 
    """
    # TODO(canchen.lee@gmail.com): Consider using the colored image along with 
    # the mask to generate entity boxes, which separate enties within one connected 
    # component.
    bin_func = np.vectorize(lambda x: 0 if x < config.FOOD_PROB_THRESHOLD else 1)
    reduced_mask = bin_func(skimage.measure.block_reduce(mask, config.BLOCK_REDUCT_WINDOW, np.mean))
    label_mask = skimage.measure.label(reduced_mask, neighbors=4, background=0)
    boxes = [[
            *map(lambda x: (min(x), max(x) + 1), np.where(label_mask == entity))
        ] for entity in np.unique(label_mask)
    ]
    return label_mask, boxes[1:]


def _index_crop(array, i, multiplier):
    """ Cropping an image with a specified width and height index range as well 
        as a multiplier. The cropped image will be a square image that cover the 
        region specified by the index while having the minimum area.

    Args:
        array: A 3d numpy array with shape (width, height, 3).
        i: The crop index, represented as a list of tuples, such as 
            `[(1, 2), (3, 4)]`, which stands for `[(min width, max width), 
            (min height, max height)]`.
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


def get_recognition_results(image):
    """ Get the recognition result of the color image with corresponding mask.

    Get a list of image buffers with the cropped food image in `image`. Images 
        in the list are all resized to `config.CLASSIFIER_IMAGE_SIZE`.
    
    Args:
        image: The raw resolution colored square image, represented as a numpy array.
    
    Returns:
        A tuple `(label_mask, boxes, buffers)`.
        `label_mask` is a 2d numpy array that mark different entities in the image 
        with ascending integers starting from 0, while 0 stand for background. 
        The pixels with a probability greater than `config.FOOD_PROB_THRESHOLD` 
        will be considered as food.
        `boxes` is a list of entity boxes having the same order with `label_mask`. 
        Each entity box is represented as a list of tuples, which stands for 
        `[(width min, width max), (height min, height max)]`. Background is not 
        included in `boxes`.
        `buffers` is a list of image buffers, each image is the cropped food 
        image in `image`, and are all resized to `config.CLASSIFIER_IMAGE_SIZE`.
        Note that the coordinates of both return values are reduced according to 
        `config.BLOCK_REDUCT_WINDOW` on the basis of `config.UNIFIED_IMAGE_SIZE`.
    """
    resized_image = cv2.resize(image, config.UNIFIED_IMAGE_SIZE)
    mask = _get_segmentation(resized_image)
    np.save('/Users/Frost/Desktop/a.npy', mask)
    label_mask, boxes = _get_entity_labeling(resized_image, mask)
    multiplier = config.BLOCK_REDUCT_WINDOW[0] * image.shape[0] / config.UNIFIED_IMAGE_SIZE[0]
    images = [
        cv2.resize(
            _index_crop(image, box, multiplier),
            config.CLASSIFIER_IMAGE_SIZE
        ) for box in boxes
    ]
    buffers = [io.BytesIO() for _ in range(len(images))]
    [plt.imsave(buffer, image, format='jpeg') for buffer, image in zip(buffers, images)]
    return label_mask, boxes, buffers

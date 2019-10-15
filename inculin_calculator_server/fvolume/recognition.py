import skimage.measure
import numpy as np
import cv2
import io
import matplotlib.pyplot as plt

from . import config

def _get_entity_boxes(image, mask):
    """ Getting the boxes that cover the food entities in the image.

    Args:
        image: The colored image, represented as a numpy array with shape `(width, 
            height, 3)`.
        mask: The food segmentation mask. A numpy array with the same resolution 
            with `image`, and each pixel stands for the probability of the 
            corresponding pixel in `image` being food.
    
    Returns:
        A list of entity boxes. Each entity box is represented as a list of 
        tuples, which stands for `[(min width, max width), (min height, max height)]`. 
        Note that the coordinate is reduced in this list according to `config.block_reduct_window`. 
        The pixels with a probability greater than `config.food_prob_threshold` 
        will be considered as food.
    """
    # TODO(canchen.lee@gmail.com): Consider using the colored image along with 
    # the mask to generate entity boxes, which separate enties within one connected 
    # component.
    bin_func = np.vectorize(lambda x: 0 if x < config.food_prob_threshold else 1)
    reduced_mask = bin_func(skimage.measure.block_reduce(mask, config.block_reduct_window, np.mean))
    entity_labels = skimage.measure.label(reduced_mask, neighbors=4, background=0)
    boxes = [[
            *map(lambda x: (min(x), max(x) + 1), np.where(entity_labels == entity))
        ] for entity in np.unique(entity_labels)
    ]
    return boxes[1:]


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


def get_food_image_buffers(image, mask):
    """ Get a list of image buffers with the cropped food image in `image`. Images 
        in the list are all resized to `config.classifier_image_size`.
    
    Args:
        image: The raw resolution colored square image, represented as a numpy array.
        mask: The food segmentation mask. A numpy array with resolution 
            `config.unified_image_size`, and each pixel stands for the probability 
            of the pixel being food. The `mask` and `image` are basically the same 
            image with different resolution.
    
    Returns:
        A list of image buffers, each image is the cropped food image in `image`, 
        and are all resized to `config.classifier_image_size`.
    """
    entity_boxes = _get_entity_boxes(cv2.resize(image, config.unified_image_size), mask)
    multiplier = config.block_reduct_window[0] * image.shape[0] / config.unified_image_size[0]
    images = [
        cv2.resize(
            _index_crop(image, box, multiplier),
            config.classifier_image_size
        ) for box in entity_boxes
    ]
    buffers = [io.BytesIO() for _ in range(len(image))]
    [plt.imsave(buffer, image, format='jpeg') for buffer, image in zip(buffers, images)]
    return buffers

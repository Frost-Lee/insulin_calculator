import numpy as np

def center_crop(array):
    """ Crop the largest center square of an numpy array. Only the first two axis 
        are considered.
    
    Args:
        - array: The numpy array to crop. The array should have at least 2 dimensions.
    
    Returns:
        The center cropped numpy array. The first two axis are of equal length.
    """
    assert len(array.shape) >= 2
    if array.shape[0] == array.shape[1]:
        return array
    shape_difference = np.absolute(array.shape[0], array.shape[1])
    offset = shape_difference // 2
    if array.shape[0] > array.shape[1]:
        return array[offset:array.shape[1] + offset, :]
    else:
        return array[:, offset:array.shape[0] + offset]

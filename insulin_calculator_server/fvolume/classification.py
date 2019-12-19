import requests
import io
import json

from . import config
from . import config_secure

def _get_raw_classification_result(buffers):
    """ Fetching the response of the image classification from the classifier.

    Args:
        buffers: The image buffers to be classified.
    
    Returns:
        The list of responses from the classifier of the `buffer`.
    """
    responses = [requests.post(
        url=config_secure.CLASSIFIER_URL,
        headers={'Content-type': 'image/jpeg'},
        data=buffer.getvalue()
    ) for buffer in buffers[:config.MAX_ENTITIES_THRESHOLD]]
    if len(buffers) > config.MAX_ENTITIES_THRESHOLD:
        placeholders = ['{"is_food": false}' for _ in range(len(buffers) - config.MAX_ENTITIES_THRESHOLD)]
        return responses + placeholders
    else:
        return responses


unit_weights = {
    'Chocolate Donut': 0.0583,
    'Glazed Donut': 0.0627,
    'Chicken Nugget': 0.0155
}

def _correct_nutrition_unit(item):
    """ Make the nutrition unit of `item` to kilometer per kilometer.

    Due to the unit of nutrition offered by Calorie mama is inconsistant, we 
        need to manually unify the unit to kilometer per kilometer.
    
    Args:
        item: A json object containing nutrition information of the corresponding 
            food.
    """
    # TODO(canchen.lee@gmail.com): Find better ways to do this, either negotiate 
    # with Calorie mama, or create a library file.
    global unit_weights
    if 'servingWeight' not in item['servingSizes'][0]:
        if item['name'] in unit_weights:
            for key, value in item['nutrition'].items():
                item['nutrition'][key] = value / unit_weights[item['name']]
            for serving_size in item['servingSizes']:
                serving_size['corrected'] = True
    return item


def get_classification_result(buffers):
    """ Get the food classification results for a list of image buffers.

    Args:
        buffers: The image buffers to be classified.
    
    Returns:
        The list of classification results. Each classification result is a list 
            of candidates (represented as json format) if the object is food in 
            the corresponding image, or `None` if not.
    """
    responses = _get_raw_classification_result(buffers)
    json_contents = [json.loads(response.content.decode('utf8')) for response in responses]
    food_items = [
        [_correct_nutrition_unit(item) for result in content['results'] for item in sorted(
            result['items'], 
            key=lambda x: x['score'], 
            reverse=True
        )][:config.CLASSIFICATION_CANDIDATES] 
        if content['is_food'] else None for content in json_contents
    ]
    return food_items

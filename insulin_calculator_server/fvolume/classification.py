import requests
import io
import json

from . import config

def _get_raw_classification_result(buffers):
    """ Fetching the response of the image classification from the classifier.

    Args:
        buffers: The image buffers to be classified.
    
    Returns:
        The list of responses from the classifier of the `buffer`.
    """
    # TODO(canchen.lee@gmail.com): Control the number of request to Calorie mama 
    # API, avoid abuse.
    assert len(buffers) < 10
    return [requests.post(
        url=config.CLASSIFIER_URL,
        headers={'Content-type': 'image/jpeg'},
        data=buffer.getvalue()
    ) for buffer in buffers]


def get_classification_result(buffers):
    """ Get the food classification results for a list of image buffers.

    Args:
        buffers: The image buffers to be classified.
    
    Returns:
        The list of classification results. Each classification result is a list 
        of candidates (represented as json format) if the object is food in the 
        corresponding image, or `None` if not.
    """
    food_items = [None for _ in buffers]
    # responses = _get_raw_classification_result(buffers)
    # json_contents = [json.loads(response.content.decode('utf8')) for response in responses]
    # food_items = [
    #     [item for result in content['results'] for item in sorted(
    #         result['items'], 
    #         key=lambda x: x['score'], 
    #         reverse=True
    #     )][:config.CLASSIFICATION_CANDIDATES] 
    #     if content['is_food'] else None for content in json_contents
    # ]
    return food_items

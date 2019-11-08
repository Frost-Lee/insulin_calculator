import json
import numpy as np
import flask

import fvolume.classification
import fvolume.estimation
import fvolume.recognition
import fdensitylib.density

import data_manager


app = flask.Flask(__name__)


@app.route('/nutritionestimation', methods=['GET', 'POST'])
def response_nutrition_estimate():
    files, args = flask.request.files, flask.request.form
    if not (files['image'] and files['peripheral']):
        flask.abort(400, 'Unexpected file attachments.')
    if not (args.get('session_id') and args.get('token')):
        flask.abort(400, 'Request metadata not found.')
    session_data_manager = data_manager.SessionDataManager(args.get('session_id'))
    session_data_manager.register_image_file(files['image'])
    session_data_manager.register_peripheral_file(files['peripheral'])
    # response = _get_nutrition_estimate(session_data_manager)
    response = '{"results": []}'
    return response

@app.route('/densitycollect', methods=['GET', 'POST'])
def response_density_collect():
    files, args = flask.request.files, flask.request.form
    if not (files['image'] and files['peripheral']):
        flask.abort(400, 'Unexpected file attachments.')
    if not (args.get('session_id') and args.get('token')):
        flask.abort(400, 'Request metadata not found.')
    if not (args.get('name') and args.get('weight')):
        flask.abort(400, 'Request metadata not found.')
    session_data_manager = data_manager.SessionDataManager(args.get('session_id'), collection_session=True)
    session_data_manager.register_image_file(files['image'])
    session_data_manager.register_peripheral_file(files['peripheral'])
    session_data_manager.register_collection_label(args.get('name'), args.get('weight'))
    return '{"status": "OK"}'

def _get_nutrition_estimate(session_data_manager):
    """ Return the nutrition estimate of a session and store the result.
    Args:
        session_data_manager: The `SessionDataManager` object of this session. 
            The method assume the `image` and `peripheral` attribute of the 
            `session_data_manager` exist.
    """
    depth_map = np.array(session_data_manager.peripheral['depth_data'])
    calibration = session_data_manager.peripheral['calibration_data']
    attitude = session_data_manager.peripheral['device_attitude']
    label_mask, boxes, buffers = fvolume.recognition.get_recognition_results(
        session_data_manager.image,
        calibration
    )
    area_volumes = fvolume.estimation.get_area_volume(
        depth_map,
        calibration,
        attitude,
        label_mask
    )
    classifications = fvolume.classification.get_classification_result(
        buffers
    )
    densities = [[
        fdensitylib.density.get_density(candidate) for candidate in candidates
    ] if candidates is not None else None for candidates in classifications]
    # For non-food objects, `classifications` and `densities` have `None` values, 
    # but they still have value in `boxes` and `area_volumes`.
    response = _format_estimate_response(classifications, area_volumes, densities, boxes)
    session_data_manager.save_recognition_file(response)
    return response


def _format_estimate_response(classifications, area_volumes, densities, boxes):
    """ Format the nutrition estimation returned by the model to a json string.
    Note that all arguments are lists, and they should follow the same object 
    order.
    
    Args:
        classifications: The food classifications. Each classification contains 
            several candidates, and each candidates object is a json object containing 
            one specific food information. A `None` classification indicates the 
            corresponding item is not food.
        area_volumes: The area and volume estimation of all objects. Each item 
            is `(area, volume)`.
        densities: The density look up of all objects. Each item is 
            `(area_density, volume_density)` or `None`, which indicates the item 
            is not food.
        boxes: A list of object boxes. Each object box is represented as a list 
            of tuples, which stands for 
            `[(width min, width max), (height min, height max)]`.
    """
    candidates_list = classifications
    for i, candidates in enumerate(candidates_list):
        if candidates is None:
            continue
        for j, candidate in enumerate(candidates):
            candidates_list[i][j]['volume_density'] = densities[i][j][0]
            candidates_list[i][j]['area_density'] = densities[i][j][1]
    response = {
        'results' : [{
            'area' : av[0],
            'volume' : av[1],
            'bounding_box' : bb,
            'candidates' : cs
        } for av, bb, cs in zip(area_volumes, boxes, candidates_list) if cs is not None]
    }
    return json.dumps(response, indent=4, sort_keys=True)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

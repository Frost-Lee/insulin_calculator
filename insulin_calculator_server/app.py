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
    response = '{"results": []}'
    return response

@app.route('/densitycollect', methods=['GET', 'POST'])
def response_density_collect():
    files, args = flask.request.files, flask.request.form
    if not (files['image'] and files['additional'] and files['peripheral']):
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


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

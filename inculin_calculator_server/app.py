import json
import numpy as np
import flask

import fvolume.classification
import fvolume.estimation
import fvolume.recognition
import data_manager


app = flask.Flask(__name__)

@app.route('/nutritionestimation', methods=['GET', 'POST'])
def response_nutrition_estimate():
    files, args = flask.request.files, flask.request.args
    if not (files['image'] and files['peripheral']):
        flask.abort(400, 'Unexpected file attachments.')
    if not (args.get('session_id') and args.get('token')):
        flask.abort(400, 'Request metadata not found.')
    session_data_manager = data_manager.Session_Data_Manager(args.get('session_id'))
    session_data_manager.register_image_file(files['image'])
    session_data_manager.register_peripheral_file(files['peripheral'])


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

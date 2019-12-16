import argparse
import os
import analysis


arg_parser = argparse.ArgumentParser(
    description='A module for running batch testing for the system.'
)
arg_group = arg_parser.add_mutually_exclusive_group(required=True)
arg_group.add_argument(
    '-g',
    '--generate',
    nargs=4,
    help='Generate a storage directory for a food entity. Arguments: directory root path, directory name, food name, food weight.'
)
arg_group.add_argument(
    '-e',
    '--estimate',
    type=str,
    help='Estimating the food volumes for all captures in a directory.'
)
arg_group.add_argument(
    '-c',
    '--clean',
    type=str,
    help='Cleaning estimated result files in the given data directory.'
)
arg_group.add_argument(
    '-p',
    '--plot',
    nargs=2,
    help='Plot all graphs for all captures in a directory. Arguments: input directory, output directory.'
)
args = arg_parser.parse_args()

VARIATE_ACCESSES = {
    None: None, 
    'height': (lambda x: x['height']), 
    'pitch': (lambda x: x['angle']['pitch']),
    'roll': (lambda x: x['angle']['roll']),
    'deviation': (lambda x: x['center_deviation']),
    'background': (lambda x: x['background'])
}
VARIATES = [*VARIATE_ACCESSES.keys()]

if args.generate:
    import json

    food_name = args.generate[2]
    food_weight = float(args.generate[3])

    def get_control_variates_cases(variate_name, variate_list):
        global food_name, food_weight
        test_cases = [analysis.utils.TestCase(food_name, food_weight, i) for i in range(len(variate_list))]
        if variate_name is None:
            return test_cases
        for case, variate in zip(test_cases, variate_list):
            setattr(case, variate_name, variate)
        return test_cases
    
    def path_gen(path_dict, root_path):
        for key in path_dict:
            if type(path_dict[key]) is dict:
                yield from path_gen(path_dict[key], os.path.join(root_path, key))
            else:
                yield (path_dict[key], os.path.join(root_path, key))
    
    path_dict = {
        args.generate[1]: {
            'reference': get_control_variates_cases(VARIATES[0], [None]),
            VARIATES[1]: get_control_variates_cases(
                VARIATES[1], 
                [0.4, 0.5, 0.55, 0.6]
            ),
            VARIATES[2]: get_control_variates_cases(
                VARIATES[2], 
                [-2.0, -4.0, -6.0, -8.0, -10.0, -15.0, -20.0, -25.0, -30.0, 2.0, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0]
            ),
            VARIATES[3]: get_control_variates_cases(
                VARIATES[3],
                [-2.0, -4.0, -6.0, -8.0, -10.0, -15.0, -20.0, -25.0, -30.0, 2.0, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0]
            ),
            VARIATES[4]: get_control_variates_cases(
                VARIATES[4],
                [0.02, 0.04, 0.06, 0.08, 0.1]
            ),
            VARIATES[5]: get_control_variates_cases(
                VARIATES[5], 
                ['Wood table 76-660', 'Cupboard 76-651', 'Dining table 76-651', 'Window table 76-651']
            )
        }
    }

    for cases, path in path_gen(path_dict, args.generate[0]):
        for case in cases:
            dir_path = os.path.join(path, case.dir_name())
            os.makedirs(dir_path)
            with open(os.path.join(dir_path, 'metadata.json'), 'w') as out_file:
                out_file.write(case.to_json_string())
    exit()


if args.estimate:
    import fvolume
    import numpy as np
    def get_area_volume_estimate(image, peripheral, path):
        depth_map = np.array(peripheral['depth_data'])
        calibration = peripheral['calibration_data']
        attitude = peripheral['device_attitude']
        fvolume.estimation.FILE_DIR = path
        fvolume.recognition.FILE_DIR = path
        label_mask, boxes, buffers = fvolume.recognition.get_recognition_results(
            image,
            calibration
        )
        area_volumes = fvolume.estimation.get_area_volume(
            depth_map,
            calibration,
            attitude,
            label_mask
        )
        return area_volumes
    for path in analysis.utils.capture_storage_dirs(args.estimate):
        if os.path.exists(os.path.join(path, 'result.json')):
            continue
        print('\rProcessing: ', path, end='')
        try:
            image = analysis.utils.load_image(os.path.join(path, 'image.jpg'))
            peripheral = analysis.utils.load_peripheral(os.path.join(path, 'peripheral.json'))
            result_json = analysis.utils.format_result(
                get_area_volume_estimate(image, peripheral, path)
            )
            with open(os.path.join(path, 'result.json'), 'w') as out_file:
                out_file.write(result_json)
        except ValueError:
            print('\rCapture error at', path)
    exit()


if args.clean:
    for root, dirs, files in os.walk(args.clean):
        for file_name in files:
            if file_name == 'result.json' or file_name == 'food_pc.npy' or file_name == 'full_pc.npy' or file_name == 'mask.jpg' or file_name == 'projection.jpg':
                os.remove(os.path.join(root, file_name))
    exit()


if args.plot:
    root, entity_dirs, _ = next(os.walk(args.plot[0]))
    for entity_dir in entity_dirs:
        case_storage_dirs = analysis.utils.case_storage_dirs(os.path.join(root, entity_dir))
        reference_dir = [dir for dir in case_storage_dirs if 'reference' in dir][0]
        variate_dirs = [dir for dir in case_storage_dirs if 'reference' not in dir]
        for variate_dir in variate_dirs:
            variate = os.path.basename(os.path.normpath(variate_dir))
            df = analysis.utils.get_result_df(
                reference_dir,
                variate_dir,
                VARIATE_ACCESSES[variate]
            )
            analysis.visualize.visualize_result_df(
                df, 
                os.path.join(args.plot[1], '{}_{}.{}'.format(entity_dir, variate, 'jpg'))
            )
    exit()

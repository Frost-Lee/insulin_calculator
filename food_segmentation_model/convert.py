import coremltools
import argparse

arg_parser = argparse.ArgumentParser(
    description='Converting food recognition model from Keras to CoreML.'
)
arg_parser.add_argument(
    '-i',
    help='File path of input Keras model archive, in .h5 format.',
    type=str,
    required=True
)
arg_parser.add_argument(
    '-o',
    help='Output path of generated .mlmodel file.',
    type=str,
    required=True
)
args = arg_parser.parse_args()

keras_model_path = args.i
coreml_model_output_path = args.o

fr_coreml_model = coremltools.converters.keras.convert(
    keras_model_path,
    input_names='input_image',
    image_input_names='input_image',
    output_names='mask',
    red_bias=32.0,
    green_bias=32.0,
    blue_bias=32.0,
    image_scale=1.0/66.0
)

fr_coreml_model.author = '李灿晨'
fr_coreml_model.license = 'MIT'
fr_coreml_model.short_description = 'Model for recognizing food in images'
fr_coreml_model.input_description['input_image'] = 'A RGB image with size of 512 * 512'
fr_coreml_model.output_description['mask'] = 'The probability mask of each pixel being food'

spec = fr_coreml_model.get_spec()
Float32 = coremltools.proto.FeatureTypes_pb2.ArrayFeatureType.FLOAT32
spec.description.output[0].type.multiArrayType.dataType = Float32
coremltools.utils.save_spec(spec, coreml_model_output_path)
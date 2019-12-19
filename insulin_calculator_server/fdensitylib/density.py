from . import library

def get_density(food_item):
    """ Give the area and volume density with a food object. In kilogram per cube 
        meter.
    
    Args:
        food_item: The json object of food information.
    """
    if food_item['group'] in library.density_library:
        if food_item['name'] in library.density_library[food_item['group']]:
            return library.density_library[food_item['group']][food_item['name']]
        else:
            return [*library.density_library[food_item['group']].values()][0]
    else:
        return 0.0, 0.0

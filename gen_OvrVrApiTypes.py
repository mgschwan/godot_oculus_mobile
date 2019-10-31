# Note: this does not work yet as the enums reference themselves in the C file
#       which is not suppored in gdscript; so this would need to be resolved


"""
A utility script to autogenerate the addons/godot_ovrmobile/OvrVrApiTypes.gd from the ovr_sdk_mobile/VrApi/Include/VrApi_Types.h
"""
input_vrapi_types_filename = "ovr_sdk_mobile/VrApi/Include/VrApi_Types.h";
#output_gdscript_file = "demo/addons/godot_ovrmobile/OvrVrApiTypes.gd";
output_gdscript_file = "test_typesenum_output.gd"


def format_and_write_enum(enum_name, enum_text, out_file):
    out_file.write("enum " + enum_name[0].upper() + enum_name[1:] + " ");

    enum_text = enum_text.replace("//", '#');
    out_file.write(enum_text);
    out_file.write("\n\n");


def find_and_write_enums(text, out_file):
    pos = text.find("typedef enum");
    while pos != -1:
        start_pos = text.find("{", pos);
        end_pos = text.find("}", pos)+1; # note: this only works if nobody uses } in comments
        name_end_pos = text.find(";", end_pos);
        
        enum_text = text[start_pos:end_pos];
        enum_name = text[end_pos:name_end_pos].strip();
        
        pos = text.find("typedef enum", end_pos);

        format_and_write_enum(enum_name, enum_text, out_file);


with open(output_gdscript_file , "w") as output_file:
    with open(input_vrapi_types_filename, "r") as input_file:
        find_and_write_enums(input_file.read(), output_file);


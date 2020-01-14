#include "config_common.h"
#include "ovr_mrc.h"

#include "OVR_Mrc_Shim.h"
#include "../Source/OVR_Mrc_Shim.cpp"

typedef struct ovr_mrc_data_struct {
	ovrmobile::OvrMobileSession *ovr_mobile_session;
    OVRM_API_STRUCTURE* ovrm_api;
} ovr_mrc_data_struct;

static const char *kClassName = "OvrMRC";

// No need to put these functions into the header; they are only exposed via the .gdns api
GDCALLINGCONV void *ovr_mrc_constructor(godot_object *p_instance, void *p_method_data);
GDCALLINGCONV void ovr_mrc_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data);

GDCALLINGCONV godot_variant initialize(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args);

void register_gdnative_mrc(void *p_handle) {
    { // register the constructor and destructor of the OvrUtilitites class for use in GDScript
		godot_instance_create_func create = { NULL, NULL, NULL };
		create.create_func = &ovr_mrc_constructor;

		godot_instance_destroy_func destroy = { NULL, NULL, NULL };
		destroy.destroy_func = &ovr_mrc_destructor;

		nativescript_api->godot_nativescript_register_class(p_handle, kClassName, "Reference", create, destroy);
	}

	{ // register all the functions that we want to expose via the Ovrmrc class in GDScript
		godot_instance_method method = { NULL, NULL, NULL };
		godot_method_attributes attributes = { GODOT_METHOD_RPC_MODE_DISABLED };

   		method.method = &initialize;
		nativescript_api->godot_nativescript_register_method(p_handle, kClassName, "initialize", attributes, method);
	}
}


GDCALLINGCONV void *ovr_mrc_constructor(godot_object *p_instance, void *p_method_data) {
	ovr_mrc_data_struct *ovr_mrc_data;

	ovr_mrc_data = (ovr_mrc_data_struct *)api->godot_alloc(sizeof(ovr_mrc_data_struct));
	if (ovr_mrc_data != NULL) {
		ovr_mrc_data->ovr_mobile_session = ovrmobile::OvrMobileSession::get_singleton_instance();
        ovr_mrc_data->ovrm_api = NULL;
	}

	return ovr_mrc_data;
}


GDCALLINGCONV void ovr_mrc_destructor(godot_object *p_instance, void *p_method_data, void *p_user_data) {
	if (p_user_data != NULL) {
        ovrm_UnloadSharedLibrary();
		ovr_mrc_data_struct *ovr_mrc_data = (ovr_mrc_data_struct *) p_user_data;
		if (ovr_mrc_data->ovr_mobile_session != NULL) {
			ovr_mrc_data->ovr_mobile_session = NULL;
            ovr_mrc_data->ovrm_api = NULL;
		}
	}
}


GDCALLINGCONV godot_variant initialize(godot_object *p_instance, void *p_method_data, void *p_user_data, int p_num_args, godot_variant **p_args) {
    CHECK_OVR(

        ovr_mrc_data_struct* ovr_mrc_data = (ovr_mrc_data_struct*)p_user_data;
      
        bool result_load_shared_library = ovrm_LoadSharedLibrary();
        if (!result_load_shared_library) {
            ALOGE("OvrMrc: initialize(): failed to load shared library");
    		api->godot_variant_new_bool(&ret, false);
            return ret;
        } 

        ovr_mrc_data->ovrm_api = ovrm_GetAPIs();

        if (!ovr_mrc_data->ovrm_api) {
            ALOGE("OvrMrc: initialize(): ovrm_GetAPIs() failed to return API.");
    		api->godot_variant_new_bool(&ret, false);
            return ret;
        }

        int majorVersion = 0;
        int minorVersion = 0;
        int patchVersion = 0;
        ovr_mrc_data->ovrm_api->GetVersions(&majorVersion, &minorVersion, &patchVersion);
        ALOGV("OvrMrc: initializing ovrm version %d.%d.%d", majorVersion, minorVersion, patchVersion);

        ovrmResult result_ovrm_initialize = ovr_mrc_data->ovrm_api->Initialize(ovr, (void*)ovr_java, ovr_java->ActivityObject);

        if (result_ovrm_initialize != ovrmSuccess) {
            ALOGE("OvrMrc: initialize(): ovrm_Initialize(...) failed with code %d", result_ovrm_initialize);
            api->godot_variant_new_bool(&ret, false);
            return ret;
        } 
          
        ovrmResult result_ovrm_configure_gles = ovr_mrc_data->ovrm_api->ConfigureGLES(eglGetCurrentContext(), false, false);
        if (result_ovrm_configure_gles != ovrmSuccess) {
            ALOGE("OvrMrc: initialize(): ovrm_ConfigureGLES(...) failed with code %d", result_ovrm_configure_gles);
            api->godot_variant_new_bool(&ret, false);
            return ret;
        }

        api->godot_variant_new_bool(&ret, true);
    );
}


extends Spatial


enum ovrmMediaMrcActivationMode {
  Automatic = 0,
  Disabled = 1,
};

enum ovrmMediaInputVideoBufferType {
  Memory = 0,
  TextureHandle = 1,
};

var ovr_mrc = null;


var count = 0;

func _process(_dt):
	count += 1;
	
	if (ovr_mrc):
		if (!ovr_mrc.update()):
			print("ovr_mrc.update() failed")
		if (ovr_mrc.is_mrc_activated()):
			pass;

		if (count >= 72*5):
			count = 0;
			print("ovr_mrc.is_mrc_enabled() = " + str(ovr_mrc.is_mrc_enabled()));
			print("ovr_mrc.is_mrc_activated() = " + str(ovr_mrc.is_mrc_activated()));
			
			print("ovr_mrc.get_external_camera_count() = " + str(ovr_mrc.get_external_camera_count()));
			for c in range(0, ovr_mrc.get_external_camera_count()):
				print(c);
				print("ovr_mrc.get_external_camera_intrinsics(...) = " + str(ovr_mrc.get_external_camera_intrinsics(c)));
				print("ovr_mrc.get_external_camera_extrinsics(...) = " + str(ovr_mrc.get_external_camera_extrinsics(c)));
				
			print("---------");
	

func _ready():
	ovr_mrc = load("res://addons/godot_ovrmobile/OvrMRC.gdns");

	if (ovr_mrc.library.get_current_library_path() != ""):
		ovr_mrc = ovr_mrc.new()
		ovr_mrc.initialize();

		ovr_mrc.set_mrc_activation_mode(ovrmMediaMrcActivationMode.Automatic);
		
		print("ovr_mrc.get_mrc_activation_mode() = " + str(ovr_mrc.get_mrc_activation_mode()));
		
		ovr_mrc.set_mrc_input_video_buffer_type(ovrmMediaInputVideoBufferType.TextureHandle);
		ovr_mrc.set_mrc_audio_sample_rate(44000);
	else:
		ovr_mrc = null;
		


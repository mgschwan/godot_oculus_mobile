extends Spatial


enum ovrmMediaMrcActivationMode {
  Automatic = 0,
  Disabled = 1,
};

enum ovrmMediaInputVideoBufferType {
  Memory = 0,
  TextureHandle = 1,
};

enum mrcCameraIntrinsics {
	IsValid = 0,					# bool
	LastChangedTimeSeconds,			# real
	FOVPort_UpTan,					# real
	FOVPort_DownTan,				# real
	FOVPort_LeftTan,				# real
	FOVPort_RightTan,				# real
	VirtualNearPlaneDistanceMeters,	# real
	VirtualFarPlaneDistanceMeters,	# real
	ImageSensorPixelResolution_w,	# int
	ImageSensorPixelResolution_h,	# int
};

enum mrcCameraExtrinsics {
	IsValid = 0,			# bool
	LastChangedTimeSeconds, # real
	CameraStatus,			# int
	AttachedToNode,			# int
	RelativePose			# transform
};

var ovr_mrc = null;

onready var _viewport_back = $Viewport;
onready var _camera_back = $Viewport/Camera; # for now only a single camera is supported


func _mrc_update_capture_camera(mrc_camera_id, cam, vp):
	var intrinsics = ovr_mrc.get_external_camera_intrinsics(mrc_camera_id);
	var extrinsics = ovr_mrc.get_external_camera_extrinsics(mrc_camera_id);
	
	vp.size = Vector2(intrinsics[mrcCameraIntrinsics.ImageSensorPixelResolution_w], intrinsics[mrcCameraIntrinsics.ImageSensorPixelResolution_h]);
	
	var h_fov = intrinsics[mrcCameraIntrinsics.FOVPort_LeftTan] + intrinsics[mrcCameraIntrinsics.FOVPort_RightTan]
	var v_fov = intrinsics[mrcCameraIntrinsics.FOVPort_UpTan] + intrinsics[mrcCameraIntrinsics.FOVPort_DownTan]
	
	cam.fov = rad2deg(h_fov);
	#cam.near = intrinsics[mrcCameraIntrinsics.VirtualNearPlaneDistanceMeters];
	#cam.far = intrinsics[mrcCameraIntrinsics.VirtualFarPlaneDistanceMeters];
	
	cam.global_transform = extrinsics[mrcCameraExtrinsics.RelativePose];
	
	print("cam update: fov = %f near = %f far = %f resX = %d resY = %d" % [cam.fov, cam.near, cam.far, vp.size.x, vp.size.y])
	

var count = 0;

var _last_sync_id = 0;
var _mrc_render_toggle = true;

func _process(_dt):
	count += 1;
	

	
	if (ovr_mrc):
		if (!ovr_mrc.update()):
			print("ovr_mrc.update() failed")
		if (ovr_mrc.is_mrc_activated()):
			
			if (ovr_mrc.get_external_camera_count() > 0):
				_mrc_update_capture_camera(0, _camera_back, _viewport_back);
				# render once
				_viewport_back.render_target_update_mode = Viewport.UPDATE_ONCE;

				if (_mrc_render_toggle):
					var timestamp = OS.get_ticks_usec();
					var texture_id = VisualServer.texture_get_texid(_viewport_back.get_texture());
					_last_sync_id = ovr_mrc.encode_mrc_frame(texture_id, timestamp);
					#_last_sync_id = ovr_mrc.encode_mrc_frame_with_dual_texture(texture_id, texture_id, timestamp);
					
					print("timestamp = %d; texture_id = %d; _last_sync_id = %d" % [timestamp, texture_id, _last_sync_id]);
					_mrc_render_toggle = false;
				else:
					ovr_mrc.sync_mrc_frame(_last_sync_id);
					_mrc_render_toggle = true;
				
			
			
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
		
		
	#print(VisualServer.texture_get_texid(mrc_viewport.get_texture()))


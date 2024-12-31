extends GPUParticles3D

var rd:RenderingDevice
var shader:RID
var pipeline:RID
var params_buffer:RID
var uniform_set:RID
var activated:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.call_on_render_thread(_setup_compute)
	
func _generate_params(delta:float)->PackedByteArray:
	return PackedFloat32Array([delta]).to_byte_array()
	
func _setup_compute()->void:
	rd = RenderingServer.get_rendering_device()
	
	var params := _generate_params(0)
	params_buffer = rd.storage_buffer_create(params.size(),params)
	var delta_uniform := _generate_uniform(params_buffer,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0)
	
	var pos_uniform: = _generate_uniform(_generate_vec3_buffer(rand_arr(1024)),RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,1)
	var vel_uniform: = _generate_uniform(_generate_vec3_buffer(rand_arr(1024)),RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,2)

	var data_buffer := _get_texture_buffer(1024,1)
	
	var output_tex :Texture2DRD= self.process_material.get_shader_parameter("pos_data")
	output_tex.texture_rd_rid = data_buffer
	
	var shader_file := load("res://compute/gravity.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	var output_uniform := _generate_uniform(data_buffer,RenderingDevice.UNIFORM_TYPE_IMAGE,3)
	uniform_set = rd.uniform_set_create([delta_uniform,pos_uniform,vel_uniform,output_uniform],shader,0)

func _generate_uniform(data_buffer:RID, type:int, binding:int) -> RDUniform:
	var data_uniform := RDUniform.new()
	data_uniform.uniform_type = type
	data_uniform.binding = binding
	data_uniform.add_id(data_buffer)
	return data_uniform

func _generate_vec3_buffer(data:Array[Vector3])->RID:
	var data_buffer_bytes := PackedVector3Array(data).to_byte_array()
	var data_buffer := rd.storage_buffer_create(data_buffer_bytes.size(), data_buffer_bytes)
	return data_buffer
	
func _get_texture_buffer(x:int,y:int)->RID:
	var pos_tex:=Image.create(x,y, false, Image.FORMAT_RGBAH)
	var fmt:= RDTextureFormat.new()
	fmt.width=32
	fmt.height=32
	fmt.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	
	var view := RDTextureView.new()
	return rd.texture_create(fmt,view,[pos_tex.get_data()])

func rand_arr(n:int) -> Array[Vector3]:
	var arr:Array[Vector3] = []
	for i in range(n):
		arr.append(Vector3(randf(),randf(),randf()))
	return arr

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		activated = true
	if activated:
		RenderingServer.call_on_render_thread(_compute.bind(delta))


func _compute(delta:float) ->void:
	var params:PackedByteArray = _generate_params(delta)
	rd.buffer_update(params_buffer,0,params.size(),params)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1024,1, 1)
	rd.compute_list_end()

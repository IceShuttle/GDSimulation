extends GPUParticles3D

@export var mass:=1.0
@export var elasticity:=.9
@export var gravity:=9.8
@export var target_density:= 200.
@export var pressure_multiplier:=1


var rd:RenderingDevice

var gravity_shader:RID
var gravity_pipeline:RID
var gravity_uniform_set:RID

var density_buffer:RID
var density_shader:RID
var density_pipeline:RID
var density_uniform_set:RID

var params_buffer:RID
var activated:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("tree_exiting",_on_exit)
	RenderingServer.call_on_render_thread(_setup_compute)
	
func _generate_params(delta:float)->PackedByteArray:
	return PackedFloat32Array([1024,mass,elasticity,gravity,target_density,pressure_multiplier,delta]).to_byte_array()
	
func _setup_compute()->void:
	rd = RenderingServer.get_rendering_device()
	
	var params := _generate_params(0)
	params_buffer = rd.storage_buffer_create(params.size(),params)
	var params_uniform := _generate_uniform(params_buffer,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0)
	
	var pos_uniform: = _generate_uniform(_generate_vec3_buffer(rand_vec3_arr(1024)),RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,1)
	var vel_uniform: = _generate_uniform(_generate_vec3_buffer(rand_vec3_arr(1024)),RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,2)
	density_buffer = _generate_float_buffer(num_float_arr(1024,0))
	var density_uniform := _generate_uniform(density_buffer,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,3)

	var data_buffer := _get_texture_buffer(1024,1)
	
	var output_tex :Texture2DRD= self.process_material.get_shader_parameter("pos_data")
	output_tex.texture_rd_rid = data_buffer
	
	var gravity_shader_file := load("res://compute/gravity.glsl")
	var gravity_shader_spirv: RDShaderSPIRV = gravity_shader_file.get_spirv()
	gravity_shader = rd.shader_create_from_spirv(gravity_shader_spirv)
	gravity_pipeline = rd.compute_pipeline_create(gravity_shader)
	
	
	
	var density_shader_file := load("res://compute/density.glsl")
	var density_shader_spirv:RDShaderSPIRV = density_shader_file.get_spirv()
	density_shader = rd.shader_create_from_spirv(density_shader_spirv)
	density_pipeline = rd.compute_pipeline_create(density_shader)
	
	var output_uniform := _generate_uniform(data_buffer,RenderingDevice.UNIFORM_TYPE_IMAGE,4)
	var param_set:=[params_uniform,pos_uniform,vel_uniform,density_uniform,output_uniform]
	
	gravity_uniform_set = rd.uniform_set_create(param_set,gravity_shader,0)
	density_uniform_set = rd.uniform_set_create(param_set,density_shader,0)

func _generate_uniform(data_buffer:RID, type:int, binding:int) -> RDUniform:
	var data_uniform := RDUniform.new()
	data_uniform.uniform_type = type
	data_uniform.binding = binding
	data_uniform.add_id(data_buffer)
	return data_uniform
	
func _generate_float_buffer(data:Array[float])->RID:
	var data_buffer_bytes := PackedFloat32Array(data).to_byte_array()
	var data_buffer := rd.storage_buffer_create(data_buffer_bytes.size(), data_buffer_bytes)
	return data_buffer

func _generate_vec3_buffer(data:Array[Vector3])->RID:
	var data_buffer_bytes := PackedVector3Array(data).to_byte_array()
	var data_buffer := rd.storage_buffer_create(data_buffer_bytes.size(), data_buffer_bytes)
	return data_buffer
	
func _get_texture_buffer(x:int,y:int)->RID:
	var pos_tex:=Image.create(x,y, false, Image.FORMAT_RGBAH)
	var fmt:= RDTextureFormat.new()
	fmt.width=x
	fmt.height=y
	fmt.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	
	var view := RDTextureView.new()
	return rd.texture_create(fmt,view,[pos_tex.get_data()])

func rand_vec3_arr(n:int) -> Array[Vector3]:
	var arr:Array[Vector3] = []
	for i in range(n):
		arr.append(Vector3(randf(),randf(),randf()))
	return arr
func num_float_arr(n:int,val:float)->Array[float]:
	var arr :Array[float]= []
	for i in range(n):
		arr.append(val)
	return arr

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		activated = true
	if activated:
		RenderingServer.call_on_render_thread(_compute.bind(delta))


func _compute(delta:float) ->void:
	calculate_gravity(delta)
	compute_shader_pipeline(density_pipeline,density_uniform_set)
	
	
	var out:=rd.buffer_get_data(density_buffer)
	var opt :=out.to_float32_array()
	var sum:=0.
	for i in opt:
		sum+=i
	print(sum/opt.size())
	#rd.submit()
	
func calculate_gravity(delta:float)->void:
	var params:PackedByteArray = _generate_params(delta)
	rd.buffer_update(params_buffer,0,params.size(),params)
	compute_shader_pipeline(gravity_pipeline,gravity_uniform_set)
	
func compute_shader_pipeline(pipeline:RID,uniform_set:RID)->void:
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1024,1, 1)
	rd.compute_list_end()
	
func _on_exit()->void:
	print("exited")
	rd.free_rid(gravity_shader)
	rd.free_rid(params_buffer)
	rd.free_rid(gravity_uniform_set)
	rd.free_rid(gravity_uniform_set)

class_name CaveGenerator
extends VoxelGeneratorScript
## Hands Voxel Tools the blocks that the Cave Maker designs.
## Voxel Tools calls this from background threads.

var maker: CaveMaker


func _init(p_maker: CaveMaker = null) -> void:
	maker = p_maker


func _get_used_channels_mask() -> int:
	return (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES)


func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, _lod: int) -> void:
	maker.generate_block(out_buffer, origin_in_voxels)

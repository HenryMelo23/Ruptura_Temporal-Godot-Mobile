class_name RTWorldSnapshotChunker
extends RefCounted

const MAX_DECODED_PAYLOAD_BYTES: int = 512 * 1024


static func encode(enemies_data, boss_data, bullets_data) -> PackedByteArray:
	var raw_payload: PackedByteArray = var_to_bytes([enemies_data, boss_data, bullets_data])
	var compressed_payload: PackedByteArray = raw_payload.compress(FileAccess.COMPRESSION_FASTLZ)
	var payload: = PackedByteArray()
	payload.resize(4)
	payload.encode_u32(0, raw_payload.size())
	payload.append_array(compressed_payload)
	return payload


static func decode(payload: PackedByteArray) -> Array:
	if payload.size() <= 4:
		return []
	var decoded_size: int = payload.decode_u32(0)
	if decoded_size <= 0 or decoded_size > MAX_DECODED_PAYLOAD_BYTES:
		return []
	var compressed_payload: PackedByteArray = payload.slice(4)
	var raw_payload: PackedByteArray = compressed_payload.decompress(decoded_size, FileAccess.COMPRESSION_FASTLZ)
	if raw_payload.is_empty():
		return []
	var decoded = bytes_to_var(raw_payload)
	if not decoded is Array or decoded.size() != 3:
		return []
	return decoded


static func encode_variant(value: Variant) -> PackedByteArray:
	var raw_payload: PackedByteArray = var_to_bytes(value)
	var compressed_payload: PackedByteArray = raw_payload.compress(FileAccess.COMPRESSION_FASTLZ)
	var payload: = PackedByteArray()
	payload.resize(4)
	payload.encode_u32(0, raw_payload.size())
	payload.append_array(compressed_payload)
	return payload


static func decode_variant(payload: PackedByteArray) -> Variant:
	if payload.size() <= 4:
		return null
	var decoded_size: int = payload.decode_u32(0)
	if decoded_size <= 0 or decoded_size > MAX_DECODED_PAYLOAD_BYTES:
		return null
	var compressed_payload: PackedByteArray = payload.slice(4)
	var raw_payload: PackedByteArray = compressed_payload.decompress(decoded_size, FileAccess.COMPRESSION_FASTLZ)
	if raw_payload.is_empty():
		return null
	return bytes_to_var(raw_payload)


static func split(payload: PackedByteArray, chunk_payload_bytes: int) -> Array:
	var chunks: Array = []
	var safe_size: int = maxi(1, chunk_payload_bytes)
	for offset in range(0, payload.size(), safe_size):
		chunks.append(payload.slice(offset, mini(payload.size(), offset + safe_size)))
	if chunks.is_empty():
		chunks.append(PackedByteArray())
	return chunks


static func join(chunks_by_index: Dictionary, chunk_count: int, max_chunk_count: int) -> PackedByteArray:
	if chunk_count <= 0 or chunk_count > max_chunk_count or chunks_by_index.size() != chunk_count:
		return PackedByteArray()
	var payload: = PackedByteArray()
	for chunk_index in range(chunk_count):
		if not chunks_by_index.has(chunk_index):
			return PackedByteArray()
		var chunk = chunks_by_index[chunk_index]
		if not chunk is PackedByteArray:
			return PackedByteArray()
		payload.append_array(chunk)
	return payload

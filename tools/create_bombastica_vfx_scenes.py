import os

VFX_DIR = "vfx/bombastica"

def create_mine_scene():
    tscn_content = """[gd_scene load_steps=18 format=3 uid="uid://b8m2mine1234"]

[ext_resource type="Script" path="res://vfx/bombastica/BombasticaMineExplosionVFX.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://c1core_sheet" path="res://vfx/bombastica/textures/explosion_core_sheet.png" id="2_core_sheet"]
[ext_resource type="Texture2D" uid="uid://c4spark" path="res://vfx/bombastica/textures/spark_texture.png" id="3_spark_tex"]
[ext_resource type="Texture2D" uid="uid://c5ember" path="res://vfx/bombastica/textures/ember_texture.png" id="4_ember_tex"]
[ext_resource type="Texture2D" uid="uid://c6debris" path="res://vfx/bombastica/textures/debris_texture.png" id="5_debris_tex"]
[ext_resource type="Material" uid="uid://m1sparks" path="res://vfx/bombastica/materials/bombastica_sparks.tres" id="6_sparks_mat"]
[ext_resource type="Material" uid="uid://m2embers" path="res://vfx/bombastica/materials/bombastica_embers.tres" id="7_embers_mat"]
[ext_resource type="Material" uid="uid://m3debris" path="res://vfx/bombastica/materials/bombastica_debris.tres" id="8_debris_mat"]

[sub_resource type="AtlasTexture" id="AtlasTexture_m0"]
atlas = ExtResource("2_core_sheet")
region = Rect2(0, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_m1"]
atlas = ExtResource("2_core_sheet")
region = Rect2(64, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_m2"]
atlas = ExtResource("2_core_sheet")
region = Rect2(128, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_m3"]
atlas = ExtResource("2_core_sheet")
region = Rect2(192, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_m4"]
atlas = ExtResource("2_core_sheet")
region = Rect2(256, 0, 64, 64)

[sub_resource type="SpriteFrames" id="SpriteFrames_mine"]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_m0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_m1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_m2")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_m3")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_m4")
}],
"loop": false,
"name": &"default",
"speed": 28.0
}]

[sub_resource type="Gradient" id="Gradient_light"]
offsets = PackedFloat32Array(0, 0.5, 1)
colors = PackedColorArray(1, 0.8, 0.3, 1, 1, 0.4, 0.1, 0.6, 0, 0, 0, 0)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_light"]
gradient = SubResource("Gradient_light")
width = 96
height = 96
fill = 1
fill_from = Vector2(0.5, 0.5)

[node name="BombasticaMineExplosionVFX" type="Node2D"]
script = ExtResource("1_script")

[node name="ExplosionCore" type="AnimatedSprite2D" parent="."]
texture_filter = 0
sprite_frames = SubResource("SpriteFrames_mine")

[node name="Sparks" type="GPUParticles2D" parent="."]
texture_filter = 0
emitting = false
amount = 32
process_material = ExtResource("6_sparks_mat")
texture = ExtResource("3_spark_tex")
lifetime = 0.28
one_shot = true
explosiveness = 0.95

[node name="Embers" type="GPUParticles2D" parent="."]
texture_filter = 0
emitting = false
amount = 14
process_material = ExtResource("7_embers_mat")
texture = ExtResource("4_ember_tex")
lifetime = 0.5
one_shot = true

[node name="Debris" type="GPUParticles2D" parent="."]
texture_filter = 0
emitting = false
amount = 16
process_material = ExtResource("8_debris_mat")
texture = ExtResource("5_debris_tex")
lifetime = 0.5
one_shot = true
explosiveness = 0.95

[node name="FlashLight" type="PointLight2D" parent="."]
visible = false
color = Color(1, 0.6, 0.15, 1)
energy = 1.6
texture = SubResource("GradientTexture2D_light")
"""
    with open(os.path.join(VFX_DIR, "BombasticaMineExplosionVFX.tscn"), "w", encoding="utf-8") as f:
        f.write(tscn_content)
    print("Created BombasticaMineExplosionVFX.tscn")

def create_ignition_scene():
    tscn_content = """[gd_scene load_steps=12 format=3 uid="uid://b8m2igni5678"]

[ext_resource type="Script" path="res://vfx/bombastica/BombasticaIgnitionVFX.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://c1core_sheet" path="res://vfx/bombastica/textures/explosion_core_sheet.png" id="2_core_sheet"]
[ext_resource type="Texture2D" uid="uid://c5ember" path="res://vfx/bombastica/textures/ember_texture.png" id="3_ember_tex"]
[ext_resource type="Texture2D" uid="uid://c7quantum" path="res://vfx/bombastica/textures/quantum_spark.png" id="4_quantum_tex"]
[ext_resource type="Material" uid="uid://m2embers" path="res://vfx/bombastica/materials/bombastica_embers.tres" id="5_embers_mat"]
[ext_resource type="Material" uid="uid://m6quantum" path="res://vfx/bombastica/materials/bombastica_quantum.tres" id="6_quantum_mat"]

[sub_resource type="AtlasTexture" id="AtlasTexture_i0"]
atlas = ExtResource("2_core_sheet")
region = Rect2(0, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_i1"]
atlas = ExtResource("2_core_sheet")
region = Rect2(64, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_i2"]
atlas = ExtResource("2_core_sheet")
region = Rect2(128, 0, 64, 64)

[sub_resource type="AtlasTexture" id="AtlasTexture_i3"]
atlas = ExtResource("2_core_sheet")
region = Rect2(192, 0, 64, 64)

[sub_resource type="SpriteFrames" id="SpriteFrames_igni"]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_i0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_i1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_i2")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_i3")
}],
"loop": false,
"name": &"default",
"speed": 24.0
}]

[node name="BombasticaIgnitionVFX" type="Node2D"]
script = ExtResource("1_script")

[node name="ExplosionCore" type="AnimatedSprite2D" parent="."]
texture_filter = 0
sprite_frames = SubResource("SpriteFrames_igni")

[node name="Embers" type="GPUParticles2D" parent="."]
texture_filter = 0
emitting = false
amount = 8
process_material = ExtResource("5_embers_mat")
texture = ExtResource("3_ember_tex")
lifetime = 0.4
one_shot = true

[node name="QuantumSparks" type="GPUParticles2D" parent="."]
texture_filter = 0
emitting = false
amount = 8
process_material = ExtResource("6_quantum_mat")
texture = ExtResource("4_quantum_tex")
lifetime = 0.3
one_shot = true
"""
    with open(os.path.join(VFX_DIR, "BombasticaIgnitionVFX.tscn"), "w", encoding="utf-8") as f:
        f.write(tscn_content)
    print("Created BombasticaIgnitionVFX.tscn")

if __name__ == "__main__":
    create_mine_scene()
    create_ignition_scene()

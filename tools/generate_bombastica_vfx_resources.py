import os

MAT_DIR = "vfx/bombastica/materials"
RES_DIR = "vfx/bombastica/resources"
os.makedirs(MAT_DIR, exist_ok=True)
os.makedirs(RES_DIR, exist_ok=True)

# 1. bombastica_sparks.tres
sparks_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_sparks"]
offsets = PackedFloat32Array(0, 0.2, 0.65, 1)
colors = PackedColorArray(1, 1, 1, 1, 1, 0.92, 0.35, 1, 1, 0.48, 0.1, 0.85, 1, 0.15, 0.05, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_sparks"]
gradient = SubResource("Gradient_sparks")

[sub_resource type="Curve" id="Curve_sparks"]
_data = [Vector2(0, 1.2), 0.0, 0.0, 0, 0, Vector2(1, 0.2), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_sparks"]
curve = SubResource("Curve_sparks")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, 0, 0)
spread = 180.0
initial_velocity_min = 180.0
initial_velocity_max = 340.0
gravity = Vector3(0, 0, 0)
damping_min = 220.0
damping_max = 280.0
scale_curve = SubResource("CurveTexture_sparks")
color_ramp = SubResource("GradientTexture1D_sparks")
"""
with open(os.path.join(MAT_DIR, "bombastica_sparks.tres"), "w", encoding="utf-8") as f:
    f.write(sparks_content)

# 2. bombastica_embers.tres
embers_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_embers"]
offsets = PackedFloat32Array(0, 0.25, 0.55, 0.8, 1)
colors = PackedColorArray(1, 0.95, 0.4, 1, 1, 0.55, 0.1, 1, 0.85, 0.2, 0.08, 0.9, 0.3, 0.1, 0.08, 0.6, 0, 0, 0, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_embers"]
gradient = SubResource("Gradient_embers")

[sub_resource type="Curve" id="Curve_embers"]
_data = [Vector2(0, 1.0), 0.0, 0.0, 0, 0, Vector2(0.7, 0.8), 0.0, 0.0, 0, 0, Vector2(1, 0.1), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_embers"]
curve = SubResource("Curve_embers")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, 0, 0)
spread = 180.0
initial_velocity_min = 100.0
initial_velocity_max = 220.0
gravity = Vector3(0, -45, 0)
damping_min = 120.0
damping_max = 180.0
scale_curve = SubResource("CurveTexture_embers")
color_ramp = SubResource("GradientTexture1D_embers")
"""
with open(os.path.join(MAT_DIR, "bombastica_embers.tres"), "w", encoding="utf-8") as f:
    f.write(embers_content)

# 3. bombastica_debris.tres
debris_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_debris"]
offsets = PackedFloat32Array(0, 0.75, 1)
colors = PackedColorArray(0.35, 0.36, 0.4, 1, 0.2, 0.21, 0.24, 0.9, 0.05, 0.05, 0.06, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_debris"]
gradient = SubResource("Gradient_debris")

[sub_resource type="Curve" id="Curve_debris"]
_data = [Vector2(0, 1.0), 0.0, 0.0, 0, 0, Vector2(1, 0.4), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_debris"]
curve = SubResource("Curve_debris")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, -0.5, 0)
spread = 160.0
initial_velocity_min = 140.0
initial_velocity_max = 260.0
angular_velocity_min = -360.0
angular_velocity_max = 360.0
gravity = Vector3(0, 180, 0)
damping_min = 40.0
damping_max = 80.0
scale_curve = SubResource("CurveTexture_debris")
color_ramp = SubResource("GradientTexture1D_debris")
"""
with open(os.path.join(MAT_DIR, "bombastica_debris.tres"), "w", encoding="utf-8") as f:
    f.write(debris_content)

# 4. bombastica_smoke_hot.tres
smoke_hot_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_smoke_hot"]
offsets = PackedFloat32Array(0, 0.2, 0.6, 1)
colors = PackedColorArray(0.8, 0.4, 0.1, 0.9, 0.35, 0.35, 0.38, 0.85, 0.2, 0.2, 0.22, 0.6, 0.08, 0.08, 0.09, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_smoke_hot"]
gradient = SubResource("Gradient_smoke_hot")

[sub_resource type="Curve" id="Curve_smoke_hot"]
_data = [Vector2(0, 0.5), 0.0, 0.0, 0, 0, Vector2(1, 1.8), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_smoke_hot"]
curve = SubResource("Curve_smoke_hot")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, -1, 0)
spread = 120.0
initial_velocity_min = 40.0
initial_velocity_max = 85.0
gravity = Vector3(0, -70, 0)
damping_min = 30.0
damping_max = 60.0
scale_curve = SubResource("CurveTexture_smoke_hot")
color_ramp = SubResource("GradientTexture1D_smoke_hot")
anim_speed_min = 1.0
anim_speed_max = 1.0
"""
with open(os.path.join(MAT_DIR, "bombastica_smoke_hot.tres"), "w", encoding="utf-8") as f:
    f.write(smoke_hot_content)

# 5. bombastica_smoke_cold.tres
smoke_cold_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_smoke_cold"]
offsets = PackedFloat32Array(0, 0.3, 0.7, 1)
colors = PackedColorArray(0.3, 0.32, 0.35, 0.7, 0.4, 0.42, 0.45, 0.55, 0.5, 0.52, 0.55, 0.3, 0.6, 0.62, 0.65, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_smoke_cold"]
gradient = SubResource("Gradient_smoke_cold")

[sub_resource type="Curve" id="Curve_smoke_cold"]
_data = [Vector2(0, 0.8), 0.0, 0.0, 0, 0, Vector2(1, 2.5), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_smoke_cold"]
curve = SubResource("Curve_smoke_cold")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, -1, 0)
spread = 140.0
initial_velocity_min = 15.0
initial_velocity_max = 45.0
gravity = Vector3(0, -25, 0)
damping_min = 15.0
damping_max = 35.0
scale_curve = SubResource("CurveTexture_smoke_cold")
color_ramp = SubResource("GradientTexture1D_smoke_cold")
anim_speed_min = 0.8
anim_speed_max = 1.0
"""
with open(os.path.join(MAT_DIR, "bombastica_smoke_cold.tres"), "w", encoding="utf-8") as f:
    f.write(smoke_cold_content)

# 6. bombastica_quantum.tres
quantum_content = """[gd_resource type="ParticleProcessMaterial" load_steps=5 format=3]

[sub_resource type="Gradient" id="Gradient_quantum"]
offsets = PackedFloat32Array(0, 0.3, 0.7, 1)
colors = PackedColorArray(0.8, 0.98, 1, 1, 0.18, 0.88, 1, 0.9, 0, 0.6, 0.9, 0.6, 0, 0.2, 0.5, 0)

[sub_resource type="GradientTexture1D" id="GradientTexture1D_quantum"]
gradient = SubResource("Gradient_quantum")

[sub_resource type="Curve" id="Curve_quantum"]
_data = [Vector2(0, 1.1), 0.0, 0.0, 0, 0, Vector2(1, 0.1), 0.0, 0.0, 0, 0]

[sub_resource type="CurveTexture" id="CurveTexture_quantum"]
curve = SubResource("Curve_quantum")

[resource]
particle_flag_disable_z = true
direction = Vector3(0, 0, 0)
spread = 180.0
initial_velocity_min = 140.0
initial_velocity_max = 260.0
gravity = Vector3(0, 0, 0)
damping_min = 160.0
damping_max = 220.0
scale_curve = SubResource("CurveTexture_quantum")
color_ramp = SubResource("GradientTexture1D_quantum")
"""
with open(os.path.join(MAT_DIR, "bombastica_quantum.tres"), "w", encoding="utf-8") as f:
    f.write(quantum_content)

print("Created all ParticleProcessMaterial .tres files")

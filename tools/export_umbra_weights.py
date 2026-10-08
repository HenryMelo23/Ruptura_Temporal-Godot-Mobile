import os
import json
try:
    import torch
except ImportError:
    torch = None

MODEL_VERSION = "umbra_dqn_2_0_actions_23"
ACTION_SCHEMA_VERSION = 2
FEATURE_SCHEMA_VERSION = 1
HIDDEN1_SIZE = 128
HIDDEN2_SIZE = 64

ACTION_SCHEMA = [
    "FUGIR", "INTERCEPTAR", "ORBITAR", "CERCAR", "ATAQUE", "SIFON", "TELEPORTE",
    "TELEPORTE_JUKE", "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE",
    "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA", "TRANSMUTAR_HEMORRAGIA",
    "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO", "VORTICE", "PRISAO", "MIASMA",
    "DESCARGA_ELETRICA", "PRAGA_RATOS", "LASER_SOBRECARGA",
    "CAMINHO_ESPINHOS", "NENHUMA"
]

FEATURE_SCHEMA = [
    "boss_hp_ratio", "distance_to_player", "under_fire", "player_velocity_x",
    "player_velocity_y", "boss_player_dx", "boss_player_dy", "hazard_vortex",
    "hazard_prison", "hazard_thorns", "hazard_overload_laser",
    "hazard_discharge", "hazard_miasma", "rats_active", "siphon_active",
    "dimension_map", "threat_x", "threat_y", "player_edge_x",
    "player_edge_y", "boss_edge_x", "boss_edge_y", "player_corner_pressure",
    "player_center_distance"
]


def _shape_of(value):
    shape = []
    current = value
    while isinstance(current, list):
        shape.append(len(current))
        current = current[0] if current else None
    return shape


def _require_shape(weights_json, key, expected):
    actual = _shape_of(weights_json.get(key))
    if actual != expected:
        print(f"ERROR: {key} shape mismatch. expected={expected} actual={actual}")
        return False
    return True


def export_weights():
    if torch is None:
        print("ERROR: PyTorch is required to export Umbra DQN weights.")
        return False

    model_path = os.path.join("Game Base", "Ruptura_Temporal-APOLO2.0", "saves", "memoria_umbra_dqn.pt")
    output_dir = os.path.join("assets", "weights")
    output_path = os.path.join(output_dir, MODEL_VERSION + ".json")

    print(f"Loading weights from: {model_path}")
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found at {model_path}")
        return False

    try:
        # Load state dict
        state_dict = torch.load(model_path, map_location="cpu")
    except Exception as e:
        print(f"ERROR loading state dict: {e}")
        return False

    # Extract layers. The UmbraDQN net is Sequential:
    # 0: Linear(24, 128)
    # 1: LeakyReLU()
    # 2: Linear(128, 64)
    # 3: LeakyReLU()
    # 4: Linear(64, output_size)
    #
    # Keys in state_dict usually are:
    # 'net.0.weight', 'net.0.bias', 'net.2.weight', 'net.2.bias', 'net.4.weight', 'net.4.bias'
    
    weights_json = {}
    for key, tensor in state_dict.items():
        # Convert torch tensor to nested lists
        weights_json[key] = tensor.tolist()
        print(f"Extracted {key} of shape {tensor.shape}")

    expected_shapes = {
        "net.0.weight": [HIDDEN1_SIZE, len(FEATURE_SCHEMA)],
        "net.0.bias": [HIDDEN1_SIZE],
        "net.2.weight": [HIDDEN2_SIZE, HIDDEN1_SIZE],
        "net.2.bias": [HIDDEN2_SIZE],
        "net.4.weight": [len(ACTION_SCHEMA), HIDDEN2_SIZE],
        "net.4.bias": [len(ACTION_SCHEMA)],
    }
    for key, expected in expected_shapes.items():
        if not _require_shape(weights_json, key, expected):
            return False

    weights_json["model_version"] = MODEL_VERSION
    weights_json["action_schema_version"] = ACTION_SCHEMA_VERSION
    weights_json["feature_schema_version"] = FEATURE_SCHEMA_VERSION
    weights_json["input_size"] = len(FEATURE_SCHEMA)
    weights_json["output_size"] = len(ACTION_SCHEMA)
    weights_json["feature_schema"] = FEATURE_SCHEMA
    weights_json["action_schema"] = ACTION_SCHEMA
    weights_json["acoes_base"] = ACTION_SCHEMA

    os.makedirs(output_dir, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(weights_json, f, indent=2)

    print(f"SUCCESS: Weights successfully exported to {output_path}")
    return True

if __name__ == "__main__":
    raise SystemExit(0 if export_weights() else 1)

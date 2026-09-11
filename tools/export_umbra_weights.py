import os
import json
import torch

def export_weights():
    model_path = os.path.join("Game Base", "Ruptura_Temporal-APOLO2.0", "saves", "memoria_umbra_dqn.pt")
    output_dir = os.path.join("assets", "weights")
    output_path = os.path.join(output_dir, "umbra_dqn_weights.json")

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

    # Add the base actions list in the exact order defined in memoria_predatoria_umbra / Python code:
    acoes_base = [
        "FUGIR", "INTERCEPTAR", "ORBITAR", "CERCAR", "ATAQUE", "SIFON", "TELEPORTE",
        "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", 
        "TRANSMUTAR_RESSONANCIA", "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", 
        "TRANSMUTAR_RASTRO", "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", 
        "PRAGA_RATOS", "LASER_SOBRECARGA", "CAMINHO_ESPINHOS", "NENHUMA"
    ]
    weights_json["acoes_base"] = acoes_base

    os.makedirs(output_dir, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(weights_json, f, indent=2)

    print(f"SUCCESS: Weights successfully exported to {output_path}")
    return True

if __name__ == "__main__":
    export_weights()

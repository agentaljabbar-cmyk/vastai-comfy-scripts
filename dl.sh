#!/bin/bash
set -e

# ============================================================
# Wan 2.2 ComfyUI Auto-Setup untuk Vast.ai
# ============================================================
# - Download model Wan 2.2 (UNET, CLIP, VAE, LoRA)
# - Download IPAdapter models
# - Install custom nodes (12 repo)
# - Install dependencies
# ============================================================

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN tidak dijumpai."
  echo "   Set dulu: export HF_TOKEN='hf_...'"
  exit 1
fi

echo ">>> Memasang kebergantungan asas..."
pip install -U "huggingface_hub[cli]" hf_transfer

export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_XET_HIGH_PERFORMANCE=1

# Direktori asas ComfyUI
COMFY=/workspace/ComfyUI/models
mkdir -p $COMFY/{unet,clip,vae,clip_vision,checkpoints,loras,ipadapter,controlnet,upscale_models}

# ============================================================
# 1. UNET (GGUF Wan 2.2 Fun-Control)
# ============================================================
echo ">>> [1/10] UNET HighNoise (Fun-Control Q6_K)..."
hf download QuantStack/Wan2.2-Fun-A14B-Control-GGUF \
  HighNoise/Wan2.2-Fun-A14B-Control_HighNoise-Q6_K.gguf \
  --local-dir $COMFY/unet

echo ">>> [1/10] UNET LowNoise (Fun-Control Q6_K)..."
hf download QuantStack/Wan2.2-Fun-A14B-Control-GGUF \
  LowNoise/Wan2.2-Fun-A14B-Control_LowNoise-Q6_K.gguf \
  --local-dir $COMFY/unet

# ============================================================
# 2. Text Encoder
# ============================================================
echo ">>> [2/10] Text Encoder UMT5 XXL FP8..."
hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
  split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --local-dir $COMFY/clip

# ============================================================
# 3. VAE
# ============================================================
echo ">>> [3/10] VAE Wan 2.1..."
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/vae/wan_2.1_vae.safetensors \
  --local-dir $COMFY/vae

# ============================================================
# 4. CLIP Vision
# ============================================================
echo ">>> [4/10] CLIP Vision ViT-H..."
hf download gaga2210/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
  CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
  --local-dir $COMFY/clip_vision

# ============================================================
# 5. LoRA Lightx2v (Wan 2.2 I2V A14B)
# ============================================================
echo ">>> [5/10] LoRA High Lightx2v..."
hf download Kijai/WanVideo_comfy \
  LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_4step_lora_260412_rank_64_fp16.safetensors \
  --local-dir $COMFY/loras

echo ">>> [5/10] LoRA Low Lightx2v..."
hf download Kijai/WanVideo_comfy \
  LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_LOW_lightx2v_4step_lora_260412_rank_64_fp16.safetensors \
  --local-dir $COMFY/loras

# ============================================================
# 6. IPAdapter Models (SDXL)
# ============================================================
echo ">>> [6/10] IPAdapter Plus SDXL..."
hf download h94/IP-Adapter \
  sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors \
  --local-dir $COMFY/ipadapter

echo ">>> [6/10] IPAdapter Plus Face SDXL..."
hf download h94/IP-Adapter \
  sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors \
  --local-dir $COMFY/ipadapter

echo ">>> [6/10] IPAdapter SDXL..."
hf download h94/IP-Adapter \
  sdxl_models/ip-adapter_sdxl.safetensors \
  --local-dir $COMFY/ipadapter

# ============================================================
# 7. InstantID ControlNet (Optional)
# ============================================================
echo ">>> [7/10] InstantID ControlNet..."
hf download InstantX/InstantID \
  ControlNetModel/diffusion_pytorch_model.safetensors \
  --local-dir $COMFY/controlnet

# ============================================================
# 8. Upscaler
# ============================================================
echo ">>> [8/10] Upscaler 4xNomos8kDAT..."
hf download Phips/4xNomos8kDAT \
  4xNomos8kDAT.safetensors \
  --local-dir $COMFY/upscale_models

# ============================================================
# 9. Ratakan struktur subfolder
# ============================================================
echo ">>> [9/10] Meratakan struktur folder..."
mv $COMFY/clip/split_files/text_encoders/*.safetensors $COMFY/clip/ 2>/dev/null || true
mv $COMFY/vae/split_files/vae/*.safetensors $COMFY/vae/ 2>/dev/null || true
rm -rf $COMFY/clip/split_files $COMFY/vae/split_files 2>/dev/null || true

# ============================================================
# 10. Install Custom Nodes
# ============================================================
echo ""
echo ">>> [10/10] Memasang custom nodes..."

cd /workspace/ComfyUI/custom_nodes

declare -a repos=(
  "https://github.com/ltdrdata/ComfyUI-Manager"
  "https://github.com/city96/ComfyUI-GGUF"
  "https://github.com/kijai/ComfyUI-WanVideoWrapper"
  "https://github.com/Fannovel16/comfyui_controlnet_aux"
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
  "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
  "https://github.com/WASasquatch/was-node-suite-comfyui"
  "https://github.com/cubiq/ComfyUI_essentials"
  "https://github.com/rgthree/rgthree-comfy"
  "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
  "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
)

for repo in "${repos[@]}"; do
  name=$(basename "$repo")
  if [ ! -d "$name" ]; then
    echo ">>> Install $name..."
    git clone "$repo" 2>/dev/null || echo "   ⚠️ Gagal clone $name"
  else
    echo ">>> $name sudah ada"
  fi
done

# ============================================================
# 11. Install dependencies untuk custom nodes
# ============================================================
echo ""
echo ">>> Install dependencies untuk custom nodes..."

cd /workspace/ComfyUI/custom_nodes

for dir in */; do
  if [ -f "$dir/requirements.txt" ]; then
    echo ">>> $dir requirements.txt"
    pip install -r "$dir/requirements.txt" 2>&1 | tail -3
  fi
done

# Install pyproject.toml based nodes
for dir in */; do
  if [ -f "$dir/pyproject.toml" ] && [ ! -f "$dir/requirements.txt" ]; then
    echo ">>> $dir pyproject.toml"
    pip install -e "$dir" 2>&1 | tail -3
  fi
done

# ============================================================
# 12. Setup onnxruntime-gpu untuk DWPose
# ============================================================
echo ""
echo ">>> Setup onnxruntime-gpu..."
pip uninstall -y onnxruntime onnxruntime-gpu 2>/dev/null || true
pip install onnxruntime-gpu==1.18.0 2>&1 | tail -3

# ============================================================
# 13. Senarai fail akhir
# ============================================================
echo ""
echo "✅ Setup selesai!"
echo ""
echo ">>> Senarai model:"
find $COMFY -type f \( -name "*.safetensors" -o -name "*.gguf" \) | sort
echo ""
echo ">>> Jumlah saiz model:"
du -sh $COMFY
echo ""
echo ">>> Custom nodes yang dipasang:"
ls /workspace/ComfyUI/custom_nodes/
echo ""
echo ">>> Verifikasi onnxruntime:"
python3 -c "import onnxruntime as ort; print(ort.get_available_providers())" 2>/dev/null || echo "⚠️ onnxruntime check gagal"
echo ""
echo "🎉 Instance sedia untuk digunakan!"

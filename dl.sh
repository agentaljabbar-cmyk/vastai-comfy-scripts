#!/bin/bash
set -e

# ============================================================
# Wan 2.2 ComfyUI Model Downloader untuk Vast.ai
# ============================================================
# HF_TOKEN diambil dari environment variable.
# JANGAN tulis token dalam fail ini.
# ============================================================

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN tidak dijumpai."
  echo "   Set dulu: export HF_TOKEN='hf_...'"
  exit 1
fi

echo ">>> Memasang kebergantungan..."
pip install -U "huggingface_hub[cli]" hf_transfer

export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_XET_HIGH_PERFORMANCE=1

# Direktori asas ComfyUI
COMFY=/workspace/ComfyUI/models
mkdir -p $COMFY/{unet,clip,vae,clip_vision,checkpoints,loras,ipadapter,controlnet,upscale_models}

# ---- 1. UNET (GGUF Wan 2.2 I2V) ----
echo ">>> [1/9] UNET HighNoise (Q6_K)..."
hf download QuantStack/Wan2.2-I2V-A14B-GGUF \
  HighNoise/Wan2.2-I2V-A14B-HighNoise-Q6_K.gguf \
  --local-dir $COMFY/unet

echo ">>> [1/9] UNET LowNoise (Q6_K)..."
hf download QuantStack/Wan2.2-I2V-A14B-GGUF \
  LowNoise/Wan2.2-I2V-A14B-LowNoise-Q6_K.gguf \
  --local-dir $COMFY/unet

# ---- 2. Text Encoder ----
echo ">>> [2/9] Text Encoder UMT5 XXL FP8..."
hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
  split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --local-dir $COMFY/clip

# ---- 3. VAE ----
echo ">>> [3/9] VAE Wan 2.1..."
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/vae/wan_2.1_vae.safetensors \
  --local-dir $COMFY/vae

# ---- 4. CLIP Vision ----
echo ">>> [4/9] CLIP Vision ViT-H..."
hf download gaga2210/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
  CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
  --local-dir $COMFY/clip_vision

# ---- 5. Checkpoint (EpicRealism) ----
echo ">>> [5/9] Checkpoint EpicRealism..."
hf download philz1337x/epicrealism \
  epicrealism_naturalSinRC1VAE.safetensors \
  --local-dir $COMFY/checkpoints

# ---- 6. LoRA Lightx2v (Wan 2.2 I2V A14B) ----
echo ">>> [6/9] LoRA High Lightx2v..."
hf download Kijai/WanVideo_comfy \
  LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_4step_lora_260412_rank_64_fp16.safetensors \
  --local-dir $COMFY/loras

echo ">>> [6/9] LoRA Low Lightx2v..."
hf download Kijai/WanVideo_comfy \
  LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_LOW_lightx2v_4step_lora_260412_rank_64_fp16.safetensors \
  --local-dir $COMFY/loras

# ---- 7. IP-Adapter ----
echo ">>> [7/9] IP-Adapter Full Face..."
hf download h94/IP-Adapter \
  models/ip-adapter-full-face_sd15.safetensors \
  --local-dir $COMFY/ipadapter

echo ">>> [7/9] IP-Adapter Plus Face..."
hf download h94/IP-Adapter \
  models/ip-adapter-plus-face_sd15.safetensors \
  --local-dir $COMFY/ipadapter

# ---- 8. InstantID ControlNet ----
echo ">>> [8/9] InstantID ControlNet..."
hf download InstantX/InstantID \
  ControlNetModel/diffusion_pytorch_model.safetensors \
  --local-dir $COMFY/controlnet

# ---- 9. Upscaler ----
echo ">>> [9/9] Upscaler 4xNomos8kDAT..."
hf download Phips/4xNomos8kDAT \
  4xNomos8kDAT.safetensors \
  --local-dir $COMFY/upscale_models

# ---- Ratakan struktur subfolder ----
echo ">>> Meratakan struktur folder..."
mv $COMFY/clip/split_files/text_encoders/*.safetensors $COMFY/clip/ 2>/dev/null || true
mv $COMFY/vae/split_files/vae/*.safetensors $COMFY/vae/ 2>/dev/null || true
rm -rf $COMFY/clip/split_files $COMFY/vae/split_files 2>/dev/null || true

# ---- Senarai fail akhir ----
echo ""
echo "✅ Selesai! Senarai model:"
find $COMFY -type f \( -name "*.safetensors" -o -name "*.gguf" \) | sort
echo ""
echo ">>> Jumlah saiz:"
du -sh $COMFY

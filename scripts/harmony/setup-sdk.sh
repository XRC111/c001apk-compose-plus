#!/usr/bin/env bash
# 安装 HarmonyOS Command Line Tools 6.1（公开直链，无需 secret）
# 与 PiliPlus 仓库的鸿蒙工作流共用同一套逻辑。
set -euo pipefail

SDK_PKG="${HOME}/hos-sdk.pkg"
SDK_DIR="${HOME}/hos"

if [ -f "$SDK_PKG" ]; then
  echo "::notice::SDK 压缩包命中缓存，跳过下载"
else
  read -r -a URLS <<< "${HOS_SDK_URLS:-}"
  if [ ${#URLS[@]} -eq 0 ]; then echo "::error::HOS_SDK_URLS 为空"; exit 1; fi
  for u in "${URLS[@]}"; do
    echo "尝试下载: $u"
    if curl -fL --retry 3 --retry-all-errors --connect-timeout 30 --max-time 1800 \
        -o "$SDK_PKG" "$u"; then
      echo "::notice::下载成功: $u"; break
    fi
    echo "::warning::失败，尝试下一个源"; rm -f "$SDK_PKG"
  done
  [ -f "$SDK_PKG" ] || { echo "::error::所有 SDK 源均下载失败"; exit 1; }
  ls -lh "$SDK_PKG"
fi

MAGIC=$(head -c 2 "$SDK_PKG" | od -An -tx1 | tr -d ' \n')
if [ "$MAGIC" != "504b" ] && [ "$MAGIC" != "1f8b" ]; then
  echo "::error::下载文件不是合法压缩包 (magic=$MAGIC)"; exit 1
fi

mkdir -p "$SDK_DIR"
if [ "$MAGIC" = "504b" ]; then
  unzip -q -o "$SDK_PKG" -d "$SDK_DIR"
elif [ "$MAGIC" = "1f8b" ]; then
  tar -xzf "$SDK_PKG" -C "$SDK_DIR"
else
  tar -xf "$SDK_PKG" -C "$SDK_DIR"
fi
find "$SDK_DIR" -type f \( -name hvigorw -o -name ohpm -o -name node -o -name sdkmanager \) \
  -exec chmod +x {} \; 2>/dev/null || true
echo "--- SDK 解压结构 ---"
find "$SDK_DIR" -maxdepth 3 | head -20

HOS_ROOT=$(find "$SDK_DIR" -maxdepth 2 -type d -name "command-line-tools" | head -1)
if [ -n "$HOS_ROOT" ]; then
  if [ -d "$HOS_ROOT/sdk" ]; then
    echo "DEVECO_SDK_HOME=$HOS_ROOT/sdk" >> "$GITHUB_ENV"
    echo "HOS_SDK_HOME=$HOS_ROOT/sdk" >> "$GITHUB_ENV"
  fi
  [ -d "$HOS_ROOT/bin" ] && echo "$HOS_ROOT/bin" >> "$GITHUB_PATH"
  [ -d "$HOS_ROOT/tool/node/bin" ] && echo "$HOS_ROOT/tool/node/bin" >> "$GITHUB_PATH"
  echo "::notice::已适配 command-line-tools 布局: $HOS_ROOT"
else
  SDKMANAGER=$(find "$SDK_DIR" -name sdkmanager -type f 2>/dev/null | head -1)
  if [ -n "$SDKMANAGER" ]; then
    TOOL_ROOT=$(dirname "$(dirname "$SDKMANAGER")")
    echo "DEVECO_SDK_HOME=$TOOL_ROOT" >> "$GITHUB_ENV"
    echo "HOS_SDK_HOME=$TOOL_ROOT" >> "$GITHUB_ENV"
    echo "$(dirname "$SDKMANAGER")" >> "$GITHUB_PATH"
    echo "::notice::已适配旧版 sdkmanager 布局: $TOOL_ROOT"
  else
    echo "::error::未识别 SDK 布局，请核对解压结构"; exit 1
  fi
fi

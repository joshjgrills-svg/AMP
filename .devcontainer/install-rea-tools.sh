#!/usr/bin/env bash
# Installs the optional analysis engines REA (.mcp.json) uses inside a Codespace.
# Every download is pinned and checked against its published SHA-256.
set -euo pipefail

GHIDRA_VERSION=12.1.4
GHIDRA_ZIP=ghidra_${GHIDRA_VERSION}_PUBLIC_20260921.zip
GHIDRA_SHA256=ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db
JADX_JAR=jadx-headless-mcp-0.7.1-all.jar
JADX_SHA256=6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75
WAKARU_TGZ=wakaru-linux-x64.tar.gz
WAKARU_SHA256=db0e620034723195ab426e94d00d55dbd8fd0106a928ada2563f1103196d09fa

export DEBIAN_FRONTEND=noninteractive
apt-get update
# procps: REA's process supervisor. chromium: website analysis. apktool/adb: Android.
# tshark/sigrok-cli: packet captures and logic-signal recordings. unzip: Ghidra archive.
apt-get install -y --no-install-recommends \
  procps util-linux unzip chromium apktool adb tshark sigrok-cli
rm -rf /var/lib/apt/lists/*

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ ! -d "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC" ]; then
  curl -fsSL -o "$tmp/$GHIDRA_ZIP" \
    "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/$GHIDRA_ZIP"
  echo "$GHIDRA_SHA256  $tmp/$GHIDRA_ZIP" | sha256sum -c -
  unzip -q "$tmp/$GHIDRA_ZIP" -d /opt
fi

mkdir -p /opt/rea-tools
if [ ! -f "/opt/rea-tools/$JADX_JAR" ]; then
  curl -fsSL -o "$tmp/$JADX_JAR" \
    "https://github.com/1013503897/jadx-headless-mcp/releases/download/v0.7.1/$JADX_JAR"
  echo "$JADX_SHA256  $tmp/$JADX_JAR" | sha256sum -c -
  install -m 0644 "$tmp/$JADX_JAR" "/opt/rea-tools/$JADX_JAR"
fi

if [ ! -x /opt/rea-tools/wakaru ]; then
  curl -fsSL -o "$tmp/$WAKARU_TGZ" \
    "https://github.com/pionxzh/wakaru/releases/download/v1.14.0/$WAKARU_TGZ"
  echo "$WAKARU_SHA256  $tmp/$WAKARU_TGZ" | sha256sum -c -
  tar -xzf "$tmp/$WAKARU_TGZ" -C "$tmp" wakaru
  install -m 0755 "$tmp/wakaru" /opt/rea-tools/wakaru
fi

echo "REA tools installed. Check with: npx rea-agents@6.8.0 doctor --json"

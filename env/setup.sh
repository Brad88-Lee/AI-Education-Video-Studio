#!/bin/sh
# env/setup.sh
# 在沒有 root 的 Codex Cloud 任務裡，重建 Manim 製作環境到 /workspace/tools。
# 可重複執行：已完成就直接結束（FORCE=1 可強制重建）。
# 不使用 sudo，不使用 apt install（只用 apt-get download 加 dpkg-deb -x 解壓）。
set -eu

SETUP_VERSION=1
TOOLS="${TOOLS:-/workspace/tools}"
SCRATCH="${SCRATCH:-/workspace/scratch}"
MICROMAMBA_VERSION="${MICROMAMBA_VERSION:-2.10.0}"
ENV_NAME=manim312
PY_VERSION=3.12
MANIM_VERSION=0.22.1
DVISVGM_PKGS="${DVISVGM_PKGS:-dvisvgm libwoff1}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
SNAPSHOT_URL="${SNAPSHOT_URL:-http://snapshot.debian.org/archive/debian/20261020T000000Z}"
MIN_FREE_KB=6000000
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

log() { printf '[setup %s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

START_TS=$(date +%s)

# ---- 階段 0：前置檢查 ----
[ -d /workspace ] && [ -w /workspace ] || die "/workspace 不存在或不可寫"
free_kb=$(df -Pk /workspace | awk 'NR==2{print $4}')
[ "${free_kb:-0}" -ge "$MIN_FREE_KB" ] || die "/workspace 剩餘空間不足（需要約 6 GB）：${free_kb:-0} KB"

if [ -f "$TOOLS/.setup-complete" ] && [ "${FORCE:-0}" != "1" ]; then
    if [ -x "$TOOLS/mamba/envs/$ENV_NAME/bin/manim" ] && [ -f "$TOOLS/env.sh" ]; then
        log "環境已存在（$(cat "$TOOLS/.setup-complete")），略過。需要重建請設 FORCE=1。"
        exit 0
    fi
    log "標記檔存在但內容不完整，重新建置。"
fi

mkdir -p "$TOOLS/bin" "$TOOLS/home" "$TOOLS/cache" "$TOOLS/mamba" "$TOOLS/sysroot" \
         "$SCRATCH/tmp" "$SCRATCH/out"

# 避免寫進記憶體型的 /tmp，也避免 HOME 不可寫
export HOME="$TOOLS/home"
export XDG_CACHE_HOME="$TOOLS/cache"
export MAMBA_ROOT_PREFIX="$TOOLS/mamba"
export TMPDIR="$SCRATCH/tmp"

# ---- 階段 1：micromamba ----
if [ ! -x "$TOOLS/bin/micromamba" ]; then
    log "下載 micromamba $MICROMAMBA_VERSION"
    mm_tmp=$(mktemp -d "$TMPDIR/mm.XXXXXX")
    url1="https://micro.mamba.pm/api/micromamba/linux-64/$MICROMAMBA_VERSION"
    url2="https://conda.anaconda.org/conda-forge/linux-64/micromamba-$MICROMAMBA_VERSION-0.tar.bz2"
    if ! curl -fsSL "$url1" -o "$mm_tmp/mm.tar.bz2"; then
        log "主要來源失敗，改用備用來源"
        curl -fsSL "$url2" -o "$mm_tmp/mm.tar.bz2" || die "無法下載 micromamba（兩個來源皆失敗）"
    fi
    bzip2 -dc "$mm_tmp/mm.tar.bz2" | tar -x -C "$mm_tmp" bin/micromamba || die "解開 micromamba 失敗"
    cp "$mm_tmp/bin/micromamba" "$TOOLS/bin/micromamba"
    chmod +x "$TOOLS/bin/micromamba"
    rm -rf "$mm_tmp"
fi
log "micromamba: $("$TOOLS/bin/micromamba" --version)"

# ---- 階段 2：conda 環境（只用 conda-forge）----
ENV_DIR="$TOOLS/mamba/envs/$ENV_NAME"
if [ ! -x "$ENV_DIR/bin/manim" ]; then
    if [ -d "$ENV_DIR" ]; then
        log "清除不完整的環境目錄 $ENV_DIR"
        rm -rf "$ENV_DIR"
    fi
    log "建立 conda 環境 $ENV_NAME（python=$PY_VERSION manim=$MANIM_VERSION）"
    "$TOOLS/bin/micromamba" create -y -n "$ENV_NAME" --override-channels -c conda-forge \
        "python=$PY_VERSION" "manim=$MANIM_VERSION" manimpango pycairo cairo pango ffmpeg \
        || die "micromamba create 失敗"
fi
"$ENV_DIR/bin/python" -c "import manim, manimpango, cairo; print('manim', manim.__version__)" \
    || die "import manim 失敗"
"$ENV_DIR/bin/ffmpeg" -hide_banner -encoders 2>/dev/null | grep -q libx264 || die "conda ffmpeg 沒有 libx264"

# ---- 階段 3：dvisvgm（apt-get download 加 dpkg-deb -x，不安裝）----
if [ ! -x "$TOOLS/bin/dvisvgm" ]; then
    log "取得 dvisvgm（$DVISVGM_PKGS）"
    apt_dir="$TMPDIR/apt"
    rm -rf "$apt_dir"
    mkdir -p "$apt_dir/state/lists/partial" "$apt_dir/cache/archives/partial" "$apt_dir/debs"
    codename=$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-trixie}")
    apt_opts="-o Dir::State=$apt_dir/state -o Dir::State::status=/var/lib/dpkg/status \
-o Dir::Cache=$apt_dir/cache -o Dir::Etc::sourcelist=$apt_dir/sources.list \
-o Dir::Etc::sourceparts=/dev/null -o APT::Sandbox::User=$(id -un) \
-o Acquire::Languages=none -o Debug::NoLocking=1"
    keyring=/usr/share/keyrings/debian-archive-keyring.gpg
    printf 'deb [signed-by=%s] %s %s main\n' "$keyring" "$DEBIAN_MIRROR" "$codename" > "$apt_dir/sources.list"
    # shellcheck disable=SC2086
    if ! apt-get $apt_opts update >"$apt_dir/update.log" 2>&1; then
        log "主要 Debian 來源失敗，改用 snapshot"
        printf 'deb [signed-by=%s] %s %s main\n' "$keyring" "$SNAPSHOT_URL" "$codename" > "$apt_dir/sources.list"
        # shellcheck disable=SC2086
        apt-get $apt_opts -o Acquire::Check-Valid-Until=false update >"$apt_dir/update.log" 2>&1 \
            || { tail -20 "$apt_dir/update.log"; die "apt 索引更新失敗"; }
    fi
    (
        cd "$apt_dir/debs"
        # shellcheck disable=SC2086
        apt-get $apt_opts download $DVISVGM_PKGS || exit 1
    ) || die "apt-get download 失敗"
    for deb in "$apt_dir"/debs/*.deb; do
        dpkg-deb -x "$deb" "$TOOLS/sysroot" || die "解壓 $deb 失敗"
    done
    rm -rf "$apt_dir"

    # 包裝成只對 dvisvgm 自己加 LD_LIBRARY_PATH，避免影響 conda 的程式
    cat > "$TOOLS/bin/dvisvgm" <<WRAP
#!/bin/sh
LD_LIBRARY_PATH="$TOOLS/sysroot/usr/lib/x86_64-linux-gnu\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}" exec "$TOOLS/sysroot/usr/bin/dvisvgm" "\$@"
WRAP
    chmod +x "$TOOLS/bin/dvisvgm"
fi
missing=$(LD_LIBRARY_PATH="$TOOLS/sysroot/usr/lib/x86_64-linux-gnu" ldd "$TOOLS/sysroot/usr/bin/dvisvgm" 2>&1 | grep 'not found' || true)
[ -z "$missing" ] || die "dvisvgm 缺少函式庫：$missing（可用 DVISVGM_PKGS 追加套件名稱後重跑）"
"$TOOLS/bin/dvisvgm" --version | head -1

# ---- 階段 4：產生 env.sh ----
cat > "$TOOLS/env.sh" <<ENVSH
# 由 env/setup.sh 產生（版本 $SETUP_VERSION）。用法：source $TOOLS/env.sh
export TOOLS_ROOT="$TOOLS"
export HOME="$TOOLS/home"
export XDG_CACHE_HOME="$TOOLS/cache"
export MAMBA_ROOT_PREFIX="$TOOLS/mamba"
export TMPDIR="$SCRATCH/tmp"
export PATH="$ENV_DIR/bin:$TOOLS/bin:\$PATH"
ENVSH

# ---- 階段 5：驗收 ----
if [ "${SKIP_VERIFY:-0}" != "1" ] && [ -f "$SCRIPT_DIR/verify.sh" ]; then
    log "執行驗收場景"
    sh "$SCRIPT_DIR/verify.sh" || die "驗收失敗"
fi

printf 'version=%s built=%s\n' "$SETUP_VERSION" "$(date -u +%FT%TZ)" > "$TOOLS/.setup-complete"
log "完成，總耗時 $(( $(date +%s) - START_TS )) 秒；/workspace/tools 大小：$(du -sh "$TOOLS" 2>/dev/null | cut -f1)"

# JOB-024 第 1 階段交付

僅含 480p15 預覽，未進入第 2 階段。影片為無音軌教學動畫；字幕以獨立 ASS 檔燒錄。

- 基底：`3160270ff8fda921311adfa7aa058044d2f18ebe`（main，未修改）。
- 素材：`results/job023-images` 的 `0ac06ff8dcdd7cdadb13154bfbd6c2fd74b49c20`，兩張 JPEG 均為 1280×720，直接複製，未重新壓縮。
- 交付分支：`results/job024-sample`。僅新增本 `sample/` 目錄。
- 開始製作前已 `. /workspace/tools/env.sh`；可用空間 7.5 GB。未執行 setup／verify、sudo、apt 或套件安裝。
- 工具：Manim Community 0.22.1、ffmpeg／ffprobe 9.0.2，均由上述環境提供。

## 實際主要指令

以下從 repository 根目錄執行。所有需連網的 git fetch／push 均使用 `sandbox_permissions="require_escalated"`。

```sh
. /workspace/tools/env.sh
df -h /workspace
git fetch origin main results/job023-images
git ls-remote --heads origin results/job024-sample
git switch -c results/job024-sample origin/main
git fetch origin results/job023-images
git show FETCH_HEAD:images/02_rent.jpg > sample/images/02_rent.jpg
git show FETCH_HEAD:images/03_retire.jpg > sample/images/03_retire.jpg
manim --disable_caching -r 854,480 --fps 15 \
  --media_dir /workspace/scratch/out/job024/media sample/scene.py AnnuityPV
ffmpeg -hide_banner -y \
  -i /workspace/scratch/out/job024/media/videos/scene/480p15/AnnuityPV.mp4 \
  -vf ass=sample/subtitles.ass -c:v libx264 -preset medium -crf 24 \
  -pix_fmt yuv420p -movflags +faststart -an sample/preview/preview_480p15.mp4
ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,nb_read_frames,duration:format=size,duration \
  -of json sample/preview/preview_480p15.mp4
ffprobe -v error -select_streams v:0 -show_frames \
  -show_entries frame=best_effort_timestamp_time -of json \
  sample/preview/preview_480p15.mp4
# 每一個截圖時間 T 使用此指令；PNG 均來自已燒錄字幕的 MP4。
ffmpeg -v error -y -ss "$T" -i sample/preview/preview_480p15.mp4 \
  -frames:v 1 "sample/preview/frame_$LABEL.png"
git add -- sample/
git commit -m "Add JOB-024 annuity PV 480p15 preview"
git push origin HEAD:refs/heads/results/job024-sample
```

渲染由環境 Python 的 `subprocess.run(..., timeout=1500)` 執行；用 `time.monotonic()` 前後差量測壁鐘，並保存退出碼。無快取的最終完整渲染退出碼為 0。

## 最終量測

| 項目 | 結果 |
|---|---:|
| 尺寸 | 854×480 |
| FPS | 15/1 |
| 長度 | 120.000000 秒 |
| ffprobe -count_frames | 1,800 = 120×15 |
| 第一／最後 PTS | 0.000000／119.933333 秒 |
| PTS 最小間隔 | 0.066666 秒 |
| PTS 最大間隔 | 0.066667 秒 |
| 最終完整渲染壁鐘（停用快取） | 18.928 秒 |
| 最終 MP4 | 980,765 bytes（0.981 MB） |

PTS 用全部 1,800 個解碼影格的 `best_effort_timestamp_time` 逐一相減，全部遞增；六位小數精度造成最小／最大間隔相差 1 微秒。所有交付檔案均小於 10 MB。

## 關鍵影格與自我檢查

已檢視燒錄字幕後的 18 張 854×480 PNG：00:05、00:14、00:20、00:35、00:37、00:38、00:39、00:41、00:45、00:58、01:09、01:12、01:16、01:20、01:29、01:35、01:42、01:55。包含所有指定的 9 個時間點。

| 檢查項目 | 結果 |
|---|---|
| 缺字／方框 | 無問題。關鍵影格目視未見；Fontconfig 所選 TC 字型的 charset 亦涵蓋場景與 ASS 文字。|
| 公式超出畫面 | 無問題。已檢視推導、消項與代入畫面。|
| 文字與圖片重疊 | 無問題。開場推近末端另檢查 00:14；結尾公式置於圖片下方。|
| 字幕超出左右邊界 | 無問題。12 則字幕逐則以 libass 在黑底獨立渲染，量測所有非黑像素（含描邊），左右最小邊距 316 px（37.00%），大於 43 px 的 5% 門檻。|
| 箭頭與數字對齊 | 無問題。1／2／3 期箭頭與 1,000、990.10／980.30／970.59 各共用 x 座標；折線指回第 0 期，不穿越數字。|

字幕黑底量測的 inclusive bounding box 如下；座標原點為左上角。這是獨立字幕遮罩量測，沒有把插圖或公式算進來。

| 字幕 | x_min | y_min | x_max | y_max | 左／右邊距 px |
|---|---:|---:|---:|---:|---:|
| 1 | 362 | 446 | 487 | 461 | 362／366 |
| 2 | 348 | 428 | 499 | 461 | 348／354 |
| 3 | 362 | 428 | 487 | 461 | 362／366 |
| 4 | 354 | 446 | 495 | 461 | 354／358 |
| 5 | 316 | 446 | 533 | 461 | 316／320 |
| 6 | 342 | 446 | 507 | 461 | 342／346 |
| 7 | 348 | 428 | 499 | 461 | 348／354 |
| 8 | 358 | 428 | 491 | 461 | 358／362 |
| 9 | 340 | 428 | 509 | 461 | 340／344 |
| 10 | 346 | 428 | 501 | 461 | 346／352 |
| 11 | 330 | 428 | 521 | 461 | 330／332 |
| 12 | 336 | 428 | 513 | 461 | 336／340 |

黑底字幕量測的實際濾鏡（n 是 15fps 的影格序號，各取一個字幕中間影格）：

```sh
ffmpeg -hide_banner -v warning -y -f lavfi \
  -i color=c=black:s=854x480:r=15:d=120 \
  -vf "ass=sample/subtitles.ass,select='eq(n,45)+eq(n,135)+eq(n,270)+eq(n,375)+eq(n,525)+eq(n,660)+eq(n,855)+eq(n,1035)+eq(n,1185)+eq(n,1365)+eq(n,1500)+eq(n,1680)'" \
  -fps_mode vfr /workspace/work/job024/subtitle_masks/cue_%02d.png
```

以 Pillow／NumPy 取 RGB 任一色頻大於 0 的像素 bounding box。字幕無動畫／移位，所以每則固定的遮罩邊界適用於該則整段。所有字幕均依指定手動 `\N` 換行，最多 2 行，每行最多 18 個全形字寬；第 10 則的全形等號依「ASCII 字元」規則改為 `=`，文字內容不變。

## 遇到的問題及處理

1. 同次 fetch 多個 ref 時，`FETCH_HEAD` 預設讀到 main，第一次取圖未成功；已單獨 fetch 指定素材分支再擷取，兩張 JPEG 均成功驗證尺寸。
2. 系統沒有 `/usr/bin/time`；改用環境 Python 的 `time.monotonic()`，未安裝套件。
3. Manim 靜態等待以 `int(duration / dt)` 截斷，第一次試跑在 49 秒檢查點少一格。`until()` 改成以整數影格算等待時間並加入極小的子影格保護；最終完整渲染與燒錄版均為 1,800 格。
4. 自我檢查發現初版折現曲線穿過已顯示數字，已改成位於付款與現值數字之間的折線，並重跑完整渲染、燒錄、截圖與量測。
5. `fontTools` 未安裝，因此改用既有 Fontconfig 的 `fc-match`／`fc-query --index` 檢查選定字型 charset；未安裝套件。Manim 的 `set_height` 僅出現棄用警告，沒有缺字或渲染錯誤。

## 待審閱

請審閱 480p 的字幕可讀性與動畫節奏。字幕尺寸依指定維持 PlayRes 1920×1080／42；未擅自放大。沒有阻塞疑點，等待核可後再處理第 2 階段。

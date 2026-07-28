#!/bin/bash
# u-meeting-note — Google Meet 녹화 프레임 추출기
#
# bash 스크립트인 이유: Bash 도구 셸(zsh)의 단어분리·글롭 차이를 피하기 위함.
# 한글 경로는 인자로 quoted 전달하면 안전 (내부에서 재해석하지 않음).
#
# Usage:
#   1) 녹화 길이 확인 (세션 ↔ 스크립트 매칭용):
#      extract-frames.sh probe "<영상1>" ["<영상2>" ...]
#
#   2) 프레임 추출:
#      extract-frames.sh "<영상파일>" "<출력폴더>" <crop> label=H:MM:SS [label=MM:SS ...]
#
#      crop:
#        full    크롭 없음 (레이아웃 확인용 샘플도 이걸로)
#        mobile  Meet 1920x1080 모바일 화면 공유 프리셋 (crop=440:1080:500:0)
#        W:H:X:Y 커스텀 (예: 1500:1080:0:0 — 우측 참가자 타일 제외)
#
#      label 은 ASCII 권장 (a01, b03 ...). 타임스탬프는 영상 기준(video-relative).
#      스크립트 시각 → video-relative 변환(- video_offset)은 호출 측 책임.
#
# 산출물: <출력폴더>/<label>.jpg + _contact-sheet.jpg (ImageMagick 있을 때)
set -euo pipefail

err() { echo "ERROR: $*" >&2; exit 1; }

command -v ffmpeg >/dev/null 2>&1 || err "ffmpeg 가 필요합니다 (brew install ffmpeg)"

# ── probe 서브커맨드 ─────────────────────────────────────────
if [[ "${1:-}" == "probe" ]]; then
  shift
  [[ $# -ge 1 ]] || err "probe: 영상 파일을 1개 이상 지정하세요"
  for f in "$@"; do
    [[ -f "$f" ]] || { echo "MISSING	$f"; continue; }
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null || echo "?")
    # H:MM:SS 로도 표기
    if [[ "$dur" != "?" ]]; then
      total=${dur%.*}
      printf '%d:%02d:%02d	%ss	%s\n' $((total/3600)) $(((total%3600)/60)) $((total%60)) "$total" "$f"
    else
      echo "?	?	$f"
    fi
  done
  exit 0
fi

# ── 프레임 추출 ─────────────────────────────────────────────
[[ $# -ge 4 ]] || err "usage: extract-frames.sh <video> <outdir> <full|mobile|W:H:X:Y> label=TS [...]"

VIDEO="$1"; OUTDIR="$2"; CROP="$3"; shift 3
[[ -f "$VIDEO" ]] || err "영상 파일 없음: $VIDEO"
mkdir -p "$OUTDIR"

VF_ARGS=()
case "$CROP" in
  full)   ;;
  mobile) VF_ARGS=(-vf "crop=440:1080:500:0") ;;
  *:*:*:*) VF_ARGS=(-vf "crop=${CROP}") ;;
  *) err "crop 은 full | mobile | W:H:X:Y 중 하나: $CROP" ;;
esac

FAIL=0
for spec in "$@"; do
  label="${spec%%=*}"
  ts="${spec#*=}"
  [[ "$label" != "$spec" && -n "$label" && -n "$ts" ]] || { echo "SKIP 잘못된 spec: $spec" >&2; FAIL=1; continue; }
  out="$OUTDIR/${label}.jpg"
  if ffmpeg -nostdin -hide_banner -loglevel error -y \
       -ss "$ts" -i "$VIDEO" -frames:v 1 "${VF_ARGS[@]}" -q:v 3 "$out" \
     && [[ -s "$out" ]]; then
    echo "OK	$label	$ts	$out"
  else
    rm -f "$out"
    echo "FAIL	$label	$ts	(타임스탬프가 영상 길이를 넘는지 probe 로 확인)" >&2
    FAIL=1
  fi
done

# ── contact sheet (일괄 검증용 — Read 1회로 전체 확인) ──────
shopt -s nullglob
jpgs=("$OUTDIR"/*.jpg)
# 기존 시트는 목록에서 제외
sheet_in=()
for j in "${jpgs[@]}"; do
  [[ "$(basename "$j")" == _contact-sheet* ]] || sheet_in+=("$j")
done
if [[ ${#sheet_in[@]} -gt 0 ]] && command -v montage >/dev/null 2>&1; then
  montage "${sheet_in[@]}" -tile 4x -geometry 300x+4+4 -label '%f' \
    "$OUTDIR/_contact-sheet.jpg" 2>/dev/null \
    && echo "SHEET	$OUTDIR/_contact-sheet.jpg"
elif [[ ${#sheet_in[@]} -gt 0 ]]; then
  echo "NOTE	montage(ImageMagick) 없음 — contact sheet 생략" >&2
fi

exit $FAIL

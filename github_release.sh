#!/usr/bin/env bash
set -euo pipefail

# Minimal GitHub Release Script
# Gereksinim: gh (GitHub CLI) -> gh auth login
# Bulunduğun branch'in HEAD'inden release oluşturur.
# Tag   = --version (örn: 1.2.3)
# Notes = --generate-notes (varsayılan) | --notes-file | --no-notes

VERSION=""
ASSETS=()
DRY_RUN="false"
NOTES_FILE=""
NO_NOTES="false"
TITLE=""
flags=""

usage() {
  cat <<EOF
Kullanım: $(basename "$0") -v <versiyon> [opsiyonlar]

Zorunlu:
  -v, --version <semver>       Örn: 1.2.3  (release tag adı)

Opsiyonel:
  -a, --asset <path>       Framework dosyası (tekrarlanabilir)
  -t, --title <string>     Release başlığı (yok ise version kullanılır)
  --notes-file <path>      Notları dosyadan al (--generate-notes devre dışı)
  --no-notes               Not ekleme veya oluşturma
  --dry-run                Komutları yazdır, çalıştırma

Örnekler:
  $(basename "$0") -v 1.2.3
  $(basename "$0") -v 1.2.3 --title Title --notes-file CHANGELOG.md
  $(basename "$0") -v 1.2.3 --asset build/ios/InsiderMobile.xcframework.zip
EOF
}

# Check validity of arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version) VERSION="$2"; shift 2;;
    -a|--asset) ASSETS+=("$2"); shift 2;;
    -t|--title) TITLE="$2"; shift 2;;
    --notes-file) NOTES_FILE="$2"; shift 2;;
    --no-notes) NO_NOTES="true"; shift;;
    --dry-run) DRY_RUN="true"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "⛔ Error: Bilinmeyen argüman: $1"; usage; exit 1;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "⛔ Error: --version parametresi zorunludur. Örn: -v 1.2.3"
  usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "⛔ Error: GitHub CLI (gh) bulunamadı."
  echo "ℹ️ Kurulum: https://cli.github.com ve 'gh auth login' komutunu çalıştırın."
  exit 1
fi

# Dry run method
run() {
  echo "+ $*"
  if [[ "${DRY_RUN}" == "false" ]]; then
    eval "$@"
  fi
}

# Check if there exists a release with same version
if gh release view "${VERSION}" >/dev/null 2>&1; then
  echo "⛔ Error: Bu tag için zaten bir release mevcut: ${VERSION}"
  exit 1
fi

# Assign title
if [[ -z "${TITLE}" ]]; then
  flags+="--title \"${VERSION}\""
else
  flags+="--title \"${TITLE}\""
fi

# Construct release flags
if [[ "${NO_NOTES}" == "true" ]]; then
  flags+=" --notes \"\""
elif [[ -n "${NOTES_FILE}" ]]; then
  if [[ ! -f "${NOTES_FILE}" ]]; then
    echo "⛔ Error: Not dosyası bulunamadı: ${NOTES_FILE}"
    exit 1
  fi
  flags+=" --notes-file \"${NOTES_FILE}\""
else
  flags+=" --generate-notes"
fi

# Create the release on Github
run "gh release create \"${VERSION}\" ${flags}"

# Upload Framework file
if [[ ${#ASSETS[@]} -gt 0 ]]; then
  echo "📦 Framework dosyası yükleniyor..."
  for a in "${ASSETS[@]}"; do
    if [[ -f "${a}" ]]; then
      run "gh release upload \"${VERSION}\" \"${a}\" --clobber"
    else
      echo "⚠️ Warning: Asset bulunamadı, atlanıyor: ${a}"
    fi
  done
fi

echo "✅ Sürüm oluşturuldu: ${VERSION}"

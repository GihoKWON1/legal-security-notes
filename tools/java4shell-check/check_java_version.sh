#!/usr/bin/env bash
#
# check_java_version.sh
#
# 목적: Java4Shell(CVE-2026-114938) 관련 1차 점검용 스크립트.
#   - 현재 시스템/컨테이너에서 실행 가능한 java 바이너리를 찾아 버전을 출력한다.
#   - CPU가 AVX-512를 지원하는지(취약점 악용 전제조건 중 하나) 확인한다.
#   - 어디까지나 "확인이 필요한 대상을 골라내는" 스크립트이며,
#     특정 빌드가 패치되었는지 최종 판정하지는 않는다. 최종 판정은
#     반드시 Oracle / OpenJDK / 사용 중인 벤더(Temurin, Red Hat 등)의
#     공식 보안 공지와 대조해서 내려야 한다.
#
# 이 스크립트는 공격 코드가 아니다. 네트워크로 어떤 데이터도 전송하지 않고,
# 어떤 Java 프로세스에도 입력을 주입하지 않는다. 로컬에서 버전 정보만 조회한다.

set -euo pipefail

echo "================================================================"
echo " Java4Shell (CVE-2026-114938) 1차 점검 스크립트"
echo " 실행 시각: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "================================================================"
echo

# ---------------------------------------------------------------
# 1. CPU의 AVX-512 지원 여부 확인 (악용 전제조건 중 하나)
# ---------------------------------------------------------------
echo "[1] CPU AVX-512 지원 여부"
if [ -r /proc/cpuinfo ]; then
    if grep -qim1 'avx512' /proc/cpuinfo; then
        echo "  -> AVX-512 플래그 감지됨. 해당 CPU에서 영향 받는 Java를 실행 중이라면 우선 점검 대상."
    else
        echo "  -> /proc/cpuinfo에서 AVX-512 플래그가 확인되지 않음."
        echo "     (참고용 판단이며, 가상화/클라우드 환경에서는 CPU 플래그 노출이 다를 수 있음)"
    fi
else
    echo "  -> /proc/cpuinfo를 읽을 수 없는 환경(예: macOS, 컨테이너 격리 설정). 수동 확인 필요."
    echo "     macOS: sysctl -a | grep -i avx512"
fi
echo

# ---------------------------------------------------------------
# 2. 시스템에서 실행 가능한 java 바이너리 탐색
# ---------------------------------------------------------------
echo "[2] 실행 가능한 java 바이너리 탐색"

JAVA_BINS=()

if command -v java >/dev/null 2>&1; then
    JAVA_BINS+=("$(command -v java)")
fi

if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
    JAVA_BINS+=("${JAVA_HOME}/bin/java")
fi

# 흔히 쓰이는 설치 경로도 함께 탐색 (존재하는 경우만)
for CANDIDATE in /usr/lib/jvm/*/bin/java /opt/*/bin/java "/Library/Java/JavaVirtualMachines"/*/Contents/Home/bin/java; do
    if [ -x "$CANDIDATE" ]; then
        JAVA_BINS+=("$CANDIDATE")
    fi
done

# 중복 제거
mapfile -t JAVA_BINS < <(printf '%s\n' "${JAVA_BINS[@]}" | sort -u)

if [ "${#JAVA_BINS[@]}" -eq 0 ]; then
    echo "  -> 이 환경에서 실행 가능한 java 바이너리를 찾지 못했습니다."
    echo "     이 환경에 자바가 없다는 뜻은 아닙니다 — 다른 서버/컨테이너/내장 런타임을 각각 점검하세요."
else
    for BIN in "${JAVA_BINS[@]}"; do
        echo "  --------------------------------------------------------"
        echo "  바이너리: $BIN"
        VER_OUTPUT="$("$BIN" -version 2>&1 || true)"
        echo "$VER_OUTPUT" | sed 's/^/    /'

        # 버전 문자열에서 major 버전 추출 (예: 17.0.21 -> 17 / 1.8.0_511 -> 8)
        MAJOR="$(echo "$VER_OUTPUT" | grep -oE '"[0-9]+(\.[0-9]+)*' | head -1 | tr -d '"' | cut -d. -f1)"

        case "$MAJOR" in
            17|21|25|27)
                echo "    => 공개된 영향 버전대(Java 17/21/25/27 계열)에 해당합니다."
                echo "       빌드 번호가 2026-11-17 이후 벤더 패치 빌드인지 반드시 확인하세요."
                ;;
            1|8|11)
                echo "    => 보도 기준 영향 범위(OpenJDK 17.0.6+)에 해당하지 않는 구버전일 가능성이 있습니다."
                echo "       다만 이 결과만으로 안전을 단정하지 말고 벤더 공지와 대조하세요."
                ;;
            *)
                echo "    => 버전을 자동으로 판정하지 못했습니다. 위 원문 출력을 직접 확인하세요."
                ;;
        esac
    done
fi
echo

# ---------------------------------------------------------------
# 3. 다음 확인 사항 안내
# ---------------------------------------------------------------
cat <<'EOF'
[3] 이 스크립트로 끝나지 않는 확인 사항

  1) 위에서 찾은 각 java 바이너리의 정확한 빌드 번호를, 사용 중인 벤더의
     보안 공지(Oracle Critical Patch Update, OpenJDK, Eclipse Temurin,
     Red Hat 등)에 나온 "패치된 빌드"와 직접 대조할 것.
  2) 이 서버에 직접 설치한 Java뿐 아니라, 그룹웨어·ERP·WAS 등 제3자
     소프트웨어에 내장되어 함께 배포된 Java도 별도로 확인할 것.
  3) 인터넷에 노출된 서비스(외부에서 Base64 데이터를 전달받아 디코딩하는
     엔드포인트)를 우선순위로 점검할 것 — 공격 전제조건 중 하나가
     "외부에서 조작된 데이터를 디코딩 지점까지 전달할 수 있는가"이기 때문.
  4) 패치 적용 후에는 해당 서비스를 재시작하고, 실제 운영 중인 프로세스가
     새 빌드로 바뀌었는지(재기동 전 캐시된 구버전이 남아있지 않은지)
     다시 확인할 것.
EOF

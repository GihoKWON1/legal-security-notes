# lab/java4shell — 패치 전/후 비교 환경

## 목적과 범위

이 디렉터리는 Java4Shell(CVE-2026-114938)에 대해 두 가지를 **방어적 관점에서** 비교하는 환경이다.

1. 패치 이전(취약) Eclipse Temurin JDK 17 빌드 vs 패치 이후 빌드의 버전·플래그 차이
2. 같은(패치 전) 빌드 안에서, 공식 완화 플래그(`-XX:-UseBASE64Intrinsics`, `-XX:UseAVX=2`)를 켰을 때와 껐을 때의 동작 차이

**포함하지 않은 것**: 실제로 메모리 손상을 유발하는 Base64 트리거 입력(익스플로잇 페이로드)은 어디에도 작성하지 않았다. 이 취약점은 공격 전제조건(AVX-512 VBMI 하드웨어, 조작된 입력을 전달할 통로)과 결합해야 비로소 위험해지는 종류이고, 그 트리거를 만드는 것 자체가 동작하는 익스플로잇을 작성하는 일이기 때문에 — 교육·비공개 목적이라도 — 이 저장소에서는 다루지 않는다.

대신 "패치 전/완화 플래그 끔(=취약한 가속 경로 사용) vs 패치 후/완화 플래그 켬(=안전한 경로 사용)"이라는 **실제로 바뀌는 지점**을 비교한다. `compare.sh`는 두 상태 모두에서 정상 입력에 대한 Base64 인코딩/디코딩이 올바르게 동작함을 보여준다 — 즉 "취약한 가속 경로를 꺼도 기능은 멀쩡하다"는, 완화 조치를 적용해도 되는 근거를 직접 눈으로 확인하는 실습이다.

취약점 자체의 메모리 손상 동작(크래시 재현 등)을 직접 확인하고 싶다면, 그건 이 저장소가 아니라 Oracle/OpenJDK 공식 보안 공지나 CVE 상세 페이지에서 벤더가 직접 공개한 재현 정보를 벤더 문서 안에서 다뤄야 한다.

## 구성

```
lab/java4shell/
├── docker-compose.yml
├── vulnerable/Dockerfile    # 패치 이전 빌드 (아래 '버전' 참고)
├── patched/Dockerfile       # 패치 이후 빌드
└── testapp/
    ├── Base64Test.java      # 정상 입력에 대한 Base64 인코딩/디코딩 (익스플로잇 아님)
    └── compare.sh           # 플래그 기본값 확인 + 기본/완화플래그 상태별 실행 비교
```

## 버전 (2026-11-18 기준 확인 — 빌드 전 재확인 권장)

Eclipse Temurin(Adoptium) 공식 공지와 업계 추적 보도를 교차 확인한 값이다. 자세한 출처는
[02-참고자료.md](../../docs/2026-11-java4shell-cve-2026-114938/02-참고자료.md)의
"공식 기관/벤더 1차 출처" 항목 참고.

| 이미지 | JDK_TAG | 의미 |
| --- | --- | --- |
| `vulnerable` | `17.0.21_9` | Temurin JDK 17 마지막 패치 이전 빌드(2026-10-22 공개) |
| `patched` | `17.0.21.1_2` | Temurin JDK 17 패치 빌드(Adoptium 공식 공지 기준) |

Adoptium 공지 자체가 "테스트가 끝나는 대로 바이너리를 게시 중"이라고 밝히고 있어, 작업 시점에 Docker Hub의 `eclipse-temurin` 저장소에 `17.0.21.1_2-jdk` 태그가 실제로 올라와 있는지 먼저 확인할 것(없으면 빌드가 실패한다). 태그가 없다면 Adoptium 공지 페이지나 Docker Hub에서 그 시점의 최신 패치 태그로 `docker-compose.yml`을 갱신한다.

```bash
# 태그 확인 예시
docker manifest inspect eclipse-temurin:17.0.21.1_2-jdk
```

## 실행

```bash
docker compose build
docker compose run --rm vulnerable
docker compose run --rm patched
```

각 컨테이너는 (1) `java -version`, (2) `UseBASE64Intrinsics`/`UseAVX` 플래그의 현재 기본값, (3) 플래그를 켠/끈 두 상태 각각에서 `Base64Test`를 실행한 결과를 출력한다. `vulnerable`과 `patched` 두 컨테이너의 출력을 나란히 두고, 버전 표기·플래그 기본값·완화 조치 적용 후에도 기능이 정상인지를 비교해 `docs/2026-11-java4shell-cve-2026-114938/03-결과보고서.md`에 기록한다.

# java4shell-check

Java4Shell(CVE-2026-114938) 관련 1차 점검 스크립트.

## 하는 일

- 현재 환경에서 실행 가능한 `java` 바이너리를 찾아 버전을 출력한다.
- 영향이 보도된 버전대(Java 17/21/25/27 계열)에 해당하는지 1차 분류한다.
- CPU가 AVX-512를 지원하는지(악용 전제조건 중 하나) 확인한다.

## 하지 않는 일

- 실제로 취약점을 트리거하거나 입력을 주입하지 않는다. 네트워크 통신도 하지 않는다.
- "패치됨/안 됨"을 최종 판정하지 않는다. 빌드 번호 대 벤더 공지 대조는 사람이 직접 해야 한다.

## 사용법

```bash
chmod +x check_java_version.sh
./check_java_version.sh
```

여러 서버/컨테이너를 점검해야 한다면, 이 스크립트를 각 대상에 복사해 실행하거나,
SSH로 원격 실행한 결과를 모아 `docs/.../03-결과보고서.md`에 정리한다.

```bash
# 예시: 여러 호스트에 원격으로 실행 (호스트 목록은 환경에 맞게 수정)
for HOST in host1 host2 host3; do
  echo "== $HOST =="
  ssh "$HOST" 'bash -s' < check_java_version.sh
done
```

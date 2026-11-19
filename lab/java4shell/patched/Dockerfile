# patched/Dockerfile
#
# 패치 이후 OpenJDK 빌드를 담는 이미지. JDK_TAG는 반드시 공식 벤더 공지에서
# 확인한 "패치된 빌드" 태그로 지정할 것 (README.md의 '버전 지정' 참고).
#
# 이 이미지에는 취약점을 트리거하는 코드가 없다. 표준 Base64 API만 쓰는
# testapp을 올려 패치 전/후 비교에만 사용한다.

ARG JDK_TAG=17.0.21.1_2
FROM eclipse-temurin:${JDK_TAG}-jdk

WORKDIR /app
COPY testapp/Base64Test.java /app/Base64Test.java
COPY testapp/compare.sh /app/compare.sh

RUN javac Base64Test.java && chmod +x compare.sh

CMD ["./compare.sh"]

import java.util.Base64;
import java.nio.charset.StandardCharsets;

/**
 * Base64Test
 *
 * 패치 전/후 OpenJDK 환경을 비교하기 위한 "정상 입력" 테스트 도구이다.
 * 표준 java.util.Base64 API만 사용하며, 취약점을 트리거하는 비정상
 * 입력이나 조작된 바이트 시퀀스는 포함하지 않는다. 이 코드는 익스플로잇이
 * 아니라, 두 JVM 빌드가 동일한 정상 입력에 대해 동일하게 동작하는지
 * 확인하기 위한 대조군이다.
 */
public class Base64Test {
    public static void main(String[] args) {
        System.out.println("== Base64Test ==");
        System.out.println("java.version      = " + System.getProperty("java.version"));
        System.out.println("java.vm.name       = " + System.getProperty("java.vm.name"));
        System.out.println("java.vm.version    = " + System.getProperty("java.vm.version"));
        System.out.println("os.arch            = " + System.getProperty("os.arch"));
        System.out.println();

        String sample = "Java4Shell 비교 테스트 - 정상 입력입니다.";
        byte[] original = sample.getBytes(StandardCharsets.UTF_8);

        String encoded = Base64.getEncoder().encodeToString(original);
        byte[] decoded = Base64.getDecoder().decode(encoded);
        String roundTripped = new String(decoded, StandardCharsets.UTF_8);

        System.out.println("원문            : " + sample);
        System.out.println("Base64 인코딩    : " + encoded);
        System.out.println("디코딩 후 복원   : " + roundTripped);
        System.out.println("일치 여부        : " + sample.equals(roundTripped));
    }
}

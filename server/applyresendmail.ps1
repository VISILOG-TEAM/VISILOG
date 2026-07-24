# Switch email delivery from Gmail SMTP (blocked by Render's free tier) to Resend's HTTP API.
# Run this from your VisiLog-frontend\server folder (the one with pom.xml in it) in PowerShell.
[Environment]::CurrentDirectory = (Get-Location).Path
Start-Transcript -Path resendmail-log.txt -Force

# --- pom.xml ---
[System.IO.File]::WriteAllText('pom.xml', @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.4</version>
    <relativePath/>
  </parent>

  <groupId>com.visilog</groupId>
  <artifactId>visilog-api</artifactId>
  <version>0.1.0</version>
  <name>visilog-api</name>
  <description>VisiLog backend -- single Spring Boot API serving the visipro app</description>

  <properties>
    <java.version>21</java.version>
    <jjwt.version>0.12.6</jjwt.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-core</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>

    <!-- JWT -->
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-api</artifactId>
      <version>${jjwt.version}</version>
    </dependency>
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-impl</artifactId>
      <version>${jjwt.version}</version>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>io.jsonwebtoken</groupId>
      <artifactId>jjwt-jackson</artifactId>
      <version>${jjwt.version}</version>
      <scope>runtime</scope>
    </dependency>

    <dependency>
      <groupId>org.projectlombok</groupId>
      <artifactId>lombok</artifactId>
      <optional>true</optional>
    </dependency>

    <!-- Tests -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.h2database</groupId>
      <artifactId>h2</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <configuration>
          <excludes>
            <exclude>
              <groupId>org.projectlombok</groupId>
              <artifactId>lombok</artifactId>
            </exclude>
          </excludes>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
'@)

# --- src\main\resources\application.yml ---
[System.IO.File]::WriteAllText('src\main\resources\application.yml', @'
spring:
  application:
    name: visilog-api
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/visipro}
    username: ${DB_USER:visipro}
    password: ${DB_PASSWORD:visipro}
  jpa:
    hibernate:
      # Flyway owns the schema -- Hibernate only validates it matches.
      ddl-auto: validate
    open-in-view: false
    properties:
      hibernate:
        format_sql: true
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: ${PORT:8080}

visilog:
  jwt:
    secret: ${JWT_SECRET:dev-only-secret-key-visilog-change-me-in-prod-32bytes-min}
    expiration-ms: 86400000 # 24h
  google:
    client-id: ${GOOGLE_CLIENT_ID:}
  # Welcome/password-reset/meeting-invite email, sent via Resend's HTTP
  # API (not SMTP) -- see MailService for why. Left blank (the
  # default), MailService just skips sending and logs instead of
  # failing whatever triggered it.
  resend:
    api-key: ${RESEND_API_KEY:}
    from: ${RESEND_FROM:VisiLog <onboarding@resend.dev>}

logging:
  level:
    com.visilog: INFO
'@)

# --- src\main\java\com\visilog\api\service\MailService.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\service\MailService.java', @'
package com.visilog.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

// Sends transactional email (welcome, password reset, meeting invites
// to outside guests) via Resend's HTTP API rather than raw SMTP --
// Render's free tier blocks outbound traffic to SMTP ports (25/465/587)
// entirely, which is what silently broke Gmail SMTP delivery in
// production. Resend sends over plain HTTPS, so it isn't affected by
// that restriction. Until RESEND_API_KEY is set, sending is a silent
// no-op (logged, not thrown) so nothing else ever fails just because
// mail isn't configured yet.
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);
    private static final URI RESEND_ENDPOINT = URI.create("https://api.resend.com/emails");
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${visilog.resend.api-key:}")
    private String apiKey;

    @Value("${visilog.resend.from:VisiLog <onboarding@resend.dev>}")
    private String fromAddress;

    public void sendMeetingInvite(
            String toEmail, String guestName, String organiserName, String companyName, String companyCode,
            String title, String when, String placeLabel) {
        String subject = organiserName + " invited you to \"" + title + "\" on VisiLog";
        String body =
                "Hi " + (guestName == null || guestName.isBlank() ? "there" : guestName) + ",\n\n"
                + organiserName + " has invited you to a meeting:\n\n"
                + "  " + title + "\n"
                + "  " + when + "\n"
                + (placeLabel != null && !placeLabel.isBlank() ? "  " + placeLabel + "\n" : "")
                + "\nTo see the details and check in when you arrive, download the VisiLog app and "
                + "sign up with " + companyName + "'s company code: " + companyCode + "\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "meeting invite");
    }

    public void sendPasswordResetEmail(String toEmail, String name, String code) {
        String subject = "Your VisiLog password reset code";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Here's your VisiLog password reset code:\n\n"
                + "  " + code + "\n\n"
                + "Enter this in the app to choose a new password. It expires in 15 minutes.\n\n"
                + "If you didn't ask to reset your password, you can ignore this email.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "password reset");
    }

    public void sendWelcomeEmail(String toEmail, String name, String companyName) {
        String subject = "Welcome to VisiLog";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Welcome to VisiLog! Your account with " + companyName + " is ready to go.\n\n"
                + "You can now check in visitors, book meetings, and clock in right from the app.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "welcome");
    }

    private void send(String toEmail, String subject, String textBody, String kind) {
        if (apiKey == null || apiKey.isBlank()) {
            log.info("Mail not configured -- skipping {} email to {}", kind, toEmail);
            return;
        }
        try {
            String json = objectMapper.writeValueAsString(Map.of(
                    "from", fromAddress,
                    "to", List.of(toEmail),
                    "subject", subject,
                    "text", textBody));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(RESEND_ENDPOINT)
                    .timeout(TIMEOUT)
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                log.warn("Could not send {} email to {}: Resend returned {} - {}",
                        kind, toEmail, response.statusCode(), response.body());
            }
        } catch (Exception ex) {
            log.warn("Could not send {} email to {}: {}", kind, toEmail, ex.getMessage());
        }
    }
}
'@)

Write-Host '--- Files written, verifying ---'
if (Test-Path "pom.xml") { Write-Host "OK   pom.xml" } else { Write-Host "MISSING pom.xml" -ForegroundColor Red }
if (Test-Path "src\main\resources\application.yml") { Write-Host "OK   src\main\resources\application.yml" } else { Write-Host "MISSING src\main\resources\application.yml" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\service\MailService.java") { Write-Host "OK   src\main\java\com\visilog\api\service\MailService.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\service\MailService.java" -ForegroundColor Red }

Stop-Transcript
Write-Host ''
Write-Host 'Done. Now run: .\mvnw.cmd -q test' -ForegroundColor Green
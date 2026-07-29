# VisiLog backend - send email to any address via Brevo
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
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

  # Brevo is preferred over Resend when both are configured, because
  # Brevo verifies a single SENDER ADDRESS while Resend requires a whole
  # verified DOMAIN. On Resend's shared onboarding@resend.dev sender,
  # delivery is silently restricted to the account owner's own inbox --
  # which is why mail to everyone else vanished. Brevo lets a plain
  # Gmail address send to anybody once that one address is confirmed.
  brevo:
    api-key: ${BREVO_API_KEY:}
    from: ${BREVO_FROM:${RESEND_FROM:VisiLog <onboarding@resend.dev>}}

logging:
  level:
    com.visilog: INFO

'@
$path = Join-Path (Get-Location) 'server\src\main\resources\application.yml'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/resources/application.yml'

$content = @'
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
    private static final URI BREVO_ENDPOINT = URI.create("https://api.brevo.com/v3/smtp/email");
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${visilog.resend.api-key:}")
    private String apiKey;

    @Value("${visilog.resend.from:VisiLog <onboarding@resend.dev>}")
    private String fromAddress;

    @Value("${visilog.brevo.api-key:}")
    private String brevoApiKey;

    @Value("${visilog.brevo.from:VisiLog <onboarding@resend.dev>}")
    private String brevoFrom;

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

    public void sendVerificationEmail(String toEmail, String name, String code) {
        String subject = "Your VisiLog verification code";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Here's the code to confirm your email address and finish setting up your "
                + "VisiLog account:\n\n"
                + "  " + code + "\n\n"
                + "Enter this in the app. It expires in 30 minutes -- if it runs out, tap "
                + "\"Resend code\" for a new one.\n\n"
                + "If you didn't sign up for VisiLog, you can ignore this email.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "email verification");
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

    // Brevo first when it's configured, Resend otherwise. See the
    // comment on visilog.brevo in application.yml for why: Resend needs
    // a verified domain to reach arbitrary recipients, Brevo needs only
    // a verified sender address, and VisiLog has to email visitors and
    // outside guests at whatever address they give us.
    private void send(String toEmail, String subject, String textBody, String kind) {
        if (brevoApiKey != null && !brevoApiKey.isBlank()) {
            sendViaBrevo(toEmail, subject, textBody, kind);
            return;
        }
        if (apiKey != null && !apiKey.isBlank()) {
            sendViaResend(toEmail, subject, textBody, kind);
            return;
        }
        log.info("Mail not configured -- skipping {} email to {}", kind, toEmail);
    }

    private void sendViaBrevo(String toEmail, String subject, String textBody, String kind) {
        try {
            String[] from = splitFrom(brevoFrom);
            String json = objectMapper.writeValueAsString(Map.of(
                    "sender", Map.of("name", from[0], "email", from[1]),
                    "to", List.of(Map.of("email", toEmail)),
                    "subject", subject,
                    "textContent", textBody));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(BREVO_ENDPOINT)
                    .timeout(TIMEOUT)
                    .header("api-key", brevoApiKey)
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                log.warn("Could not send {} email to {}: Brevo returned {} - {}",
                        kind, toEmail, response.statusCode(), response.body());
            } else {
                log.info("Sent {} email to {} via Brevo", kind, toEmail);
            }
        } catch (Exception ex) {
            log.warn("Could not send {} email to {}: {}", kind, toEmail, ex.getMessage());
        }
    }

    private void sendViaResend(String toEmail, String subject, String textBody, String kind) {
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
            } else {
                log.info("Sent {} email to {} via Resend", kind, toEmail);
            }
        } catch (Exception ex) {
            log.warn("Could not send {} email to {}: {}", kind, toEmail, ex.getMessage());
        }
    }

    // Accepts either "VisiLog <mail@example.com>" or a bare
    // "mail@example.com", and returns {displayName, emailAddress} --
    // Brevo wants the two as separate JSON fields, where Resend takes
    // the combined string.
    private String[] splitFrom(String raw) {
        String value = raw == null ? "" : raw.trim();
        int open = value.indexOf('<');
        int close = value.lastIndexOf('>');
        if (open >= 0 && close > open) {
            String name = value.substring(0, open).trim();
            String email = value.substring(open + 1, close).trim();
            return new String[] {name.isEmpty() ? "VisiLog" : name, email};
        }
        return new String[] {"VisiLog", value};
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\service\MailService.java'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/service/MailService.java'

Write-Host ''
Write-Host 'Done. 2 files written.'
Write-Host 'Next: run   cd server; .\mvnw -q test'

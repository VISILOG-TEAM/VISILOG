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
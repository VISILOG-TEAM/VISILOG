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

// Sends device push notifications through Expo's push API -- works for
// any Expo push token (the app registers one per device, see
// PushTokenController) without our own separate FCM/APNs credentials.
// Same "silent no-op on failure, logged not thrown" pattern as
// MailService, since a push failure should never break the request that
// triggered it (booking a meeting, etc).
//
// Requires a development/EAS build to actually be received: Expo Go on
// Android has not supported remote push since SDK 53 (see
// https://expo.dev/changelog/sdk-53) -- the send still succeeds from
// this side, there's just no Expo Go client to hand it to.
@Service
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
    private static final URI EXPO_PUSH_ENDPOINT = URI.create("https://exp.host/--/api/v2/push/send");
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Optional: only needed if Expo's push service is configured to
    // require it for this project. Blank (the default) omits the header
    // entirely rather than sending an empty bearer token.
    @Value("${visilog.expo.access-token:}")
    private String accessToken;

    public void send(List<String> tokens, String title, String body) {
        List<String> valid = tokens.stream()
                .filter(t -> t != null && t.startsWith("ExponentPushToken"))
                .toList();
        if (valid.isEmpty()) {
            return;
        }
        try {
            List<Map<String, Object>> messages = valid.stream()
                    .map(t -> Map.<String, Object>of(
                            "to", t, "title", title, "body", body, "sound", "default"))
                    .toList();
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(EXPO_PUSH_ENDPOINT)
                    .timeout(TIMEOUT)
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(messages)));
            if (accessToken != null && !accessToken.isBlank()) {
                builder.header("Authorization", "Bearer " + accessToken);
            }
            HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 300) {
                log.warn("Expo push send failed ({}): {}", response.statusCode(), response.body());
            }
        } catch (Exception ex) {
            log.warn("Expo push send failed", ex);
        }
    }
}

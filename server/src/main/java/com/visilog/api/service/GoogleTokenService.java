package com.visilog.api.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.visilog.api.exception.ApiException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

// Verifies a Google Sign-In ID token against Google's own tokeninfo
// endpoint rather than pulling in the full google-api-client SDK -- one
// small HTTP call is enough for what this app needs (the caller's
// verified email + name).
@Service
public class GoogleTokenService {

    private static final Duration TIMEOUT = Duration.ofSeconds(5);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${visilog.google.client-id:}")
    private String expectedClientId;

    public record GoogleUser(String email, String name) {
    }

    public GoogleUser verify(String idToken) {
        JsonNode payload = fetchTokenInfo(idToken);

        if (payload.has("error")) {
            throw ApiException.unauthorized("Google sign-in could not be verified.");
        }
        if (!expectedClientId.isBlank() && !expectedClientId.equals(payload.path("aud").asText())) {
            throw ApiException.unauthorized("Google sign-in was issued for a different app.");
        }
        if (!"true".equals(payload.path("email_verified").asText())) {
            throw ApiException.unauthorized("Your Google email isn't verified.");
        }
        String email = payload.path("email").asText(null);
        if (email == null || email.isBlank()) {
            throw ApiException.unauthorized("Google sign-in did not return an email address.");
        }
        String name = payload.path("name").asText(email);
        return new GoogleUser(email, name);
    }

    private JsonNode fetchTokenInfo(String idToken) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken))
                    .timeout(TIMEOUT)
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return objectMapper.readTree(response.body());
        } catch (Exception ex) {
            throw ApiException.unauthorized("Could not verify Google sign-in right now.");
        }
    }
}
package com.visilog.api.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// Google's OAuth client only accepts a real HTTPS domain as a redirect
// target -- it will not redirect straight to a mobile app's custom URI
// scheme (visilog://). This tiny landing page is that HTTPS domain:
// Google sends the sign-in result here (in the URL fragment, since the
// frontend requests an ID token via the implicit flow), and this page's
// own script immediately bounces the browser on to the app's scheme,
// carrying the result forward as query params so expo-auth-session's
// redirect listener picks it up. Same trick Expo's own (deprecated)
// auth proxy used to do.
@RestController
public class OAuthRedirectController {

    @GetMapping(value = "/oauth/google/redirect", produces = MediaType.TEXT_HTML_VALUE)
    public String redirect() {
        return "<!DOCTYPE html><html><body>"
                + "<script>"
                + "var hash = window.location.hash.substring(1);"
                + "window.location.href = 'visilog://oauth-redirect?' + hash;"
                + "</script>"
                + "</body></html>";
    }
}
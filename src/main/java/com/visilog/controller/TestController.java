package com.visilog.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/test")
public class TestController {

    @GetMapping("/protected")
    public ResponseEntity<Map<String, Object>> protectedEndpoint(
            Authentication authentication
    ) {

        Map<String, Object> data = new HashMap<>();

        data.put("message", "JWT authentication is working.");
        data.put("loggedInUser", authentication.getName());
        data.put("authorities", authentication.getAuthorities());

        return ResponseEntity.ok(data);
    }
}
package com.visilog;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * Entry point for the VisiLog backend.
 *
 * Replaces the old Login.java as the "starting point" of the app - but now
 * this just starts a REST API server on port 8080 instead of opening a
 * Swing window. Your React Native app (or Postman, for testing) talks to
 * this over HTTP.
 */
@SpringBootApplication
@EnableAsync
public class VisilogApplication {
    public static void main(String[] args) {
        SpringApplication.run(VisilogApplication.class, args);
    }
}

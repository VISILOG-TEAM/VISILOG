package com.visilog.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// @EnableScheduling backs ReminderService's fixed-rate job (30-min-before
// appointment/meeting push reminders) -- see ReminderService.
@SpringBootApplication
@EnableScheduling
public class VisilogApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(VisilogApiApplication.class, args);
    }
}

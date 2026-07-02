package com.visilog.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * Handles sending email notifications for VisiLog.
 *
 * Spring Boot's spring-boot-starter-mail auto-configures a JavaMailSender
 * bean from the spring.mail.* properties in application.properties (which
 * read EMAIL_USER / EMAIL_PASS from environment variables) - so all the
 * manual Properties/Session/Transport setup from the original EmailService
 * is gone; Spring builds that for us.
 */
@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Autowired
    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    /**
     * Sends an email synchronously (this blocks until the send completes or fails).
     *
     * @return true if the email was sent successfully, false otherwise
     */
    public boolean sendEmail(String recipient, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(recipient);
            message.setSubject(subject);
            message.setText(body);
            mailSender.send(message);
            return true;
        } catch (Exception e) {
            System.err.println("Failed to send email to " + recipient + ": " + e.getMessage());
            return false;
        }
    }

    /**
     * Sends an email on a background thread so the caller (a REST request)
     * doesn't block waiting on Gmail. @Async hands this off to a separate
     * thread pool automatically - replaces the manual `new Thread(...)`
     * from the original EmailService. Requires @EnableAsync, which is set
     * on VisilogApplication.
     */
    @Async
    public void sendEmailAsync(String recipient, String subject, String body) {
        sendEmail(recipient, subject, body);
    }
}

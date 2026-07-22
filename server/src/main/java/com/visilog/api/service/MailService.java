package com.visilog.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

// Sends the "you've been invited to a meeting" email to an outside
// guest (see RoomBookingService.book). Uses Gmail's SMTP relay with an
// account App Password (spring.mail.username/password, see
// application.yml) -- until those are set, sending is a silent no-op
// (logged, not thrown) so a booking never fails just because mail
// isn't configured yet.
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromAddress;

    public MailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendMeetingInvite(
            String toEmail, String guestName, String organiserName, String companyName, String companyCode,
            String title, String when, String placeLabel) {
        if (fromAddress == null || fromAddress.isBlank()) {
            log.info("Mail not configured -- skipping meeting invite email to {}", toEmail);
            return;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject(organiserName + " invited you to \"" + title + "\" on VisiLog");
            message.setText(
                    "Hi " + (guestName == null || guestName.isBlank() ? "there" : guestName) + ",\n\n"
                    + organiserName + " has invited you to a meeting:\n\n"
                    + "  " + title + "\n"
                    + "  " + when + "\n"
                    + (placeLabel != null && !placeLabel.isBlank() ? "  " + placeLabel + "\n" : "")
                    + "\nTo see the details and check in when you arrive, download the VisiLog app and "
                    + "sign up with " + companyName + "'s company code: " + companyCode + "\n\n"
                    + "-- VisiLog");
            mailSender.send(message);
        } catch (Exception ex) {
            log.warn("Could not send meeting invite email to {}: {}", toEmail, ex.getMessage());
        }
    }

    public void sendPasswordResetEmail(String toEmail, String name, String code) {
        if (fromAddress == null || fromAddress.isBlank()) {
            log.info("Mail not configured -- skipping password reset email to {}", toEmail);
            return;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject("Your VisiLog password reset code");
            message.setText(
                    "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                    + "Here's your VisiLog password reset code:\n\n"
                    + "  " + code + "\n\n"
                    + "Enter this in the app to choose a new password. It expires in 15 minutes.\n\n"
                    + "If you didn't ask to reset your password, you can ignore this email.\n\n"
                    + "-- VisiLog");
            mailSender.send(message);
        } catch (Exception ex) {
            log.warn("Could not send password reset email to {}: {}", toEmail, ex.getMessage());
        }
    }

    public void sendWelcomeEmail(String toEmail, String name, String companyName) {
        if (fromAddress == null || fromAddress.isBlank()) {
            log.info("Mail not configured -- skipping welcome email to {}", toEmail);
            return;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject("Welcome to VisiLog");
            message.setText(
                    "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                    + "Welcome to VisiLog! Your account with " + companyName + " is ready to go.\n\n"
                    + "You can now check in visitors, book meetings, and clock in right from the app.\n\n"
                    + "-- VisiLog");
            mailSender.send(message);
        } catch (Exception ex) {
            log.warn("Could not send welcome email to {}: {}", toEmail, ex.getMessage());
        }
    }
}
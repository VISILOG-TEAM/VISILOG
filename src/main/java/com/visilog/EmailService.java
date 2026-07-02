package com.visilog;

import java.util.Properties;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

/**
 * Handles sending email notifications for VisiLog.
 *
 * IMPORTANT: credentials are read from environment variables, never hardcoded.
 * Set GMAIL_EMAIL and GMAIL_APP_PASSWORD as environment variables on your
 * machine (or in your IDE's run configuration) before running the app.
 *
 * NOTE FOR LATER: once this app is distributed to real users, it should NOT
 * send email using your personal Gmail account on their behalf. At that
 * point, move email sending to a backend service (alongside the database
 * migration) instead of having the desktop app hold email credentials.
 */
public class EmailService {

    private static final String EMAIL = System.getenv("EMAIL_USER");
    private static final String APP_PASSWORD = System.getenv("EMAIL_PASS");

    /**
     * Sends an email synchronously (this blocks until the send completes or fails).
     * Call this from a background thread, not directly from a Swing button handler,
     * so the UI doesn't freeze.
     *
     * @return true if the email was sent successfully, false otherwise
     */
    public boolean sendEmail(String recipient, String subject, String body) {

        if (EMAIL == null || APP_PASSWORD == null) {
            System.err.println("GMAIL_EMAIL or GMAIL_APP_PASSWORD environment variable is not set. "
                    + "Email was not sent.");
            return false;
        }

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(EMAIL, APP_PASSWORD);
            }
        });

        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(EMAIL));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipient));
            message.setSubject(subject);
            message.setText(body);

            Transport.send(message);
            return true;

        } catch (MessagingException e) {
           System.err.println("Failed to send email to " + recipient + ": " + e.getMessage());
          e.printStackTrace();
            return false;
        }
    }

    /**
     * Sends an email on a background thread so the Swing UI doesn't freeze
     * while waiting on the network. Fire-and-forget; use sendEmail() directly
     * if you need to know whether it succeeded.
     */
    public void sendEmailAsync(String recipient, String subject, String body) {
        Thread emailThread = new Thread(() -> sendEmail(recipient, subject, body));
        emailThread.setDaemon(true);
        emailThread.start();
    }
}
package com.visilog;

import java.awt.GridLayout;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;

public class SignUpForm extends JFrame {

    private JTextField usernameField;
    private JPasswordField passwordField;
    private JTextField emailField;

    private final UserService userService;
    private final EmailService emailService;

    public SignUpForm(UserService userService, EmailService emailService) {
        this.userService = userService;
        this.emailService = emailService;

        setTitle("Sign Up");
        setSize(400, 200);
        setLocationRelativeTo(null);

        JPanel panel = new JPanel();
        panel.setLayout(new GridLayout(4, 2, 10, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        JLabel userLabel = new JLabel("New Username:");
        usernameField = new JTextField();

        JLabel passLabel = new JLabel("New Password:");
        passwordField = new JPasswordField();

        JLabel emailLabel = new JLabel("Email address:");
        emailField = new JTextField();

        JButton registerButton = new JButton("Register");

        panel.add(userLabel);
        panel.add(usernameField);
        panel.add(passLabel);
        panel.add(passwordField);
        panel.add(emailLabel);
        panel.add(emailField);
        panel.add(new JLabel());
        panel.add(registerButton);

        add(panel);

        registerButton.addActionListener(e -> {
            String username = usernameField.getText();
            String password = String.valueOf(passwordField.getPassword());
            String email = emailField.getText();

            if (username.isEmpty() || password.isEmpty() || email.isEmpty()) {
                JOptionPane.showMessageDialog(null, "Fill all fields");

            } else if (!isValidPassword(password)) {
                JOptionPane.showMessageDialog(null,
                        "Password must be at least 8 characters long and include numbers and special characters!");

            } else if (!isValidEmail(email)) {
                JOptionPane.showMessageDialog(null, "Please enter a valid email address!");

            } else if (userService.userExists(username)) {
                JOptionPane.showMessageDialog(null, "User already exists");

            } else {
                boolean registered = userService.register(username, password, email);

                if (registered) {
                    emailService.sendEmailAsync(
                            email,
                            "Welcome to VISILOG",
                            "Hello " + username +
                                    ",\n\nThank you for registering with VISILOG." +
                                    "\n\nYour account has been created successfully."
                    );

                    JOptionPane.showMessageDialog(null, "Account created successfully!");
                    dispose();
                } else {
                    JOptionPane.showMessageDialog(null, "Registration failed. Please try again.");
                }
            }
        });

        setVisible(true);
    }

    private boolean isValidPassword(String password) {
        if (password.length() < 8) {
            return false;
        }
        boolean hasNumber = false;
        boolean hasSpecialChar = false;
        String specialChars = "!@#$%^&*()-+";
        String numbers = "0123456789";

        for (char c : password.toCharArray()) {
            if (numbers.indexOf(c) != -1) {
                hasNumber = true;
            }
            if (specialChars.indexOf(c) != -1) {
                hasSpecialChar = true;
            }
        }

        return hasNumber && hasSpecialChar;
    }

    private boolean isValidEmail(String email) {
        // Simple check: something@something.something
        return email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    }
}
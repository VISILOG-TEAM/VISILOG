package com.visilog;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import javax.swing.border.CompoundBorder;
import javax.swing.border.LineBorder;

public class SignUpForm extends JFrame {

    private JTextField usernameField;
    private JPasswordField passwordField;
    private JPasswordField confirmPasswordField;
    private JTextField emailField;

    private boolean passVisible = false;
    private boolean confirmVisible = false;

    private JButton eyeBtn1;
    private JButton eyeBtn2;

    // Eye icons using unicode
    private static final String EYE_OPEN   = "👁";
    private static final String EYE_CLOSED = "🚫";

    private final UserService userService;
    private final EmailService emailService;

    public SignUpForm(UserService userService, EmailService emailService) {
        this.userService = userService;
        this.emailService = emailService;

        setTitle("Sign Up");
        setSize(420, 340);
        setLocationRelativeTo(null);
        setResizable(false);

        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBorder(BorderFactory.createEmptyBorder(20, 24, 20, 24));
        panel.setBackground(Color.WHITE);

        GridBagConstraints lc = new GridBagConstraints();
        lc.anchor = GridBagConstraints.WEST;
        lc.insets = new Insets(8, 0, 4, 12);
        lc.gridx = 0;

        GridBagConstraints fc = new GridBagConstraints();
        fc.fill = GridBagConstraints.HORIZONTAL;
        fc.weightx = 1.0;
        fc.insets = new Insets(8, 0, 4, 0);
        fc.gridx = 1;

        // Username
        lc.gridy = 0; fc.gridy = 0;
        panel.add(new JLabel("New Username:"), lc);
        usernameField = new JTextField();
        styleField(usernameField);
        panel.add(usernameField, fc);

        // Email
        lc.gridy = 1; fc.gridy = 1;
        panel.add(new JLabel("Email Address:"), lc);
        emailField = new JTextField();
        styleField(emailField);
        panel.add(emailField, fc);

        // New Password
        lc.gridy = 2; fc.gridy = 2;
        panel.add(new JLabel("New Password:"), lc);
        passwordField = new JPasswordField();
        eyeBtn1 = makeEyeButton();
        eyeBtn1.addActionListener(e -> {
            passVisible = !passVisible;
            passwordField.setEchoChar(passVisible ? (char) 0 : '•');
            eyeBtn1.setText(passVisible ? EYE_OPEN : EYE_CLOSED);
        });
        panel.add(makePasswordPanel(passwordField, eyeBtn1), fc);

        // Confirm Password
        lc.gridy = 3; fc.gridy = 3;
        panel.add(new JLabel("Confirm Password:"), lc);
        confirmPasswordField = new JPasswordField();
        eyeBtn2 = makeEyeButton();
        eyeBtn2.addActionListener(e -> {
            confirmVisible = !confirmVisible;
            confirmPasswordField.setEchoChar(confirmVisible ? (char) 0 : '•');
            eyeBtn2.setText(confirmVisible ? EYE_OPEN : EYE_CLOSED);
        });
        panel.add(makePasswordPanel(confirmPasswordField, eyeBtn2), fc);

        // Register Button
        GridBagConstraints bc = new GridBagConstraints();
        bc.gridx = 1; bc.gridy = 4;
        bc.fill = GridBagConstraints.HORIZONTAL;
        bc.insets = new Insets(16, 0, 0, 0);
        JButton registerButton = new JButton("Register");
        registerButton.setPreferredSize(new Dimension(0, 36));
        registerButton.setBackground(new Color(26, 35, 126));
        registerButton.setForeground(Color.WHITE);
        registerButton.setFocusPainted(false);
        registerButton.setBorderPainted(false);
        registerButton.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        panel.add(registerButton, bc);

        getContentPane().setBackground(Color.WHITE);
        add(panel);

        // Register logic
        registerButton.addActionListener(e -> {
            String username    = usernameField.getText().trim();
            String email       = emailField.getText().trim();
            String password    = String.valueOf(passwordField.getPassword());
            String confirmPass = String.valueOf(confirmPasswordField.getPassword());

            if (username.isEmpty() || email.isEmpty() || password.isEmpty() || confirmPass.isEmpty()) {
                JOptionPane.showMessageDialog(null, "Please fill in all fields.");
                return;
            }

            if (!password.equals(confirmPass)) {
                JOptionPane.showMessageDialog(null,
                        "Passwords do not match. Please try again.",
                        "Password Mismatch", JOptionPane.ERROR_MESSAGE);
                passwordField.setText("");
                confirmPasswordField.setText("");
                return;
            }

            if (!isValidPassword(password)) {
                JOptionPane.showMessageDialog(null,
                        "Password must be at least 8 characters\nand include numbers and special characters!",
                        "Weak Password", JOptionPane.WARNING_MESSAGE);
                return;
            }

            if (!isValidEmail(email)) {
                JOptionPane.showMessageDialog(null,
                        "Please enter a valid email address.",
                        "Invalid Email", JOptionPane.WARNING_MESSAGE);
                return;
            }

            if (userService.userExists(username)) {
                JOptionPane.showMessageDialog(null,
                        "Username already exists. Please choose another.",
                        "Username Taken", JOptionPane.ERROR_MESSAGE);
                return;
            }

            boolean registered = userService.register(username, password, email);

            if (registered) {
                emailService.sendEmailAsync(
                        email,
                        "Welcome to VISILOG",
                        "Hello " + username +
                                ",\n\nThank you for registering with VISILOG🎊." +
                                "\n\nYour account has been created successfully."
                );
                JOptionPane.showMessageDialog(null, "Account created successfully! Check your email.");
                dispose();
            } else {
                JOptionPane.showMessageDialog(null, "Registration failed. Please try again.");
            }
        });

        setVisible(true);
    }

    private JPanel makePasswordPanel(JPasswordField field, JButton eyeBtn) {
        JPanel p = new JPanel(new BorderLayout());
        p.setBackground(Color.WHITE);
        styleField(field);
        p.add(field, BorderLayout.CENTER);
        p.add(eyeBtn, BorderLayout.EAST);
        p.setBorder(new CompoundBorder(
                new LineBorder(new Color(180, 180, 180), 1, true),
                BorderFactory.createEmptyBorder(0, 0, 0, 0)
        ));
        field.setBorder(BorderFactory.createEmptyBorder(4, 8, 4, 4));
        return p;
    }

    private JButton makeEyeButton() {
        JButton btn = new JButton(EYE_CLOSED);
        btn.setFocusPainted(false);
        btn.setBorderPainted(false);
        btn.setContentAreaFilled(false);
        btn.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        btn.setPreferredSize(new Dimension(36, 32));
        btn.setFont(btn.getFont().deriveFont(16f));
        btn.setToolTipText("Show/hide password");
        return btn;
    }

    private void styleField(JTextField field) {
        field.setPreferredSize(new Dimension(0, 32));
        field.setBorder(new CompoundBorder(
                new LineBorder(new Color(180, 180, 180), 1, true),
                BorderFactory.createEmptyBorder(4, 8, 4, 8)
        ));
    }

    private boolean isValidPassword(String password) {
        if (password.length() < 8) return false;
        boolean hasNumber = false;
        boolean hasSpecialChar = false;
        String specialChars = "!@#$%^&*()-+";
        for (char c : password.toCharArray()) {
            if (Character.isDigit(c)) hasNumber = true;
            if (specialChars.indexOf(c) != -1) hasSpecialChar = true;
        }
        return hasNumber && hasSpecialChar;
    }

    private boolean isValidEmail(String email) {
        return email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    }
}

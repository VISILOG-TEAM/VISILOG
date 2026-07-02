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
                                             
public class Login extends JFrame {

    private JTextField usernameField;
    private JPasswordField passwordField;

    // Shared services. SignUpForm gets a reference to the SAME UserService/EmailService .,
    // instances (passed in below) so both screens are working with the same data.
    private final UserService userService;
    private final EmailService emailService;

         public Login() {
        System.out.println("EMAIL_USER = " + System.getenv("EMAIL_USER"));
        System.out.println("EMAIL_PASS = " + System.getenv("EMAIL_PASS"));
        this.userService = new UserService();
        this.emailService = new EmailService();

        // Sample account for testing
        userService.register("admin", "Admin@1234", "admin@example.com");

        setTitle("Login Page");
        setSize(400, 250);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        JPanel panel = new JPanel();
        panel.setLayout(new GridLayout(4, 2, 10, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        JLabel userLabel = new JLabel("Username:");
        usernameField = new JTextField();

        JLabel passLabel = new JLabel("Password:");
        passwordField = new JPasswordField();

        JButton loginButton = new JButton("Login");
        JButton signUpButton = new JButton("Sign Up");

        panel.add(userLabel);
        panel.add(usernameField);
        panel.add(passLabel);
        panel.add(passwordField);
        panel.add(loginButton);
        panel.add(signUpButton);

        add(panel);

        loginButton.addActionListener(e ->{
            String username = usernameField.getText();
            String password = String.valueOf(passwordField.getPassword());

            if (userService.login(username, password)) {
                JOptionPane.showMessageDialog(null, "Login Successful!");

                String email = userService.getEmail(username);
                if (email != null) {
                    // sendEmailAsync so the UI doesn't freeze while it talks to Gmail
                    emailService.sendEmailAsync(
                            email,
                            "Login Alert",
                            "You have successfully logged into VISILOG."
                    );
                }
            } else {
                JOptionPane.showMessageDialog(null, "Invalid Username or Password!");
            }
        });

        signUpButton.addActionListener(e -> new SignUpForm(userService, emailService));

        setVisible(true);
    }

    public static void main(String[] args) {
        new Login();
    }
}
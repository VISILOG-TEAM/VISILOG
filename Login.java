import java.awt.*;
import java.awt.event.*;
import java.util.HashMap;
import javax.swing.*;

public class Login extends JFrame {

    private JTextField usernameField;
    private JPasswordField passwordField;

    // Stores registered users
    public static HashMap<String, String> users = new HashMap<>();

    public Login() {
        setTitle("Login Page");
        setSize(400, 250);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        JPanel panel = new JPanel();
        panel.setLayout(new GridLayout(4, 2, 10, 10));

        JLabel userLabel = new JLabel("Username:");
        usernameField = new JTextField();

        JLabel passLabel = new JLabel("Password:");
        passwordField = new JPasswordField();

        JButton loginButton = new JButton("Login");
        JButton signUpButton = new JButton("Sign Up");

        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        panel.add(userLabel);
        panel.add(usernameField);

        panel.add(passLabel);
        panel.add(passwordField);

        panel.add(loginButton);
        panel.add(signUpButton);

        add(panel);

        // Login Button Action
        loginButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                String username = usernameField.getText();
                String password = String.valueOf(passwordField.getPassword());

                if (users.containsKey(username) &&
                    users.get(username).equals(password)) {

                    JOptionPane.showMessageDialog(null,
                            "Login Successful!");

                } else {
                    JOptionPane.showMessageDialog(null,
                            "Invalid Username or Password!");
                }
            }
        });

        // Sign Up Button Action
        signUpButton.addActionListener(e -> {
          new SignUpForm();   // opens signup window
});

        setVisible(true);
    }

    public static void main(String[] args) {
        // Sample account for testing
        users.put("admin ", "admin @1234");

        new Login();
    }
}
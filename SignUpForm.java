import java.awt.*;
import javax.swing.*;


public class SignUpForm extends JFrame {

    private JTextField usernameField;
    private JPasswordField passwordField;

    public SignUpForm() {

        setTitle("Sign Up");
        setSize(400, 200);
        setLocationRelativeTo(null);

        JPanel panel = new JPanel();
        panel.setLayout(new GridLayout(3, 2, 10, 10));

        JLabel userLabel = new JLabel("New Username:");
        usernameField = new JTextField();

        JLabel passLabel = new JLabel("New Password:");
        passwordField = new JPasswordField();

        JButton registerButton = new JButton("Register");

        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        panel.add(userLabel);
        panel.add(usernameField);

        panel.add(passLabel);
        panel.add(passwordField);

        panel.add(new JLabel());
        panel.add(registerButton);

        add(panel);

       registerButton.addActionListener(e -> {

    String username = usernameField.getText();
    String password = String.valueOf(passwordField.getPassword());


    if (username.isEmpty() || password.isEmpty()) {

        JOptionPane.showMessageDialog(null, "Fill all fields");

    } else if(!isValidPassword(password)) {

            JOptionPane.showMessageDialog(null,
                "Password must be at least 8 characters long and include numbers and special characters!");
    
            }else if(Login.users.containsKey(username)) {

        JOptionPane.showMessageDialog(null, "User already exists");

    } else {

        // SAVE USER INTO LOGIN FORM DATABASE
        Login.users.put(username, password);

        JOptionPane.showMessageDialog(null, "Account created successfully!");

        dispose(); // close signup window
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
}
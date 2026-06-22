package com.visilog;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;


public class UserService {
    // username -> hashed password
    private final Map<String, String> users = new HashMap<>();
    // username -> email
    private final Map<String, String> emails = new HashMap<>();
 
    /**
     * Registers a new user.
     *
     * @return true if registration succeeded, false if the username already exists
     */
    public boolean register(String username, String password, String email) {
        if (userExists(username)) {
            return false;
        }
        String hashed = hashPassword(password);
        users.put(username, hashed);
        emails.put(username, email);
        return true;
    }
 
    /**
     * Attempts to log a user in.
     *
     * @return true if the username exists and the password matches
     */
    public boolean login(String username, String password) {
        if (!userExists(username)) {
            return false;
        }
        String hashed = hashPassword(password);
        return users.get(username).equals(hashed);
    }
 
    public boolean userExists(String username) {
        return users.containsKey(username);
    }
 
    public String getEmail(String username) {
        return emails.get(username);
    }
 
    /**
     * Hashes a password using SHA-256.
     * Note: for production use, a salted hash (e.g. BCrypt) is stronger than
     * plain SHA-256, but SHA-256 is a solid improvement over plain text for now.
     */
    private String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(password.getBytes("UTF-8"));
 
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
 
        } catch (NoSuchAlgorithmException | java.io.UnsupportedEncodingException e) {
            // SHA-256 and UTF-8 are both guaranteed to exist on any standard JVM,
            // so this should never actually happen.
            throw new RuntimeException("Failed to hash password", e);
        }
    }
}


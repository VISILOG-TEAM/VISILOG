package com.visilog.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * Request body for POST /api/auth/signup.
 *
 * Validation here replaces the manual isValidPassword()/isValidEmail()
 * checks from the old SignUpForm.java. Confirm-password matching and
 * show/hide-password toggling are UI concerns now, so they live in the
 * React Native app, not here - the API only needs to know the final
 * password once the user has confirmed it client-side.
 */
public class SignUpRequest {

    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Please provide a valid email address")
    private String email;

    @NotBlank(message = "Password is required")
    @Pattern(
            regexp = "^(?=.*[0-9])(?=.*[!@#$%^&*()\\-+]).{8,}$",
            message = "Password must be at least 8 characters and include a number and a special character"
    )
    private String password;

    public SignUpRequest() {
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}

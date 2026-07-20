package com.visilog.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.visilog.enums.Role;
import com.visilog.enums.StaffRole;
import com.visilog.model.UserAccount;
import com.visilog.repository.UserAccountRepository;

@Service
public class UserService {

    private final UserAccountRepository userAccountRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(
        UserAccountRepository userAccountRepository,
        PasswordEncoder passwordEncoder
    ) {
    this.userAccountRepository = userAccountRepository;
    this.passwordEncoder = passwordEncoder;
       }

    public UserAccount register(
            String companyCode,
            String fullName,
            String email,
            String password,
            String confirmPassword,
            String role,
            String staffRole
    ) {

        if (companyCode == null || companyCode.isBlank()) {
            throw new IllegalArgumentException(
                    "Company code is required."
            );
        }

        if (fullName == null || fullName.isBlank()) {
            throw new IllegalArgumentException(
                    "Full name is required."
            );
        }

        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException(
                    "Email is required."
            );
        }

        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException(
                    "Password is required."
            );
        }

        if (confirmPassword == null || confirmPassword.isBlank()) {
            throw new IllegalArgumentException(
                    "Confirm password is required."
            );
        }

        if (!password.equals(confirmPassword)) {
            throw new IllegalArgumentException(
                    "Password and confirm password do not match."
            );
        }

        String normalizedEmail = email.trim().toLowerCase();

        if (userAccountRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException(
                    "Email is already registered."
            );
        }

        Role selectedRole;

        try {
            selectedRole = Role.valueOf(
                    role.trim().toUpperCase()
            );
        } catch (Exception exception) {
            throw new IllegalArgumentException(
                    "Invalid role. Role must be EMPLOYEE or VISITOR."
            );
        }

        StaffRole selectedStaffRole = null;

        if (selectedRole == Role.EMPLOYEE) {

            if (staffRole == null || staffRole.isBlank()) {
                throw new IllegalArgumentException(
                        "Staff role is required for employees."
                );
            }

            try {
                selectedStaffRole = StaffRole.valueOf(
                        staffRole.trim().toUpperCase()
                );
            } catch (IllegalArgumentException exception) {
                throw new IllegalArgumentException(
                        "Invalid staff role. Staff role must be STAFF or RECEPTIONIST."
                );
            }

        } else if (selectedRole == Role.VISITOR) {
            selectedStaffRole = null;
        }

        UserAccount userAccount = new UserAccount();

        userAccount.setCompanyCode(
                companyCode.trim().toUpperCase()
        );

        userAccount.setFullName(
                fullName.trim()
        );

        userAccount.setEmail(
                normalizedEmail
        );

        userAccount.setPassword(
                passwordEncoder.encode(password)
        );

        userAccount.setRole(
                selectedRole
        );

        userAccount.setStaffRole(
                selectedStaffRole
        );

        userAccount.setActive(true);

        return userAccountRepository.save(userAccount);
    }

    public UserAccount login(
            String email,
            String password
    ) {

        String normalizedEmail = email.trim().toLowerCase();

        UserAccount userAccount = userAccountRepository
                .findByEmail(normalizedEmail)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Invalid email or password."
                        )
                );

        if (!passwordEncoder.matches(
                password,
                userAccount.getPassword()
        )) {
            throw new IllegalArgumentException(
                    "Invalid email or password."
            );
        }

        if (!userAccount.isActive()) {
            throw new IllegalArgumentException(
                    "This account is inactive."
            );
        }

        return userAccount;
    }

    public boolean emailExists(String email) {
        return userAccountRepository.existsByEmail(
                email.trim().toLowerCase()
        );
    }

    public String determineDashboard(
            UserAccount userAccount
    ) {

        if (userAccount.getRole() == Role.VISITOR) {
            return "VISITOR_DASHBOARD";
        }

        if (userAccount.getRole() == Role.EMPLOYEE
                && userAccount.getStaffRole()
                == StaffRole.RECEPTIONIST) {

            return "RECEPTIONIST_DASHBOARD";
        }

        if (userAccount.getRole() == Role.EMPLOYEE
                && userAccount.getStaffRole()
                == StaffRole.STAFF) {

            return "EMPLOYEE_DASHBOARD";
        }

        return "UNKNOWN_DASHBOARD";
    }
}
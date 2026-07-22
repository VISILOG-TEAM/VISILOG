package com.visilog.api.entity;

// A user's fixed role, resolved once at signup (see AuthService) by
// matching their email against the org's Employee roster — never
// chosen freely by the user.
public enum Role {
    VISITOR, RECEPTIONIST, EMPLOYEE, MANAGER
}

package com.visilog.api;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jayway.jsonpath.JsonPath;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

// Drives the real end-to-end story this whole rebuild exists for:
// a company signs itself up, the admin adds staff with roles, and a
// person's role is decided automatically by matching their email at
// signup -- no free role-picker anywhere in the flow.
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OnboardingFlowIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private com.visilog.api.repository.AppUserRepository appUserRepository;

    @Test
    void selfServeCompanySignupThenStaffAndVisitorSignupResolveRolesAutomatically() throws Exception {
        // 1. Company signs itself up -- one call gets an org + admin account + company code.
        var registerBody = Map.of(
                "companyName", "Acme Logistics",
                "adminName", "Ama Owusu",
                "adminEmail", "ama@acmelogistics.com",
                "adminPassword", "adminpass123"
        );
        String registerResponse = mockMvc.perform(post("/api/v1/companies/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("MANAGER")))
                .andReturn().getResponse().getContentAsString();

        String adminToken = JsonPath.read(registerResponse, "$.token");
        String companyCode = JsonPath.read(registerResponse, "$.organization.code");
        String orgId = JsonPath.read(registerResponse, "$.user.organizationId");

        // 1b. A brand-new account's email isn't verified yet, and the token
        //     it was handed refuses everything but the verify step.
        mockMvc.perform(get("/api/v1/employees").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isForbidden());

        // 1c. A wrong code is rejected...
        mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", "000000"))))
                .andExpect(status().isBadRequest());

        // ...and the real one (read straight from the row, standing in for
        // the email the admin would actually receive) unlocks the account
        // and hands back a replacement token that is no longer restricted.
        String verifyResponse = mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", verificationCodeFor(orgId, "ama@acmelogistics.com")))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.emailVerified", is(true)))
                .andReturn().getResponse().getContentAsString();
        adminToken = JsonPath.read(verifyResponse, "$.token");

        // 2. The admin adds a receptionist to the roster in Company Setup.
        var employeeBody = Map.of(
                "employeeCode", companyCode + "-2001",
                "name", "Wendy Abagna",
                "department", "Reception",
                "email", "wendy@acmelogistics.com",
                "role", "RECEPTIONIST"
        );
        mockMvc.perform(post("/api/v1/employees")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(employeeBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role", is("RECEPTIONIST")));

        // 3. Wendy signs up with the company code + her real email -- gets
        //    RECEPTIONIST automatically, no role-picker.
        var wendySignup = Map.of(
                "companyCode", companyCode,
                "email", "wendy@acmelogistics.com",
                "password", "wendyspass123",
                "name", "Wendy Abagna"
        );
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wendySignup)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("RECEPTIONIST")))
                .andExpect(jsonPath("$.user.employeeId").exists());

        // 4. A stranger signs up with the same company code but an email
        //    that isn't on the roster -- becomes a visitor automatically.
        var strangerSignup = Map.of(
                "companyCode", companyCode,
                "email", "visitor1@example.com",
                "password", "visitorpass123",
                "name", "Selasi Akoto"
        );
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(strangerSignup)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("VISITOR")))
                .andExpect(jsonPath("$.user.employeeId").doesNotExist());

        // 5. Wendy logs back in later -- her role is already fixed.
        var wendyLogin = Map.of("companyCode", companyCode, "email", "wendy@acmelogistics.com", "password", "wendyspass123");
        String loginResponse = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wendyLogin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("RECEPTIONIST")))
                .andReturn().getResponse().getContentAsString();
        String wendyToken = JsonPath.read(loginResponse, "$.token");

        // 5b. Wendy confirms her email too, so step 7 below is genuinely
        //     testing the manager-only role check rather than just
        //     tripping over the unverified gate.
        String wendyVerify = mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + wendyToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", verificationCodeFor(orgId, "wendy@acmelogistics.com")))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        wendyToken = JsonPath.read(wendyVerify, "$.token");

        // 6. /auth/me reflects the same fixed role.
        mockMvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + wendyToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role", is("RECEPTIONIST")));

        // 7. A non-manager cannot manage the staff roster.
        mockMvc.perform(post("/api/v1/employees")
                        .header("Authorization", "Bearer " + wendyToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "employeeCode", "X-1", "name", "X", "email", "x@acmelogistics.com", "role", "EMPLOYEE"))))
                .andExpect(status().isForbidden());

        // 8. An unknown company code is rejected on login.
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "companyCode", "NOPE0000", "email", "wendy@acmelogistics.com", "password", "wendyspass123"))))
                .andExpect(status().isBadRequest());

        // 9. A request with no token at all is rejected.
        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized());
    }

    // Stands in for reading the verification email: no mail actually goes
    // out in tests (MailService no-ops without an API key), so the code is
    // read from the row it was stored on.
    private String verificationCodeFor(String orgId, String email) {
        return appUserRepository
                .findByOrganizationIdAndEmailIgnoreCase(java.util.UUID.fromString(orgId), email)
                .orElseThrow()
                .getVerificationCode();
    }
}

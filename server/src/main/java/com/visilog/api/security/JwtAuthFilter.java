package com.visilog.api.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// Reads "Authorization: Bearer <token>", validates it, and populates
// the SecurityContext with an AuthPrincipal + a single ROLE_<role>
// authority so @PreAuthorize("hasRole('MANAGER')") works on admin-only
// endpoints. Requests with no/invalid token simply proceed
// unauthenticated -- SecurityConfig decides what that's allowed to reach.
public class JwtAuthFilter extends OncePerRequestFilter {

    // The only endpoints an account with an unverified email may reach.
    // Everything else is refused here rather than in each controller, so
    // a new endpoint is gated by default instead of by remembering to
    // gate it: /auth/me and GET /org are what the app needs to render
    // the verify screen at all, and the other two are the verify step
    // itself. (POST/PATCH /org -- Company Setup branding -- is NOT in
    // this set; only the GET is allowed through, see below.)
    private static final Set<String> UNVERIFIED_ALLOWED_PATHS = Set.of(
            "/api/v1/auth/me",
            "/api/v1/auth/verify-email",
            "/api/v1/auth/resend-verification");

    private static final String ORG_PATH = "/api/v1/org";

    private final JwtService jwtService;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                var claims = jwtService.parse(header.substring(7));
                String employeeIdClaim = claims.get("employeeId", String.class);
                var principal = new AuthPrincipal(
                        UUID.fromString(claims.getSubject()),
                        UUID.fromString(claims.get("org", String.class)),
                        claims.get("role", String.class),
                        claims.get("email", String.class),
                        employeeIdClaim == null ? null : UUID.fromString(employeeIdClaim));
                var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + principal.role()));
                var authentication = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);

                if (!isEmailVerified(claims) && !isAllowedWhileUnverified(request)) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json");
                    response.getWriter().write(
                            "{\"error\":\"EMAIL_NOT_VERIFIED\","
                            + "\"message\":\"Verify your email address to finish setting up your account.\"}");
                    return;
                }
            } catch (JwtException | IllegalArgumentException ex) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }

    // Tokens issued before email verification existed carry no `verified`
    // claim at all. Those are treated as verified -- the accounts behind
    // them were backfilled as verified too (see migration V22), so this
    // matches, and it means nobody signed in right now gets kicked into
    // a verify screen for an email they were never asked to confirm.
    private boolean isEmailVerified(io.jsonwebtoken.Claims claims) {
        Boolean verified = claims.get("verified", Boolean.class);
        return verified == null || verified;
    }

    private boolean isAllowedWhileUnverified(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (UNVERIFIED_ALLOWED_PATHS.contains(path)) {
            return true;
        }
        // Reading the org is needed to theme the verify screen with the
        // company's own colors and to show a manager their company code;
        // changing it is not.
        return ORG_PATH.equals(path) && "GET".equalsIgnoreCase(request.getMethod());
    }
}

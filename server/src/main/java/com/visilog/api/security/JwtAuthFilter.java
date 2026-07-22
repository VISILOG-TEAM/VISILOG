package com.visilog.api.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// Reads "Authorization: Bearer <token>", validates it, and populates
// the SecurityContext with an AuthPrincipal + a single ROLE_<role>
// authority so @PreAuthorize("hasRole('MANAGER')") works on admin-only
// endpoints. Requests with no/invalid token simply proceed
// unauthenticated — SecurityConfig decides what that's allowed to reach.
public class JwtAuthFilter extends OncePerRequestFilter {

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
            } catch (JwtException | IllegalArgumentException ex) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}

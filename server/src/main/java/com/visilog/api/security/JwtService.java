package com.visilog.api.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

// HS256 JWT issuing/parsing. Claims: sub=userId, org=organizationId,
// role, email, employeeId (null for visitors), verified (email
// verification state). Kept deliberately simple (one shared secret,
// one service) -- no need for the old multi-service
// internal-API-key dance now that this is a monolith.
//
// `verified` lives in the token rather than being re-read from the
// database on every request: it's signed, so a client can't flip it,
// and it costs nothing per request. The trade-off is that it only
// changes when a new token is issued -- which is exactly what
// AuthService.verifyEmail() does on success.
@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(
            @Value("${visilog.jwt.secret}") String secret,
            @Value("${visilog.jwt.expiration-ms}") long expirationMs) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes());
        this.expirationMs = expirationMs;
    }

    public String issueToken(
            UUID userId, UUID organizationId, String role, String email, UUID employeeId, boolean emailVerified) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);
        var builder = Jwts.builder()
                .subject(userId.toString())
                .claim("org", organizationId.toString())
                .claim("role", role)
                .claim("email", email)
                .claim("verified", emailVerified)
                .issuedAt(now)
                .expiration(expiry);
        if (employeeId != null) {
            builder.claim("employeeId", employeeId.toString());
        }
        return builder.signWith(signingKey).compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}

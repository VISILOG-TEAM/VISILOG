package com.visilog.service;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.visilog.model.UserAccount;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

    private final SecretKey secretKey;
    private final long expiration;

    public JwtService(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration}") long expiration
    ) {
        this.secretKey = Keys.hmacShaKeyFor(
                secret.getBytes(StandardCharsets.UTF_8)
        );
        this.expiration = expiration;
    }

    public String generateToken(UserAccount userAccount) {

        Map<String, Object> claims = new HashMap<>();

        claims.put("userId", userAccount.getUserId());
        claims.put("fullName", userAccount.getFullName());
        claims.put("role", userAccount.getRole().name());

        if (userAccount.getStaffRole() != null) {
            claims.put(
                    "staffRole",
                    userAccount.getStaffRole().name()
            );
        }

        Date issuedAt = new Date();

        Date expiresAt = new Date(
                issuedAt.getTime() + expiration
        );

        return Jwts.builder()
                .claims(claims)
                .subject(userAccount.getEmail())
                .issuedAt(issuedAt)
                .expiration(expiresAt)
                .signWith(secretKey)
                .compact();
    }

    public Claims extractClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String extractEmail(String token) {
        return extractClaims(token).getSubject();
    }

    public String extractRole(String token) {
        return extractClaims(token).get(
                "role",
                String.class
        );
    }

    public String extractStaffRole(String token) {
        return extractClaims(token).get(
                "staffRole",
                String.class
        );
    }

    public boolean isTokenValid(String token) {
        try {
            Claims claims = extractClaims(token);

            return claims.getSubject() != null
                    && claims.getExpiration() != null
                    && claims.getExpiration().after(new Date());

        } catch (JwtException | IllegalArgumentException exception) {
            return false;
        }
    }
}
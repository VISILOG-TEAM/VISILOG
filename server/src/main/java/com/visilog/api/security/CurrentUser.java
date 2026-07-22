package com.visilog.api.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

// Inject the authenticated caller into a controller method:
//   @GetMapping("/me") getMe(@CurrentUser AuthPrincipal me) { ... }
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface CurrentUser {
}

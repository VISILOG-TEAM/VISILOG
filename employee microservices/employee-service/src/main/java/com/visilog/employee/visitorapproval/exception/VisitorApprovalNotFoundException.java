package com.visilog.employee.visitorapproval.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class VisitorApprovalNotFoundException extends RuntimeException {

    public VisitorApprovalNotFoundException(Long approvalId) {
        super("Visitor approval not found with ID: " + approvalId);
    }
}
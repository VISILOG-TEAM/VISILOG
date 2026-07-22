package com.visilog.api.dto;

import java.util.List;

public record BulkEmployeeRequest(List<EmployeeRequest> employees) {
}

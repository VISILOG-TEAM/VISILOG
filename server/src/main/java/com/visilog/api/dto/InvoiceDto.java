package com.visilog.api.dto;

import com.visilog.api.entity.Invoice;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record InvoiceDto(UUID id, Instant date, BigDecimal amount, String status) {
    public static InvoiceDto from(Invoice i) {
        return new InvoiceDto(i.getId(), i.getDate(), i.getAmount(), i.getStatus().name());
    }
}

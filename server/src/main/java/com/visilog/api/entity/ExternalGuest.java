package com.visilog.api.entity;

import jakarta.persistence.Embeddable;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Someone outside the staff roster invited to a meeting (a client, a
// candidate, a vendor) -- email/phone captured so they can actually be
// reached with an invite, not just named. See RoomBooking.externalGuests.
@Embeddable
@Getter
@Setter
@NoArgsConstructor
public class ExternalGuest {
    private String name;
    private String email;
    private String phone;
}

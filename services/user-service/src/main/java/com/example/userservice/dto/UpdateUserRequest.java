package com.example.userservice.dto;

import jakarta.validation.constraints.Email;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateUserRequest {
    private String firstName;
    private String lastName;

    @Email(message = "Email must be valid")
    private String email;

    private String phoneNumber;
}

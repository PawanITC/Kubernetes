package com.example.orderservice.exception;

import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ErrorResponse {
    private String message;
    private String error;
    private int status;
    private LocalDateTime timestamp;
    private String path;
}

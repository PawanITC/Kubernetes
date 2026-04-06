package com.example.orderservice.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI().info(new Info()
                .title("Order Service API")
                .description("REST API for managing orders. Calls user-service to validate users.")
                .version("1.0.0")
                .contact(new Contact().name("Platform Team").email("platform@example.com")));
    }
}

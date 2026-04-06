package com.example.orderservice.client;

import com.example.orderservice.dto.UserDto;
import com.example.orderservice.exception.UserServiceException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.util.Optional;

@Component
@Slf4j
public class UserServiceClient {

    private final WebClient webClient;

    public UserServiceClient(WebClient.Builder webClientBuilder,
                              @Value("${services.user-service.url:http://user-service}") String userServiceUrl) {
        this.webClient = webClientBuilder
                .baseUrl(userServiceUrl)
                .build();
    }

    public Optional<UserDto> getUser(Long userId) {
        try {
            return webClient.get()
                    .uri("/api/v1/users/{id}", userId)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, response ->
                            Mono.error(new UserServiceException("User not found with id: " + userId)))
                    .onStatus(HttpStatusCode::is5xxServerError, response ->
                            Mono.error(new UserServiceException("User service is unavailable")))
                    .bodyToMono(UserDto.class)
                    .timeout(Duration.ofSeconds(5))
                    .retryWhen(Retry.backoff(3, Duration.ofMillis(500))
                            .filter(throwable -> !(throwable instanceof UserServiceException)))
                    .blockOptional();
        } catch (UserServiceException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to call user-service for userId={}", userId, e);
            throw new UserServiceException("Failed to reach user-service: " + e.getMessage(), e);
        }
    }
}

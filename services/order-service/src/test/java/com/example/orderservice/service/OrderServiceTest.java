package com.example.orderservice.service;

import com.example.orderservice.client.UserServiceClient;
import com.example.orderservice.dto.CreateOrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.dto.UserDto;
import com.example.orderservice.exception.OrderNotFoundException;
import com.example.orderservice.exception.UserServiceException;
import com.example.orderservice.model.Order;
import com.example.orderservice.model.OrderStatus;
import com.example.orderservice.repository.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private UserServiceClient userServiceClient;

    @InjectMocks
    private OrderService orderService;

    private Order sampleOrder;
    private CreateOrderRequest createRequest;

    @BeforeEach
    void setUp() {
        sampleOrder = Order.builder()
                .id(1L).userId(1L).productName("Laptop")
                .quantity(1).price(BigDecimal.valueOf(999.99))
                .status(OrderStatus.PENDING)
                .shippingAddress("123 Main St")
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();

        createRequest = CreateOrderRequest.builder()
                .userId(1L).productName("Laptop").quantity(1)
                .price(BigDecimal.valueOf(999.99)).shippingAddress("123 Main St")
                .build();
    }

    @Test
    void createOrder_success() {
        UserDto user = UserDto.builder().id(1L).firstName("Jane").email("jane@example.com").build();
        when(userServiceClient.getUser(1L)).thenReturn(Optional.of(user));
        when(orderRepository.save(any(Order.class))).thenReturn(sampleOrder);

        OrderResponse response = orderService.createOrder(createRequest);

        assertThat(response.getUserId()).isEqualTo(1L);
        assertThat(response.getProductName()).isEqualTo("Laptop");
        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void createOrder_userNotFound_throwsException() {
        when(userServiceClient.getUser(99L)).thenReturn(Optional.empty());
        createRequest.setUserId(99L);

        assertThatThrownBy(() -> orderService.createOrder(createRequest))
                .isInstanceOf(UserServiceException.class)
                .hasMessageContaining("99");

        verify(orderRepository, never()).save(any());
    }

    @Test
    void getOrderById_notFound_throwsException() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.getOrderById(99L))
                .isInstanceOf(OrderNotFoundException.class)
                .hasMessageContaining("99");
    }

    @Test
    void getAllOrders_returnsList() {
        when(orderRepository.findAll()).thenReturn(List.of(sampleOrder));

        List<OrderResponse> result = orderService.getAllOrders();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getProductName()).isEqualTo("Laptop");
    }
}

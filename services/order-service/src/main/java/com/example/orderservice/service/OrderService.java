package com.example.orderservice.service;

import com.example.orderservice.client.UserServiceClient;
import com.example.orderservice.dto.CreateOrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.exception.OrderNotFoundException;
import com.example.orderservice.exception.UserServiceException;
import com.example.orderservice.model.Order;
import com.example.orderservice.model.OrderStatus;
import com.example.orderservice.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OrderService {

    private final OrderRepository orderRepository;
    private final UserServiceClient userServiceClient;

    public List<OrderResponse> getAllOrders() {
        return orderRepository.findAll().stream().map(this::mapToResponse).toList();
    }

    public OrderResponse getOrderById(Long id) {
        return orderRepository.findById(id)
                .map(this::mapToResponse)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }

    public List<OrderResponse> getOrdersByUser(Long userId) {
        return orderRepository.findByUserId(userId).stream().map(this::mapToResponse).toList();
    }

    public List<OrderResponse> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status).stream().map(this::mapToResponse).toList();
    }

    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request) {
        // Validate that the user exists before creating the order
        userServiceClient.getUser(request.getUserId())
                .orElseThrow(() -> new UserServiceException("User not found with id: " + request.getUserId()));

        Order order = Order.builder()
                .userId(request.getUserId())
                .productName(request.getProductName())
                .quantity(request.getQuantity())
                .price(request.getPrice())
                .shippingAddress(request.getShippingAddress())
                .status(OrderStatus.PENDING)
                .build();
        return mapToResponse(orderRepository.save(order));
    }

    @Transactional
    public OrderResponse updateOrderStatus(Long id, OrderStatus status) {
        Order order = orderRepository.findById(id).orElseThrow(() -> new OrderNotFoundException(id));
        order.setStatus(status);
        return mapToResponse(orderRepository.save(order));
    }

    @Transactional
    public OrderResponse cancelOrder(Long id) {
        Order order = orderRepository.findById(id).orElseThrow(() -> new OrderNotFoundException(id));
        if (order.getStatus() == OrderStatus.DELIVERED) {
            throw new IllegalStateException("Cannot cancel a delivered order");
        }
        order.setStatus(OrderStatus.CANCELLED);
        return mapToResponse(orderRepository.save(order));
    }

    @Transactional
    public void deleteOrder(Long id) {
        if (!orderRepository.existsById(id)) throw new OrderNotFoundException(id);
        orderRepository.deleteById(id);
    }

    private OrderResponse mapToResponse(Order order) {
        BigDecimal totalPrice = order.getPrice().multiply(BigDecimal.valueOf(order.getQuantity()));
        return OrderResponse.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .productName(order.getProductName())
                .quantity(order.getQuantity())
                .price(order.getPrice())
                .totalPrice(totalPrice)
                .status(order.getStatus())
                .shippingAddress(order.getShippingAddress())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}

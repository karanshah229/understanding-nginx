package com.example;

import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.*;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class App {

    @GetMapping("/")
    public String home() {
        // Architect decision: Perform recursive Fibonacci to saturate CPU.
        // n=30 provides a substantial delay (a few ms to 100ms) per request.
        long result = fibonacci(30);
        return "CPU work complete! Fibonacci(30) = " + result;
    }

    private long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(App.class);

        java.util.Map<String, Object> configs = new java.util.HashMap<>();
        // Consistency: Keep Tomcat thread pool identical to previous experiments.
        configs.put("server.tomcat.threads.max", 50);
        app.setDefaultProperties(configs);

        app.run(args);
    }
}

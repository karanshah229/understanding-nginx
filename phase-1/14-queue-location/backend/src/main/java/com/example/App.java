package com.example;

import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Component;
import jakarta.servlet.*;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;

@SpringBootApplication
@RestController
public class App {

    private static final AtomicInteger activeRequests = new AtomicInteger(0);

    @GetMapping("/fast")
    public String fast() {
        return "Fast response!";
    }

    @GetMapping("/slow")
    public String slow() {
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return "Slow response after 500ms!";
    }

    @GetMapping("/management/threads")
    public String threads() {
        return "active_requests:" + activeRequests.get();
    }

    @Component
    public static class RequestTracker implements Filter {
        @Override
        public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                throws IOException, ServletException {
            activeRequests.incrementAndGet();
            try {
                chain.doFilter(request, response);
            } finally {
                activeRequests.decrementAndGet();
            }
        }
    }

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(App.class);

        java.util.Map<String, Object> configs = new java.util.HashMap<>();
        configs.put("server.tomcat.threads.max", 50);
        app.setDefaultProperties(configs);

        app.run(args);
    }
}

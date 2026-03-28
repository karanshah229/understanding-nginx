package com.example;

import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.*;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class App {

    @GetMapping("/")
    public String home() {
        try {
            Thread.sleep(200);
        } catch (InterruptedException e) {
            e.printStackTrace();
        } // simulate work
        return "Hello from one-file Spring Boot!";
    }

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(App.class);

        java.util.Map<String, Object> configs = new java.util.HashMap<>();
        configs.put("server.tomcat.threads.max", 20);
        app.setDefaultProperties(configs);

        app.run(args);

    }
}

package com.example;

import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;
import java.util.Random;

@SpringBootApplication
@RestController
public class App {

    @GetMapping("/fast")
    public String fast() {
        return "Fast path - no compression!";
    }

    @GetMapping("/slow")
    public StreamingResponseBody slow() {
        // Architect decision: Stream the 50MB randomized data on-the-fly.
        // This ensures NGINX starts its 'Read-Compress-Stream' loop immediately,
        // pinning the worker and stalling the event loop without backend-side buffering.
        return outputStream -> {
            Random random = new Random();
            byte[] buffer = new byte[8192]; // 8KB chunks
            long totalBytes = 50 * 1024 * 1024;
            long sent = 0;
            
            while (sent < totalBytes) {
                random.nextBytes(buffer);
                outputStream.write(buffer);
                // Flush to ensure the data reaches NGINX chunk-by-chunk
                outputStream.flush();
                sent += buffer.length;
            }
        };
    }

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(App.class);

        java.util.Map<String, Object> configs = new java.util.HashMap<>();
        configs.put("server.tomcat.threads.max", 100);
        app.setDefaultProperties(configs);

        app.run(args);
    }
}

package com.vocaboo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * Serves uploaded asset files from the local 'uploads/' directory
 * under the /uploads/** URL path. This allows audio/image files
 * uploaded via AssetUploadService to be accessible by the mobile app
 * and admin panel without a separate CDN.
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${vocaboo.uploads.dir:uploads}")
    private String uploadsDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String absolutePath = Paths.get(uploadsDir).toAbsolutePath().toUri().toString();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(absolutePath);
    }
}

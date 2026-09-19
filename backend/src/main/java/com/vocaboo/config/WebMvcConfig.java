package com.vocaboo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Empty configuration since we moved asset uploads to Supabase S3.
 * Previously used to serve the local 'uploads/' directory.
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    // Other MVC configs can be added here
}

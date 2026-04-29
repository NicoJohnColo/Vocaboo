package com.vocaboo.backend.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vocaboo.backend.model.Learner;
import com.vocaboo.backend.repository.LearnerRepository;

@RestController
@RequestMapping("/api/learners")
public class LearnerController {
    
    @Autowired
    private LearnerRepository learnerRepository;
    
    @PostMapping
    public Learner createLearner(@RequestBody Learner learner) {
        return learnerRepository.save(learner);
    }
    
    @PostMapping("/verify-pin")
    public ResponseEntity<Learner> verifyPin(@RequestBody Map<String, String> request) {
        String name = request.get("name");
        String pin = request.get("pin");
        
        Optional<Learner> learnerOpt = learnerRepository.findByName(name);
        if (learnerOpt.isPresent()) {
            Learner learner = learnerOpt.get();
            if (learner.getPin().equals(pin)) {
                return ResponseEntity.ok(learner);
            }
        }
        return ResponseEntity.status(401).build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Learner> getLearner(@PathVariable Long id) {
        Optional<Learner> learner = learnerRepository.findById(id);
        return learner.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }
}

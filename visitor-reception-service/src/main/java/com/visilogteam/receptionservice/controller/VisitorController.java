package com.visilogteam.receptionservice.controller;

import com.visilogteam.receptionservice.entity.Visitor;
import com.visilogteam.receptionservice.service.VisitorService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/visitors")
@CrossOrigin(origins = "*")
public class VisitorController {

    private final VisitorService visitorService;

    public VisitorController(VisitorService visitorService) {
        this.visitorService = visitorService;
    }

    // Register a visitor
    @PostMapping
    public Visitor createVisitor(@Valid @RequestBody Visitor visitor) {
        return visitorService.saveVisitor(visitor);
    }

    // Get all visitors
    @GetMapping
    public List<Visitor> getAllVisitors() {
        return visitorService.getAllVisitors();
    }

    // Get one visitor by ID
    @GetMapping("/{id}")
    public Visitor getVisitorById(@PathVariable Long id) {
        return visitorService.getVisitorById(id);
    }

    // Search visitors
    @GetMapping("/search")
    public List<Visitor> searchVisitors(@RequestParam String keyword) {
        return visitorService.searchVisitors(keyword);
    }

    // Get visitors by status
    @GetMapping("/status/{status}")
    public List<Visitor> getVisitorsByStatus(@PathVariable String status) {
        return visitorService.getVisitorsByStatus(status);
    }

    // Check out by database ID
    @PutMapping("/{id}/checkout")
    public Visitor checkOutVisitor(@PathVariable Long id) {
        return visitorService.checkOutVisitor(id);
    }

    // Check out using NFC card
    @PutMapping("/nfc/{nfcCardId}/checkout")
    public Visitor checkOutVisitorByNfc(@PathVariable String nfcCardId) {
        return visitorService.checkOutVisitorByNfc(nfcCardId);
    }

    // Dashboard statistics
    @GetMapping("/dashboard")
    public Map<String, Long> getDashboardStatistics() {
        return visitorService.getDashboardStatistics();
    }
}
package com.visilogteam.receptionservice.service;

import com.visilogteam.receptionservice.entity.Visitor;
import com.visilogteam.receptionservice.repository.VisitorRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class VisitorService {

    private final VisitorRepository visitorRepository;

    public VisitorService(VisitorRepository visitorRepository) {
        this.visitorRepository = visitorRepository;
    }

    // Register and check in a new visitor
    public Visitor saveVisitor(Visitor visitor) {

        visitor.setCheckInTime(LocalDateTime.now());
        visitor.setCheckOutTime(null);
        visitor.setStatus("CHECKED_IN");

        visitor.setNfcCardId(
                "NFC-" + UUID.randomUUID()
                        .toString()
                        .substring(0, 8)
                        .toUpperCase()
        );

        return visitorRepository.save(visitor);
    }

    // Get all visitors
    public List<Visitor> getAllVisitors() {
        return visitorRepository.findAll();
    }

    // Get one visitor by ID
    public Visitor getVisitorById(Long id) {
        return visitorRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Visitor with ID " + id + " was not found")
                );
    }

    // Filter visitors by status
    public List<Visitor> getVisitorsByStatus(String status) {

        if (status == null || status.isBlank()) {
            throw new RuntimeException("Visitor status is required");
        }

        return visitorRepository.findByStatus(status.toUpperCase());
    }

    // Search visitors using one keyword
    public List<Visitor> searchVisitors(String keyword) {

        if (keyword == null || keyword.isBlank()) {
            return visitorRepository.findAll();
        }

        return visitorRepository
                .findByFullNameContainingIgnoreCaseOrPhoneNumberContainingIgnoreCaseOrCompanyNameContainingIgnoreCaseOrHostEmployeeContainingIgnoreCaseOrNfcCardIdContainingIgnoreCase(
                        keyword,
                        keyword,
                        keyword,
                        keyword,
                        keyword
                );
    }

    // Check out visitor using database ID
    public Visitor checkOutVisitor(Long id) {

        Visitor visitor = visitorRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Visitor with ID " + id + " was not found")
                );

        if ("CHECKED_OUT".equalsIgnoreCase(visitor.getStatus())) {
            throw new RuntimeException("Visitor has already been checked out");
        }

        visitor.setCheckOutTime(LocalDateTime.now());
        visitor.setStatus("CHECKED_OUT");

        return visitorRepository.save(visitor);
    }

    // Check out visitor using virtual NFC card ID
    public Visitor checkOutVisitorByNfc(String nfcCardId) {

        Visitor visitor = visitorRepository.findByNfcCardId(nfcCardId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Visitor with NFC card ID " + nfcCardId + " was not found"
                        )
                );

        if ("CHECKED_OUT".equalsIgnoreCase(visitor.getStatus())) {
            throw new RuntimeException("Visitor has already been checked out");
        }

        visitor.setCheckOutTime(LocalDateTime.now());
        visitor.setStatus("CHECKED_OUT");

        return visitorRepository.save(visitor);
    }

    // Visitor dashboard information
    public Map<String, Long> getDashboardStatistics() {

        LocalDateTime startOfToday =
                LocalDateTime.now().with(LocalTime.MIN);

        LocalDateTime endOfToday =
                LocalDateTime.now().with(LocalTime.MAX);

        long totalVisitors = visitorRepository.count();

        long visitorsToday =
                visitorRepository.countByCheckInTimeBetween(
                        startOfToday,
                        endOfToday
                );

        long currentlyCheckedIn =
                visitorRepository.countByStatus("CHECKED_IN");

        long checkedOutToday =
                visitorRepository.countByStatusAndCheckOutTimeBetween(
                        "CHECKED_OUT",
                        startOfToday,
                        endOfToday
                );

        Map<String, Long> statistics = new LinkedHashMap<>();

        statistics.put("totalVisitors", totalVisitors);
        statistics.put("visitorsToday", visitorsToday);
        statistics.put("currentlyCheckedIn", currentlyCheckedIn);
        statistics.put("checkedOutToday", checkedOutToday);

        return statistics;
    }
}
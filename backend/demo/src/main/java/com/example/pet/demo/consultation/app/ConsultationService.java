package com.example.pet.demo.consultation.app;

import com.example.pet.demo.consultation.api.dto.ConsultationCreateReq;
import com.example.pet.demo.consultation.api.dto.ConsultationRes;
import com.example.pet.demo.consultation.domain.Consultation;
import com.example.pet.demo.consultation.domain.ConsultationRepository;
import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.ReservationRepository;
import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Consultation Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ConsultationService {

    private final ConsultationRepository consultationRepository;
    private final UserRepository userRepository;
    private final PartnerRepository partnerRepository;
    private final ReservationRepository reservationRepository;

    /**
     * 상담 생성
     */
    @Transactional
    public ConsultationRes createConsultation(ConsultationCreateReq req) {
        // 사용자 조회
        User user = userRepository.findById(req.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. ID: " + req.getUserId()));

        // 파트너 조회
        Partner partner = partnerRepository.findById(req.getPartnerId())
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다. ID: " + req.getPartnerId()));

        // 예약 조회 (선택적)
        Reservation reservation = null;
        if (req.getReservationId() != null) {
            reservation = reservationRepository.findById(req.getReservationId())
                    .orElseThrow(() -> new IllegalArgumentException("예약을 찾을 수 없습니다. ID: " + req.getReservationId()));
        }

        // 상담 생성
        Consultation consultation = Consultation.builder()
                .user(user)
                .partner(partner)
                .reservation(reservation)
                .petType(req.getPetType())
                .subject(req.getSubject())
                .content(req.getContent())
                .imageUrl(req.getImageUrl())
                .build();

        Consultation savedConsultation = consultationRepository.save(consultation);

        log.info("상담 생성 완료 - ID: {}, User: {}, Partner: {}",
                 savedConsultation.getId(), user.getNickname(), partner.getName());

        return ConsultationRes.from(savedConsultation);
    }

    /**
     * 특정 사용자의 상담 목록 조회
     */
    public List<ConsultationRes> getConsultationsByUserId(Long userId) {
        return consultationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(ConsultationRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 특정 파트너의 상담 목록 조회
     */
    public List<ConsultationRes> getConsultationsByPartnerId(Long partnerId) {
        return consultationRepository.findByPartnerIdOrderByCreatedAtDesc(partnerId)
                .stream()
                .map(ConsultationRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 상담 상세 조회
     */
    public ConsultationRes getConsultation(Long consultationId) {
        Consultation consultation = consultationRepository.findById(consultationId)
                .orElseThrow(() -> new IllegalArgumentException("상담을 찾을 수 없습니다. ID: " + consultationId));
        return ConsultationRes.from(consultation);
    }

    /**
     * 상담 답변 작성 (파트너용)
     */
    @Transactional
    public ConsultationRes answerConsultation(Long consultationId, String answer) {
        Consultation consultation = consultationRepository.findById(consultationId)
                .orElseThrow(() -> new IllegalArgumentException("상담을 찾을 수 없습니다. ID: " + consultationId));

        consultation.addAnswer(answer);

        log.info("상담 답변 완료 - ID: {}, Partner: {}",
                 consultation.getId(), consultation.getPartner().getName());

        return ConsultationRes.from(consultation);
    }

    /**
     * 상담 취소 (고객용)
     */
    @Transactional
    public void cancelConsultation(Long consultationId) {
        Consultation consultation = consultationRepository.findById(consultationId)
                .orElseThrow(() -> new IllegalArgumentException("상담을 찾을 수 없습니다. ID: " + consultationId));

        consultation.cancel();

        log.info("상담 취소 - ID: {}, User: {}",
                 consultation.getId(), consultation.getUser().getNickname());
    }
}

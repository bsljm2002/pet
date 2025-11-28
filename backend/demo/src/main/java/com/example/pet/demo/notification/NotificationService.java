package com.example.pet.demo.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

@Service
public class NotificationService {
    
    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    
    private final FirebaseApp firebaseApp;
    
    @Autowired
    public NotificationService(@Autowired(required = false) FirebaseApp firebaseApp) {
        this.firebaseApp = firebaseApp;
    }
    
    private boolean isFirebaseEnabled() {
        if (firebaseApp == null) {
            log.warn("⚠️ Firebase가 초기화되지 않아 알림을 전송할 수 없습니다.");
            return false;
        }
        return true;
    }
    
    /**
     * 고객에게 예약 수락 알림 전송
     */
    public void sendReservationAccepted(String targetToken, Long reservationId) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "reservation_accepted")
            .putData("reservation_id", reservationId.toString())
            .setNotification(Notification.builder()
                .setTitle("예약 수락")
                .setBody("파트너가 예약을 수락했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 파트너에게 새 예약 알림 전송
     */
    public void sendNewReservationToPartner(String partnerToken, Long reservationId, String userName) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(partnerToken)
            .putData("type", "reservation_update")
            .putData("reservation_id", reservationId.toString())
            .putData("message", userName + "님의 새 예약이 도착했습니다.")
            .setNotification(Notification.builder()
                .setTitle("새 예약 도착")
                .setBody(userName + "님의 새 예약이 도착했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 파트너에게 예약 상태 변경 알림 전송
     */
    public void sendReservationUpdateToPartner(String partnerToken, Long reservationId, String message) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(partnerToken)
            .putData("type", "reservation_update")
            .putData("reservation_id", reservationId.toString())
            .putData("message", message)
            .setNotification(Notification.builder()
                .setTitle("예약 정보 업데이트")
                .setBody(message)
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 고객에게 예약 거절 알림 전송
     */
    public void sendReservationRejected(String targetToken, Long reservationId, String reason) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        String body = reason != null && !reason.isBlank()
            ? "예약이 거절되었습니다. 사유: " + reason
            : "예약이 거절되었습니다.";

        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "reservation_rejected")
            .putData("reservation_id", reservationId.toString())
            .putData("reason", reason != null ? reason : "")
            .setNotification(Notification.builder()
                .setTitle("예약 거절")
                .setBody(body)
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 고객에게 진료/서비스 완료 알림 전송
     */
    public void sendReservationCompleted(String targetToken, Long reservationId) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "reservation_completed")
            .putData("reservation_id", reservationId.toString())
            .setNotification(Notification.builder()
                .setTitle("진료 완료")
                .setBody("진료가 완료되었습니다. 리뷰를 남겨주세요!")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 파트너에게 예약 취소 알림 전송
     */
    public void sendReservationCancelled(String targetToken, Long reservationId) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "reservation_cancelled")
            .putData("reservation_id", reservationId.toString())
            .setNotification(Notification.builder()
                .setTitle("예약 취소")
                .setBody("고객이 예약을 취소했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 파트너에게 상담 요청 알림 전송
     */
    public void sendConsultationRequested(String targetToken, Long consultationId) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "consultation_requested")
            .putData("consultation_id", consultationId.toString())
            .setNotification(Notification.builder()
                .setTitle("새 상담 요청")
                .setBody("고객의 새로운 상담 요청이 도착했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }

    /**
     * 고객에게 상담 답변 알림 전송
     */
    public void sendConsultationAnswered(String targetToken, Long consultationId) throws FirebaseMessagingException {
        if (!isFirebaseEnabled()) return;
        
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("type", "consultation_answered")
            .putData("consultation_id", consultationId.toString())
            .setNotification(Notification.builder()
                .setTitle("상담 답변 완료")
                .setBody("파트너가 상담에 답변했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }
}

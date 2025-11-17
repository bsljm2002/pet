package com.example.pet.demo.notification;

import org.springframework.stereotype.Service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NotificationService {
    public void sendReservationAccepted(String targetToken, Long reservationId) throws FirebaseMessagingException {
        Message msg = Message.builder()
            .setToken(targetToken)
            .putData("reservation_id", reservationId.toString())
            .setNotification(Notification.builder()
                .setTitle("예약 수락")
                .setBody("파트너가 예약을 수락했습니다.")
                .build())
            .build();
        FirebaseMessaging.getInstance().send(msg);
    }
}

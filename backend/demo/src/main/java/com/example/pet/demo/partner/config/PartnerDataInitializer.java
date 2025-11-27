package com.example.pet.demo.partner.config;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.partner.domain.PartnerType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * 파트너(수의사/펫시터) 초기 데이터 삽입
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PartnerDataInitializer implements CommandLineRunner {

    private final PartnerRepository partnerRepository;

    @Override
    public void run(String... args) {
        // 이미 데이터가 있으면 스킵
        if (partnerRepository.count() > 0) {
            log.info("Partner 데이터가 이미 존재합니다. 초기화를 스킵합니다.");
            return;
        }

        log.info("Partner 초기 데이터 삽입 시작...");

        // ============== 수의사(동물병원) 데이터 ==============

        // 1. 루나 동물의료센터
        Partner hospital1 = Partner.builder()
                .partnerType(PartnerType.HOSPITAL)
                .name("루나 동물의료센터")
                .doctorName("김루나 대표원장")
                .address("서울특별시 강남구 테헤란로 218")
                .latitude(37.5012743)
                .longitude(127.0396597)
                .phone("02-501-1200")
                .description("24시간 응급진료 가능한 종합 동물병원입니다. 최신 의료장비를 갖추고 있으며, 내과, 외과, 치과 전문 수의사가 상주하고 있습니다.")
                .specialties("내과,외과,영상의학,치과")
                .availableTimes("09:00,10:30,14:00,16:30,18:00")
                .education("서울대학교 수의과대학 졸업,대한수의학회 인증 수의사")
                .experience("동물병원 15년 경력")
                .certifications("수의사 면허,동물병원 개설 허가증")
                .rating(4.8)
                .distance(1.2)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 2. 해피독 동물병원
        Partner hospital2 = Partner.builder()
                .partnerType(PartnerType.HOSPITAL)
                .name("해피독 동물병원")
                .doctorName("박민수 원장")
                .address("서울특별시 서초구 반포대로 58")
                .latitude(37.5048814)
                .longitude(127.0024723)
                .phone("02-532-7890")
                .description("강아지 전문 동물병원으로 피부과와 정형외과에 특화되어 있습니다.")
                .specialties("피부과,정형외과,예방접종")
                .availableTimes("09:30,11:00,14:30,16:00,17:30")
                .education("건국대학교 수의과대학 졸업,미국 수의피부과 전문의")
                .experience("피부과 전문 10년 경력")
                .certifications("수의사 면허,피부과 전문의 자격증")
                .rating(4.6)
                .distance(2.5)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 3. 캣츠케어 동물병원
        Partner hospital3 = Partner.builder()
                .partnerType(PartnerType.HOSPITAL)
                .name("캣츠케어 동물병원")
                .doctorName("이수진 원장")
                .address("서울특별시 송파구 올림픽로 300")
                .latitude(37.5145812)
                .longitude(127.1031473)
                .phone("02-412-5566")
                .description("고양이 전문 동물병원입니다. 고양이 친화적인 진료 환경과 스트레스 최소화 진료를 지향합니다.")
                .specialties("고양이내과,치과,중성화")
                .availableTimes("10:00,11:30,13:00,15:00,17:00")
                .education("전남대학교 수의과대학 졸업,일본 고양이 전문병원 연수")
                .experience("고양이 전문 12년 경력")
                .certifications("수의사 면허,고양이 전문병원 인증")
                .rating(4.9)
                .distance(3.8)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 4. 우리동물메디컬센터
        Partner hospital4 = Partner.builder()
                .partnerType(PartnerType.HOSPITAL)
                .name("우리동물메디컬센터")
                .doctorName("최진호 원장")
                .address("서울특별시 마포구 월드컵북로 396")
                .latitude(37.5667890)
                .longitude(126.9001234)
                .phone("02-335-8800")
                .description("2차 진료 전문 동물병원으로 CT, MRI 등 첨단 장비를 보유하고 있습니다.")
                .specialties("종양학,영상의학,신경외과")
                .availableTimes("09:00,10:00,11:00,14:00,15:00,16:00")
                .education("서울대학교 수의과대학 졸업,미국 수의종양학 전문의")
                .experience("종양학 전문 8년 경력")
                .certifications("수의사 면허,종양학 전문의 자격증")
                .rating(4.7)
                .distance(4.2)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 5. 펫플러스 동물병원
        Partner hospital5 = Partner.builder()
                .partnerType(PartnerType.HOSPITAL)
                .name("펫플러스 동물병원")
                .doctorName("정예린 원장")
                .address("서울특별시 용산구 이태원로 200")
                .latitude(37.5345123)
                .longitude(126.9945678)
                .phone("02-749-3300")
                .description("일반 진료부터 재활치료까지 제공하는 종합 동물병원입니다.")
                .specialties("재활치료,물리치료,일반내과")
                .availableTimes("08:30,10:00,13:00,15:30,17:00")
                .education("강원대학교 수의과대학 졸업,동물재활치료 전문과정 이수")
                .experience("동물재활 전문 7년 경력")
                .certifications("수의사 면허,재활치료사 자격증")
                .rating(4.5)
                .distance(2.1)
                .isOpen(false)
                .imageUrl("")
                .build();

        // ============== 펫시터 데이터 ==============

        // 1. 댕댕케어 펫시터
        Partner sitter1 = Partner.builder()
                .partnerType(PartnerType.SITTER)
                .name("댕댕케어")
                .doctorName("강민지")
                .address("서울특별시 강남구 역삼동 123-45")
                .latitude(37.4983456)
                .longitude(127.0278987)
                .phone("010-1234-5678")
                .description("강아지 전문 펫시터입니다. 산책, 목욕, 놀이 등 전문적인 케어를 제공합니다.")
                .specialties("산책,목욕,놀이케어")
                .availableTimes("09:00,10:00,14:00,16:00,18:00")
                .education("반려동물관리사 1급,반려동물행동교정사")
                .experience("펫시터 5년 경력")
                .certifications("반려동물관리사 1급,반려동물행동교정사 자격증")
                .rating(4.8)
                .distance(0.8)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 2. 냥이네 펫시터
        Partner sitter2 = Partner.builder()
                .partnerType(PartnerType.SITTER)
                .name("냥이네")
                .doctorName("이유진")
                .address("서울특별시 서초구 서초동 456-78")
                .latitude(37.4876543)
                .longitude(127.0134567)
                .phone("010-2345-6789")
                .description("고양이 전문 펫시터입니다. 고양이의 습성을 잘 이해하고 스트레스 없는 케어를 제공합니다.")
                .specialties("고양이케어,급식관리,화장실관리")
                .availableTimes("08:00,10:00,15:00,17:00,19:00")
                .education("고양이행동전문가 과정 수료")
                .experience("고양이 전문 펫시터 6년 경력")
                .certifications("반려동물관리사 1급,고양이행동전문가")
                .rating(4.9)
                .distance(1.5)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 3. 펫프렌즈
        Partner sitter3 = Partner.builder()
                .partnerType(PartnerType.SITTER)
                .name("펫프렌즈")
                .doctorName("박준호")
                .address("서울특별시 송파구 잠실동 789-12")
                .latitude(37.5123456)
                .longitude(127.0989012)
                .phone("010-3456-7890")
                .description("대형견 케어 전문 펫시터입니다. 넓은 공간에서 안전하게 돌봐드립니다.")
                .specialties("대형견케어,산책,사회화훈련")
                .availableTimes("07:00,09:00,15:00,18:00")
                .education("애견훈련사 자격증,반려동물관리사 1급")
                .experience("대형견 전문 펫시터 8년 경력")
                .certifications("애견훈련사 자격증,반려동물관리사 1급")
                .rating(4.7)
                .distance(3.2)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 4. 해피펫케어
        Partner sitter4 = Partner.builder()
                .partnerType(PartnerType.SITTER)
                .name("해피펫케어")
                .doctorName("김서연")
                .address("서울특별시 마포구 상암동 345-67")
                .latitude(37.5789012)
                .longitude(126.8890123)
                .phone("010-4567-8901")
                .description("방문 펫시터 서비스를 제공합니다. 반려동물이 편안한 집에서 케어받을 수 있습니다.")
                .specialties("방문케어,급식,산책,놀이")
                .availableTimes("10:00,12:00,14:00,16:00,18:00,20:00")
                .education("반려동물관리사 2급,펫시터 전문과정 수료")
                .experience("방문 펫시터 4년 경력")
                .certifications("반려동물관리사 2급")
                .rating(4.6)
                .distance(4.5)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 5. 펫케어365
        Partner sitter5 = Partner.builder()
                .partnerType(PartnerType.SITTER)
                .name("펫케어365")
                .doctorName("최민석")
                .address("서울특별시 용산구 한남동 890-23")
                .latitude(37.5345678)
                .longitude(127.0012345)
                .phone("010-5678-9012")
                .description("24시간 펫시터 서비스를 제공합니다. 장기 출장이나 여행 시에도 안심하고 맡기실 수 있습니다.")
                .specialties("24시간케어,장기위탁,응급상황대처")
                .availableTimes("상시가능")
                .education("반려동물관리사 1급,응급처치 교육 이수")
                .experience("24시간 펫시터 3년 경력")
                .certifications("반려동물관리사 1급,펫시터 자격증")
                .rating(4.8)
                .distance(2.8)
                .isOpen(true)
                .imageUrl("")
                .build();

        // 데이터 저장
        partnerRepository.save(hospital1);
        partnerRepository.save(hospital2);
        partnerRepository.save(hospital3);
        partnerRepository.save(hospital4);
        partnerRepository.save(hospital5);
        partnerRepository.save(sitter1);
        partnerRepository.save(sitter2);
        partnerRepository.save(sitter3);
        partnerRepository.save(sitter4);
        partnerRepository.save(sitter5);

        log.info("Partner 초기 데이터 삽입 완료! (수의사 5개, 펫시터 5개)");
    }
}

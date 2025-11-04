import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vet_model.dart';
import '../models/reservation_model.dart';

class ApiService {
  // 백엔드 서버 URL (실제 서버 주소로 변경 필요)
  static const String baseUrl = 'https://your-api-server.com/api';

  // 수의사 목록 조회
  static Future<List<VetModel>> getVets({
    String? petType,
    String? specialty,
    String? timeSlot,
  }) async {
    try {
      // 쿼리 파라미터 구성
      Map<String, String> queryParams = {};
      if (petType != null) queryParams['petType'] = petType;
      if (specialty != null) queryParams['specialty'] = specialty;
      if (timeSlot != null) queryParams['timeSlot'] = timeSlot;

      Uri uri = Uri.parse(
        '$baseUrl/vets',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => VetModel.fromJson(json)).toList();
      } else {
        throw Exception('수의사 목록을 불러오는데 실패했습니다');
      }
    } catch (e) {
      // 임시 더미 데이터 반환 (개발용)
      return _getDummyVets();
    }
  }

  // 예약 생성
  static Future<bool> createReservation(ReservationModel reservation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reservation.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('예약 생성 오류: $e');
      return false;
    }
  }

  // 내 예약 목록 조회
  static Future<List<ReservationModel>> getMyReservations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations/my'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => ReservationModel.fromJson(json)).toList();
      } else {
        throw Exception('예약 목록을 불러오는데 실패했습니다');
      }
    } catch (e) {
      return _getDummyReservations();
    }
  }

  // 더미 데이터 (개발용)
  static List<VetModel> _getDummyVets() {
    return [
      VetModel(
        id: '1',
        name: '루나 동물의료센터',
        doctorName: '김루나 대표원장',
        address: '서울특별시 강남구 테헤란로 218',
        phone: '02-501-1200',
        rating: 4.9,
        specialties: ['내과', '외과', '영상의학'],
        availableTimes: ['09:00', '10:30', '14:00', '16:30'],
        distance: 0.6,
        isOpen: true,
        imageUrl: '',
        description: "응애 나 의사임ㅋㅋㅋ 꿀팁 주지ㅋㅋㅋ",
      ),
      VetModel(
        id: '2',
        name: '브릿지 동물클리닉',
        doctorName: '이도현 원장',
        address: '서울특별시 서초구 사임당로 174',
        phone: '02-586-7700',
        rating: 4.7,
        specialties: ['내과', '피부과', '안과'],
        availableTimes: ['10:00', '12:00', '15:00', '18:00'],
        distance: 1.1,
        isOpen: true,
        imageUrl: 'https://example.com/vet2.jpg',
        description: '야구선수 이도현입니다. 초강력 직구를 바탕으로 머리를 띵~ 리셋해주겠어!!',
      ),
      VetModel(
        id: '3',
        name: '소나무 동물메디컬',
        doctorName: '박해리 부원장',
        address: '서울특별시 송파구 백제고분로 358',
        phone: '02-414-9901',
        rating: 4.6,
        specialties: ['정형외과', '내과', '재활'],
        availableTimes: ['09:30', '11:00', '15:30', '19:00'],
        distance: 2.3,
        isOpen: true,
        imageUrl: 'https://example.com/vet3.jpg',
        description: '와가 코코리니 코타에로, 오레노 나미다가 코보레루',
      ),
      VetModel(
        id: '4',
        name: '마포 24시 센트럴동물병원',
        doctorName: '윤강민 센터장',
        address: '서울특별시 마포구 월드컵북로 78',
        phone: '02-3152-7575',
        rating: 4.5,
        specialties: ['응급의학', '중환자', '영상의학'],
        availableTimes: ['00:00', '06:00', '12:00', '18:00'],
        distance: 3.1,
        isOpen: true,
        imageUrl: 'https://example.com/vet4.jpg',
        description:
            '24시간 응급진료 시스템으로 언제나 반려동물을 지킵니다. 응급의학과 중환자 치료 전문의가 상주하여 위급한 상황에서도 신속하고 정확한 치료를 제공합니다.',
      ),
      VetModel(
        id: '5',
        name: '더스마일 동물병원',
        doctorName: '최유진 진료부장',
        address: '서울특별시 용산구 한강대로 210',
        phone: '02-798-9005',
        rating: 4.4,
        specialties: ['치과', '안과', '예방의학'],
        availableTimes: ['10:00', '13:00', '17:00', '20:00'],
        distance: 2.9,
        isOpen: false,
        imageUrl: '',
        description:
            '반려동물의 구강 건강과 시력 보호에 특화된 진료를 제공합니다. 예방접종과 정기검진을 통해 질병 예방에 힘쓰며, 건강한 삶을 위한 맞춤 상담을 진행합니다.',
      ),
      VetModel(
        id: '6',
        name: '분당 하이큐 동물메디컬센터',
        doctorName: '신민아 의료원장',
        address: '경기도 성남시 분당구 황새울로 330',
        phone: '031-702-5588',
        rating: 4.9,
        specialties: ['내과', '재활의학', '초음파'],
        availableTimes: ['09:00', '10:30', '13:30', '17:30'],
        distance: 12.2,
        isOpen: true,
        imageUrl: 'https://example.com/vet6.jpg',
        description:
            '첨단 의료장비와 재활 시설을 갖춘 종합 동물병원입니다. 초음파 진단과 재활의학 분야의 전문가로서 정확한 진단과 체계적인 치료 계획을 제공합니다.',
      ),
      VetModel(
        id: '7',
        name: '수원 로얄동물병원',
        doctorName: '이재훈 진료원장',
        address: '경기도 수원시 영통구 광교호수공원로 190',
        phone: '031-217-7008',
        rating: 4.2,
        specialties: ['피부과', '내과', '노령견케어'],
        availableTimes: ['09:30', '12:00', '16:30', '19:30'],
        distance: 27.6,
        isOpen: true,
        imageUrl: 'https://example.com/vet7.jpg',
        description:
            '피부 질환 전문 치료와 노령 반려동물 케어에 특화된 병원입니다. 10년 이상의 피부과 진료 경험을 바탕으로 알레르기부터 만성 피부염까지 체계적으로 관리합니다.',
      ),
      VetModel(
        id: '8',
        name: '일산 라이트 동물의료원',
        doctorName: '정은별 수의사',
        address: '경기도 고양시 일산동구 중앙로 1354',
        phone: '031-908-1199',
        rating: 4.5,
        specialties: ['외과', '정형외과', '치과'],
        availableTimes: ['08:30', '11:30', '14:30', '18:30'],
        distance: 25.8,
        isOpen: true,
        imageUrl: 'https://example.com/vet8.jpg',
        description:
            '외과 수술과 정형외과 치료의 전문가입니다. 무균 수술실과 최신 마취 시스템을 통해 안전하고 정밀한 수술을 제공하며, 수술 후 관리까지 책임집니다.',
      ),
      VetModel(
        id: '9',
        name: '부천 리버 동물병원',
        doctorName: '문지후 대표수의사',
        address: '경기도 부천시 부흥로 157',
        phone: '032-612-7555',
        rating: 4.1,
        specialties: ['내과', '예방접종', '노령묘케어'],
        availableTimes: ['09:00', '12:30', '15:00', '18:30'],
        distance: 20.9,
        isOpen: false,
        imageUrl: 'https://example.com/vet9.jpg',
        description:
            '예방의학과 노령 고양이 전문 케어에 집중하는 병원입니다. 정기 건강검진과 맞춤형 예방접종 스케줄을 통해 반려묘의 건강한 노년을 책임집니다.',
      ),
      VetModel(
        id: '10',
        name: '해운대 오션 동물응급센터',
        doctorName: '배서현 센터장',
        address: '부산광역시 해운대구 센텀2로 32',
        phone: '051-922-3650',
        rating: 4.8,
        specialties: ['응급의학', '중환자', '영상의학'],
        availableTimes: ['00:00', '08:00', '16:00', '22:00'],
        distance: 325.4,
        isOpen: true,
        imageUrl: 'https://example.com/vet10.jpg',
        description:
            '부산 지역 유일의 24시간 응급의료센터입니다. 중환자실과 첨단 영상의학 장비를 갖추고 있어 위급한 상황에서도 신속하고 전문적인 치료가 가능합니다.',
      ),
      VetModel(
        id: '11',
        name: '대구 라온 동물메디컬',
        doctorName: '강지석 총괄원장',
        address: '대구광역시 수성구 동대구로 275',
        phone: '053-768-9900',
        rating: 4.3,
        specialties: ['내과', '피부과', '안과'],
        availableTimes: ['09:30', '11:30', '14:30', '18:30'],
        distance: 238.6,
        isOpen: true,
        imageUrl: 'https://example.com/vet11.jpg',
        description:
            '대구 지역 대표 동물의료기관으로 내과, 피부과, 안과 전문진료를 제공합니다. 풍부한 임상경험을 바탕으로 정확한 진단과 효과적인 치료를 약속드립니다.',
      ),
      VetModel(
        id: '12',
        name: '광주 라임 동물의료센터',
        doctorName: '장서윤 부원장',
        address: '광주광역시 서구 상무자유로 77',
        phone: '062-381-6400',
        rating: 4.6,
        specialties: ['외과', '치과', '내과'],
        availableTimes: ['10:00', '12:30', '15:30', '19:30'],
        distance: 298.4,
        isOpen: true,
        imageUrl: 'https://example.com/vet12.jpg',
        description:
            '광주 지역의 신뢰받는 동물의료센터입니다. 외과 수술과 치과 치료에 특화되어 있으며, 반려동물의 구강 건강부터 복합 수술까지 전문적으로 진료합니다.',
      ),
      VetModel(
        id: '13',
        name: '대전 베라 동물병원',
        doctorName: '노아린 책임수의사',
        address: '대전광역시 유성구 대학로 51',
        phone: '042-867-3300',
        rating: 4.7,
        specialties: ['안과', '내과', '피부과'],
        availableTimes: ['09:00', '11:00', '14:00', '18:00'],
        distance: 163.8,
        isOpen: true,
        imageUrl: 'https://example.com/vet13.jpg',
        description:
            '안과 전문의로서 백내장, 녹내장 등 다양한 안질환 치료에 전문성을 갖추고 있습니다. 첨단 안과 장비를 통한 정밀 진단과 맞춤 치료를 제공합니다.',
      ),
      VetModel(
        id: '14',
        name: '울산 네스트 동물의료원',
        doctorName: '오성민 메디컬디렉터',
        address: '울산광역시 남구 삼산로 246',
        phone: '052-260-7575',
        rating: 4.4,
        specialties: ['정형외과', '재활', '스포츠의학'],
        availableTimes: ['10:00', '13:00', '16:00', '20:00'],
        distance: 304.9,
        isOpen: true,
        imageUrl: 'https://example.com/vet14.jpg',
        description:
            '정형외과와 스포츠의학 전문 동물병원입니다. 수술용 관절경과 재활 장비를 갖추어 운동성 부상부터 관절 질환까지 체계적으로 치료합니다.',
      ),
      VetModel(
        id: '15',
        name: '제주 포레스트 동물병원',
        doctorName: '고수빈 병원장',
        address: '제주특별자치도 제주시 연삼로 132',
        phone: '064-742-2225',
        rating: 4.9,
        specialties: ['내과', '피부과', '예방의학'],
        availableTimes: ['09:00', '10:30', '14:30', '17:00'],
        distance: 451.8,
        isOpen: true,
        imageUrl: 'https://example.com/vet15.jpg',
        description:
            '제주도의 대표 동물병원으로 청정 자연환경에서 반려동물의 건강을 지킵니다. 알레르기성 피부염과 아토피 치료에 특화되어 있으며, 자연친화적 치료법을 병행합니다.',
      ),
      VetModel(
        id: '16',
        name: '송도 더케어 동물병원',
        doctorName: '서다혜 진료수의사',
        address: '인천광역시 연수구 센트럴로 238',
        phone: '032-458-6000',
        rating: 4.2,
        specialties: ['예방의학', '내과', '영양상담'],
        availableTimes: ['09:30', '12:00', '15:30', '18:30'],
        distance: 27.1,
        isOpen: false,
        imageUrl: 'https://example.com/vet16.jpg',
        description:
            '예방의학과 영양 관리에 특화된 동물병원입니다. 반려동물의 생애주기별 맞춤 건강 관리와 전문 영양사의 식단 상담을 통해 평생 건강을 책임집니다.',
      ),
      VetModel(
        id: '17',
        name: '김포 클라우드 동물메디컬',
        doctorName: '전민수 대표원장',
        address: '경기도 김포시 풍무로 115',
        phone: '031-981-7070',
        rating: 4.1,
        specialties: ['내과', '외과', '노령견케어'],
        availableTimes: ['08:30', '11:00', '14:00', '17:30'],
        distance: 32.5,
        isOpen: true,
        imageUrl: 'https://example.com/vet17.jpg',
        description:
            '노령 반려동물의 전문적인 케어와 관리에 집중하는 병원입니다. 관절염, 신장질환 등 노화 관련 질환의 조기 발견과 맞춤 치료로 건강한 노년을 돕습니다.',
      ),
      VetModel(
        id: '18',
        name: '평택 센트럴 케어센터',
        doctorName: '이선미 메디컬리더',
        address: '경기도 평택시 평택로 178',
        phone: '031-618-5525',
        rating: 4.3,
        specialties: ['정형외과', '재활', '영상진단'],
        availableTimes: ['09:00', '11:30', '13:30', '19:30'],
        distance: 61.8,
        isOpen: true,
        imageUrl: 'https://example.com/vet18.jpg',
        description:
            '정형외과 수술과 재활치료의 통합 의료센터입니다. CT, MRI 등 첨단 영상진단 장비를 보유하여 정확한 진단을 바탕으로 한 맞춤형 치료 계획을 제공합니다.',
      ),
      VetModel(
        id: '19',
        name: '천안 헤일로 동물병원',
        doctorName: '안지우 진료원장',
        address: '충청남도 천안시 서북구 충무로 152',
        phone: '041-575-7700',
        rating: 4.6,
        specialties: ['내과', '치과', '안과'],
        availableTimes: ['09:30', '12:30', '15:00', '18:30'],
        distance: 88.7,
        isOpen: true,
        imageUrl: 'https://example.com/vet19.jpg',
        description:
            '치과 전문 진료와 안과 질환 치료에 특화된 병원입니다. 치석제거부터 발치수술까지, 그리고 각막염부터 백내장까지 전문적인 치료를 제공합니다.',
      ),
      VetModel(
        id: '20',
        name: '전주 그린리프 동물의료원',
        doctorName: '백상우 부원장',
        address: '전라북도 전주시 덕진구 백제대로 510',
        phone: '063-275-9900',
        rating: 4.5,
        specialties: ['외과', '내과', '초음파'],
        availableTimes: ['10:00', '12:00', '16:00', '20:00'],
        distance: 206.8,
        isOpen: true,
        imageUrl: 'https://example.com/vet20.jpg',
        description:
            '전라북도 대표 동물의료원으로 외과 수술과 초음파 진단에 뛰어난 전문성을 갖추고 있습니다. 복강경 수술 등 최소침습 수술법으로 빠른 회복을 돕습니다.',
      ),
      VetModel(
        id: '21',
        name: '포항 하모니 동물병원',
        doctorName: '이해진 주치의',
        address: '경상북도 포항시 북구 중흥로 118',
        phone: '054-242-5858',
        rating: 4.4,
        specialties: ['내과', '피부과', '노령묘케어'],
        availableTimes: ['09:00', '11:30', '14:30', '18:00'],
        distance: 285.9,
        isOpen: true,
        imageUrl: 'https://example.com/vet21.jpg',
        description:
            '고양이 전문 진료와 피부 질환 치료에 특화된 병원입니다. 특히 노령묘의 만성질환 관리와 생활환경 개선을 통한 홀리스틱 케어를 제공합니다.',
      ),
      VetModel(
        id: '22',
        name: '창원 브라운라이트 동물센터',
        doctorName: '윤지호 메디컬디렉터',
        address: '경상남도 창원시 성산구 상남로 256',
        phone: '055-284-2233',
        rating: 4.3,
        specialties: ['내과', '정형외과', '재활'],
        availableTimes: ['09:30', '12:30', '15:30', '19:30'],
        distance: 313.2,
        isOpen: false,
        imageUrl: 'https://example.com/vet22.jpg',
        description:
            '경남 지역 최대 규모의 동물의료센터입니다. 내과부터 정형외과까지 원스톱 진료 시스템을 갖추고 있으며, 수술 후 재활 프로그램까지 체계적으로 관리합니다.',
      ),
    ];
  }

  static List<ReservationModel> _getDummyReservations() {
    return [
      ReservationModel(
        id: '1',
        vetId: '1',
        vetName: '강남 동물병원',
        petName: '멍멍이',
        petType: '강아지',
        specialty: '내과',
        reservationDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '14:00',
        status: '예약완료',
        memo: '감기 증상으로 진료 예약',
      ),
    ];
  }
}

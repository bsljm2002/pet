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

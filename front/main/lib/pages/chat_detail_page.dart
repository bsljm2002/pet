import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import '../services/partner_reservation_service.dart';
import '../services/location_tracking_service.dart';
import '../services/route_service.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class ChatDetailPage extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatDetailPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final PartnerService _partnerService = PartnerService();
  final PartnerReservationService _reservationService = PartnerReservationService();
  final LocationTrackingService _locationService = LocationTrackingService();
  final RouteService _routeService = RouteService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _currentUserId;
  String _currentUserType = 'USER';
  String? _currentReservationStatus; // 로컬 상태 추적용

  // 위치 추적 관련
  KakaoMapController? _mapController;
  StreamSubscription<Map<String, dynamic>?>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  Map<String, dynamic>? _sitterLocation;
  Map<String, dynamic>? _userLocation;
  bool _showMap = false;
  bool _isMapExpanded = true; // 지도 펼침/접기 상태

  // 경로 안내 관련
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    _currentReservationStatus = widget.chatRoom.reservationStatus;
    print('🔍 [채팅방] 초기 상태: ${widget.chatRoom.reservationStatus}');
    print('🔍 [채팅방] 서비스 타입: ${widget.chatRoom.serviceType}');
    print('🔍 [채팅방] 예약 ID: ${widget.chatRoom.reservationId}');
    _loadCurrentUser();
    _listenToReservationStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  /// Firebase에서 예약 상태를 실시간으로 감지 (사용자가 채팅방에 있을 때 펫시터가 수락하는 경우)
  void _listenToReservationStatus() {
    final database = FirebaseDatabase.instance.ref();

    // Firebase의 채팅방 상태를 실시간으로 감지
    _statusSubscription = database
        .child('chat_rooms')
        .child(widget.chatRoom.id.toString())
        .child('reservationStatus')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final newStatus = event.snapshot.value as String;
        print('🔄 [상태감지] Firebase에서 예약 상태 변경 감지: $newStatus');

        if (newStatus != _currentReservationStatus && mounted) {
          setState(() {
            _currentReservationStatus = newStatus;
          });

          print('✅ [상태감지] 상태 업데이트됨: $_currentReservationStatus');

          // 상태가 CHECKED_IN으로 변경되면 위치 추적 시작
          if (newStatus == 'CHECKED_IN') {
            _checkAndStartLocationTracking();
          }
        }
      }
    });
  }

  /// 위치 추적 시작 확인 (CHECKED_IN 상태일 때)
  Future<void> _checkAndStartLocationTracking() async {
    print('🔍 [위치추적] 추적 시작 확인 중...');
    print('🔍 [위치추적] 예약 상태: $_currentReservationStatus');
    print('🔍 [위치추적] 서비스 타입: ${widget.chatRoom.serviceType}');
    print('🔍 [위치추적] 사용자 타입: $_currentUserType');

    // 기존 스트림 취소 (중복 방지)
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
      print('🔄 [위치추적] 기존 스트림 취소됨');
    }

    if (_currentReservationStatus == 'CHECKED_IN' &&
        widget.chatRoom.serviceType == 'SITTER') {
      print('✅ [위치추적] 조건 충족! 위치 스트림 구독 시작');

      if (_currentUserType == 'PARTNER') {
        // 펫시터는 사용자(고객)의 위치를 Firebase에서 구독
        print('🏃 [펫시터] 고객 위치 스트림 구독 중...');
        _locationSubscription = _locationService
            .getUserLocationStream(widget.chatRoom.reservationId)
            .listen((location) {
          print('📍 [펫시터] 고객 위치 데이터 수신: $location');
          if (mounted) {
            setState(() {
              _userLocation = location;
              _showMap = location != null;
              print('📍 [펫시터] 지도 표시: $_showMap');
            });

            // 두 위치가 모두 있으면 경로 자동 로드
            if (_sitterLocation != null && location != null) {
              _loadRoute();
            }
          }
        });

        // 펫시터도 자신의 위치를 구독 (경로 표시를 위해)
        print('🏃 [펫시터] 자신의 위치 스트림도 구독...');
        _locationService
            .getSitterLocationStream(widget.chatRoom.reservationId)
            .listen((location) {
          print('📍 [펫시터] 내 위치 데이터 수신: $location');
          if (mounted) {
            setState(() {
              _sitterLocation = location;
            });

            // 두 위치가 모두 있으면 경로 자동 로드
            if (location != null && _userLocation != null) {
              _loadRoute();
            }
          }
        });
      } else {
        // 사용자는 펫시터의 위치를 Firebase에서 구독
        print('👤 [사용자] 펫시터 위치 스트림 구독 중...');
        _locationSubscription = _locationService
            .getSitterLocationStream(widget.chatRoom.reservationId)
            .listen((location) {
          print('📍 [사용자] 펫시터 위치 데이터 수신: $location');
          if (mounted) {
            setState(() {
              _sitterLocation = location;
              _showMap = location != null;
              print('📍 [사용자] 지도 표시: $_showMap');
            });

            // 두 위치가 모두 있으면 경로 자동 로드
            if (location != null && _userLocation != null) {
              _loadRoute();
            }
          }
        });

        // 사용자는 예약 정보에서 서비스 위치를 Firebase에 업로드 (펫시터가 볼 수 있도록)
        print('👤 [사용자] 예약 정보에서 서비스 위치를 가져와 Firebase에 업로드 중...');
        await _loadAndUploadServiceLocation();

        // 사용자도 자신의 위치를 구독 (경로 표시를 위해)
        print('👤 [사용자] 자신의 위치 스트림도 구독...');
        _locationService
            .getUserLocationStream(widget.chatRoom.reservationId)
            .listen((location) {
          print('📍 [사용자] 내 위치 데이터 수신: $location');
          if (mounted) {
            setState(() {
              _userLocation = location;
            });

            // 두 위치가 모두 있으면 경로 자동 로드
            if (location != null && _sitterLocation != null) {
              _loadRoute();
            }
          }
        });
      }
    } else {
      print('❌ [위치추적] 조건 미충족 - 위치 추적 시작 안함');
      if (_currentReservationStatus != 'CHECKED_IN') {
        print('  → 상태가 CHECKED_IN이 아님: $_currentReservationStatus');
      }
      if (widget.chatRoom.serviceType != 'SITTER') {
        print('  → 서비스 타입이 SITTER가 아님: ${widget.chatRoom.serviceType}');
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = int.parse(user.id);
        // 파트너 사용자인지 확인
        // 파트너는 partnerId와 userId가 같고, chatRoom의 partnerId와 일치
        if (_currentUserId == widget.chatRoom.partnerId) {
          _currentUserType = 'PARTNER';
        } else {
          _currentUserType = 'USER';
        }
      });

      print('🔍 [채팅방] 현재 사용자 타입: $_currentUserType');
      print('🔍 [채팅방] 현재 사용자 ID: $_currentUserId');

      // 메시지 읽음 처리
      await _chatService.markMessagesAsRead(
        widget.chatRoom.id,
        _currentUserType,
      );

      // 사용자 로드 후 위치 추적 시작
      await _checkAndStartLocationTracking();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      print('🔥 메시지 전송 시작: chatRoomId=${widget.chatRoom.id}, senderId=$_currentUserId');

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: _currentUserId!,
        senderType: _currentUserType,
        message: message,
      );

      print('✅ 메시지 전송 성공');
      _scrollToBottom();
    } catch (e, stackTrace) {
      print('❌ 메시지 전송 실패: $e');
      print('스택 트레이스: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 메시지 복구
      _messageController.text = message;
    }
  }

  /// 예약 정보에서 서비스 위치를 가져와 Firebase에 업로드
  Future<void> _loadAndUploadServiceLocation() async {
    try {
      // 백엔드에서 예약 정보 가져오기
      final url = Uri.parse('${ApiService.baseUrl}/reservations/${widget.chatRoom.reservationId}');
      print('📍 [위치] 예약 정보 조회: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print('📍 [위치] 예약 정보 응답: $responseData');

        if (responseData['ok'] == true && responseData['data'] != null) {
          final reservationData = responseData['data'];
          final latitude = reservationData['service_latitude'];
          final longitude = reservationData['service_longitude'];

          if (latitude != null && longitude != null) {
            print('📍 [위치] 서비스 위치 발견: ($latitude, $longitude)');

            // Firebase에 사용자 위치 업로드
            await _locationService.updateUserLocation(
              widget.chatRoom.reservationId,
              latitude as double,
              longitude as double,
              userId: _currentUserId,
            );

            print('✅ [위치] Firebase에 서비스 위치 업로드 완료');
            print('   예약 ID: ${widget.chatRoom.reservationId}');
            print('   사용자 ID: $_currentUserId');
            print('   좌표: ($latitude, $longitude)');
          } else {
            print('⚠️ [위치] 예약 정보에 서비스 위치가 없습니다. 현재 위치를 사용합니다.');

            // 서비스 위치 정보가 없으면 현재 위치 사용
            final position = await _locationService.getCurrentLocation();
            if (position != null && mounted) {
              await _locationService.updateUserLocation(
                widget.chatRoom.reservationId,
                position.latitude,
                position.longitude,
                userId: _currentUserId,
              );
              print('✅ [위치] 현재 위치를 Firebase에 업로드 완료');
            }
          }
        } else {
          print('⚠️ [위치] 예약 정보 조회 실패: ${responseData['message']}');
        }
      } else {
        print('❌ [위치] API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [위치] 오류 발생: $e');

      // 오류 발생 시 현재 위치 사용
      try {
        final position = await _locationService.getCurrentLocation();
        if (position != null && mounted) {
          await _locationService.updateUserLocation(
            widget.chatRoom.reservationId,
            position.latitude,
            position.longitude,
            userId: _currentUserId,
          );
          print('✅ [위치] 오류 복구: 현재 위치 사용');
        }
      } catch (e2) {
        print('❌ [위치] 현재 위치도 가져오기 실패: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 240),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          foregroundColor: const Color.fromARGB(255, 0, 108, 82),
          elevation: 0,
        ),
        body: Column(
          children: [
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const TabBar(
                labelColor: Color.fromARGB(255, 0, 108, 82),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color.fromARGB(255, 0, 108, 82),
                tabs: [
                  Tab(text: '채팅방'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      // 지도 뷰 (CHECKED_IN 상태일 때만 표시)
                      if (_showMap && (_sitterLocation != null || _userLocation != null))
                        _buildMapView()
                      else if (_currentReservationStatus == 'CHECKED_IN' &&
                          widget.chatRoom.serviceType == 'SITTER')
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentUserType == 'PARTNER'
                                      ? '고객의 위치 정보를 기다리는 중...'
                                      : '펫시터의 위치 정보를 기다리는 중...',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 메시지 목록
                      Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.getMessagesStream(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('오류: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      '메시지가 없습니다.\n첫 메시지를 보내보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 메시지 로드 후 스크롤 및 읽음 처리
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                  // 실시간으로 읽음 처리
                  _chatService.markMessagesAsRead(
                    widget.chatRoom.id,
                    _currentUserType,
                  );
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = _currentUserId != null &&
                        message.senderId == _currentUserId;

                    return _buildMessageBubble(message, isMine);
                  },
                );
              },
            ),
          ),

          // 1단계: 예약 확정 버튼 (WAITING → CONFIRMED)
          if (_currentUserType == 'PARTNER' &&
              widget.chatRoom.serviceType == 'SITTER' &&
              _currentReservationStatus == 'WAITING')
            _buildConfirmReservationButton(),

          // 2단계: 의뢰 수락 버튼 (CONFIRMED → CHECKED_IN)
          if (_currentUserType == 'PARTNER' &&
              widget.chatRoom.serviceType == 'SITTER' &&
              _currentReservationStatus == 'CONFIRMED')
            _buildAcceptWorkButton(),

          // 3단계: 작업 완료 버튼 (CHECKED_IN → COMPLETED)
          if (_currentUserType == 'PARTNER' &&
              widget.chatRoom.serviceType == 'SITTER' &&
              _currentReservationStatus == 'CHECKED_IN')
            _buildCompleteWorkButton(),

          // 메시지 입력 영역
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  // 텍스트 입력 필드
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 전송 버튼
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            // 상대방 프로필 이미지
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.chatRoom.partnerImageUrl != null
                  ? NetworkImage(widget.chatRoom.partnerImageUrl!)
                  : null,
              child: widget.chatRoom.partnerImageUrl == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // 메시지 내용
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFF4CAF50) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isMine && !message.isRead) ...[
                      const SizedBox(width: 4),
                      Text(
                        '1',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 오늘: 시간만 표시
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // 어제
      return '어제 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // 일주일 이내: 요일 표시
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[dateTime.weekday - 1];
      return '$weekday요일 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      // 그 외: 전체 날짜
      return DateFormat('M월 d일 HH:mm').format(dateTime);
    }
  }

  /// 지도 뷰 위젯
  Widget _buildMapView() {
    // 펫시터는 사용자 위치를, 사용자는 펫시터 위치를 봄
    final targetLocation = _currentUserType == 'PARTNER'
        ? _userLocation
        : _sitterLocation;

    if (targetLocation == null) return const SizedBox.shrink();

    final targetLat = targetLocation['latitude'] as double;
    final targetLng = targetLocation['longitude'] as double;

    // 두 위치가 모두 있으면 중간 지점을 중심으로 설정
    double centerLat = targetLat;
    double centerLng = targetLng;

    if (_sitterLocation != null && _userLocation != null) {
      final sitterLat = _sitterLocation!['latitude'] as double;
      final sitterLng = _sitterLocation!['longitude'] as double;
      final userLat = _userLocation!['latitude'] as double;
      final userLng = _userLocation!['longitude'] as double;

      // 중간 지점 계산
      centerLat = (sitterLat + userLat) / 2;
      centerLng = (sitterLng + userLng) / 2;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 지도 헤더 (항상 표시)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: _isMapExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    )
                  : BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isMapExpanded = !_isMapExpanded;
                  });
                },
                borderRadius: _isMapExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '실시간 위치 추적',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_sitterLocation != null && _userLocation != null)
                        Text(
                          _calculateDistance(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isMapExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 지도 영역 (펼쳤을 때만 표시)
          if (_isMapExpanded)
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    KakaoMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _updateMapMarkers();
                      },
                      center: LatLng(centerLat, centerLng),
                      markers: _buildMarkers(),
                      polylines: _buildPolylines(),
                    ),
            // 위치 정보 표시
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          children: [
                            const TextSpan(
                              text: '🔵 펫시터',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            const TextSpan(text: ' ↔ '),
                            const TextSpan(
                              text: '🔴 고객',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5252),
                              ),
                            ),
                            if (targetLocation['timestamp'] != null)
                              TextSpan(
                                text: ' · ${_getTimeAgo(targetLocation['timestamp'] as int)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 거리 정보 표시 (두 위치가 모두 있을 때만)
            if (_sitterLocation != null && _userLocation != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.straighten,
                        color: Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _calculateDistance(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 줌 컨트롤 버튼 (우측 상단)
            Positioned(
              top: 60,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 줌 인 버튼
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                  // 구분선
                  Container(
                    width: 36,
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  // 줌 아웃 버튼
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 20,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 경로 토글 버튼 (줌 버튼 아래)
            if (_sitterLocation != null && _userLocation != null)
              Positioned(
                top: 145,
                right: 12,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: _showRoute
                      ? const Color(0xFF2196F3)
                      : Colors.white,
                  onPressed: _isLoadingRoute ? null : _toggleRoute,
                  child: _isLoadingRoute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4CAF50),
                          ),
                        )
                      : Icon(
                          _showRoute ? Icons.route : Icons.add_road,
                          color: _showRoute
                              ? Colors.white
                              : const Color(0xFF4CAF50),
                          size: 20,
                        ),
                ),
              ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 카카오 내비게이션 열기
  Future<void> _openNavigation(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'kakaomap://route?ep=$lat,$lng&by=CAR',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // 카카오맵 앱이 없으면 웹으로 열기
        final webUrl = Uri.parse(
          'https://map.kakao.com/link/to/목적지,$lat,$lng',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('⚠️ 네비게이션 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네비게이션을 실행할 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 지도 마커 생성
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    print('📍 [마커] 마커 생성 중 - sitter: ${_sitterLocation != null}, user: ${_userLocation != null}');

    // 펫시터 위치 마커 (파란색 핀으로 표시)
    if (_sitterLocation != null) {
      final sitterLat = _sitterLocation!['latitude'] as double;
      final sitterLng = _sitterLocation!['longitude'] as double;
      print('🔵 [마커] 펫시터 마커 추가: ($sitterLat, $sitterLng)');

      markers.add(
        Marker(
          markerId: 'sitter',
          latLng: LatLng(sitterLat, sitterLng),
          width: 30,
          height: 44,
          infoWindowContent: '🔵 펫시터',
        ),
      );
    }

    // 사용자(고객) 위치 마커 (빨간색 핀으로 표시)
    if (_userLocation != null) {
      final userLat = _userLocation!['latitude'] as double;
      final userLng = _userLocation!['longitude'] as double;
      print('🔴 [마커] 고객 마커 추가: ($userLat, $userLng)');

      markers.add(
        Marker(
          markerId: 'user',
          latLng: LatLng(userLat, userLng),
          width: 30,
          height: 44,
          infoWindowContent: '🔴 고객',
        ),
      );
    }

    print('✅ [마커] 총 ${markers.length}개 마커 생성됨');
    return markers;
  }

  /// 줌 인
  Future<void> _zoomIn() async {
    if (_mapController != null) {
      final currentLevel = await _mapController!.getLevel();
      final newLevel = (currentLevel - 1).clamp(1, 14);
      await _mapController!.setLevel(newLevel);
      print('🔍 [지도] 줌 인: 레벨 $currentLevel → $newLevel');
    }
  }

  /// 줌 아웃
  Future<void> _zoomOut() async {
    if (_mapController != null) {
      final currentLevel = await _mapController!.getLevel();
      final newLevel = (currentLevel + 1).clamp(1, 14);
      await _mapController!.setLevel(newLevel);
      print('🔍 [지도] 줌 아웃: 레벨 $currentLevel → $newLevel');
    }
  }

  /// 경로 표시 토글
  void _toggleRoute() {
    if (_showRoute) {
      // 경로 숨기기
      setState(() {
        _showRoute = false;
      });
    } else {
      // 경로 로드 및 표시
      _loadRoute();
    }
  }

  /// 실제 도로 경로 로드
  Future<void> _loadRoute() async {
    if (_sitterLocation == null || _userLocation == null) {
      print('⚠️ [경로] 위치 정보 부족 - sitter: ${_sitterLocation != null}, user: ${_userLocation != null}');
      return;
    }

    // 이미 로딩 중이면 중복 호출 방지
    if (_isLoadingRoute) {
      print('⚠️ [경로] 이미 로딩 중...');
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final sitterLat = _sitterLocation!['latitude'] as double;
      final sitterLng = _sitterLocation!['longitude'] as double;
      final userLat = _userLocation!['latitude'] as double;
      final userLng = _userLocation!['longitude'] as double;

      print('🗺️ [경로] 경로 로딩 시작: ($sitterLat, $sitterLng) → ($userLat, $userLng)');

      final routePoints = await _routeService.getRoute(
        startLat: sitterLat,
        startLng: sitterLng,
        endLat: userLat,
        endLng: userLng,
      );

      if (routePoints.isNotEmpty && mounted) {
        setState(() {
          _routePoints = routePoints;
          _showRoute = true;
          _isLoadingRoute = false;
        });
        print('✅ [경로] 경로 로딩 완료: ${routePoints.length}개 포인트');
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
        print('⚠️ [경로] 경로를 찾을 수 없음');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
      print('❌ [경로] 로딩 실패: $e');
    }
  }

  /// 두 위치를 연결하는 폴리라인 생성
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // 실제 경로가 있으면 경로 표시, 없으면 직선 표시
    if (_showRoute && _routePoints.isNotEmpty) {
      // 실제 도로 경로 표시 (파란색)
      polylines.add(
        Polyline(
          polylineId: 'route',
          points: _routePoints,
          strokeColor: const Color(0xFF2196F3), // 파란색 경로
          strokeWidth: 5,
          strokeOpacity: 0.9,
        ),
      );
    } else if (_sitterLocation != null && _userLocation != null) {
      // 직선 거리 표시 (녹색 점선)
      polylines.add(
        Polyline(
          polylineId: 'straight_line',
          points: [
            LatLng(
              _sitterLocation!['latitude'] as double,
              _sitterLocation!['longitude'] as double,
            ),
            LatLng(
              _userLocation!['latitude'] as double,
              _userLocation!['longitude'] as double,
            ),
          ],
          strokeColor: const Color(0xFF4CAF50), // 녹색 직선
          strokeWidth: 3,
          strokeOpacity: 0.6,
        ),
      );
    }

    return polylines;
  }

  /// 두 위치 사이의 직선 거리 계산 (km 단위)
  String _calculateDistance() {
    if (_sitterLocation == null || _userLocation == null) {
      return '';
    }

    final sitterLat = _sitterLocation!['latitude'] as double;
    final sitterLng = _sitterLocation!['longitude'] as double;
    final userLat = _userLocation!['latitude'] as double;
    final userLng = _userLocation!['longitude'] as double;

    // Haversine formula로 거리 계산
    const double earthRadius = 6371; // km
    final dLat = _toRadians(userLat - sitterLat);
    final dLng = _toRadians(userLng - sitterLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(sitterLat)) *
            cos(_toRadians(userLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * asin(sqrt(a));
    final distance = earthRadius * c;

    if (distance < 1) {
      // 1km 미만이면 미터로 표시
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      // 1km 이상이면 km로 표시
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  /// 각도를 라디안으로 변환
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// 지도 마커 업데이트
  void _updateMapMarkers() {
    // 지도가 생성되면 자동으로 마커가 표시됨
    // setState를 호출하면 KakaoMap 위젯이 다시 빌드되어 markers가 업데이트됨
    if (_sitterLocation != null) {
      setState(() {
        // 상태 업데이트로 지도 재렌더링
      });
    }
  }

  /// 시간 경과 표시 (예: "방금 전", "3분 전")
  String _getTimeAgo(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final seconds = diff ~/ 1000;

    if (seconds < 60) {
      return '방금 전';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}분 전';
    } else if (seconds < 86400) {
      return '${seconds ~/ 3600}시간 전';
    } else {
      return '${seconds ~/ 86400}일 전';
    }
  }

  /// 1단계: 예약 확정 버튼 (WAITING → CONFIRMED)
  /// 파트너가 예약을 수락하고 채팅방을 활성화
  Widget _buildConfirmReservationButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ElevatedButton(
        onPressed: _confirmReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 22),
            SizedBox(width: 8),
            Text(
              '예약 확정 (채팅 시작)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2단계: 의뢰 수락 버튼 (CONFIRMED → CHECKED_IN)
  /// 사용자가 요청한 실제 일을 받아들이고 작업 시작
  Widget _buildAcceptWorkButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ElevatedButton(
        onPressed: _acceptWork,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 22),
            SizedBox(width: 8),
            Text(
              '의뢰 수락 (작업 시작)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3단계: 작업 완료 버튼 (CHECKED_IN → COMPLETED)
  /// 작업을 완료하고 예약을 종료
  Widget _buildCompleteWorkButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ElevatedButton(
        onPressed: _completeWork,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 22),
            SizedBox(width: 8),
            Text(
              '작업 완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 예약 확정 처리 (WAITING → CONFIRMED)
  Future<void> _confirmReservation() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '예약 확정',
            style: TextStyle(
              color: Color(0xFF2D3E3F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('이 예약을 확정하고 채팅을 시작하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '확정',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 파트너 ID 가져오기
      final partners = await _partnerService.getMyPartners(_currentUserId!);
      if (partners.isEmpty || partners.first.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파트너 정보를 찾을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final partnerId = partners.first.id!;

      // 백엔드 API 호출하여 예약 확정 처리 (WAITING → CONFIRMED)
      final success = await _reservationService.acceptReservation(
        widget.chatRoom.reservationId,
        partnerId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 확정되었습니다. 사용자와 채팅을 시작할 수 있습니다.'),
            backgroundColor: Color(0xFF2196F3),
            duration: Duration(seconds: 2),
          ),
        );

        // 상태 업데이트 (WAITING → CONFIRMED)
        setState(() {
          _currentReservationStatus = 'CONFIRMED';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 확정에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 확정 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 의뢰 수락 처리 (CONFIRMED → CHECKED_IN)
  Future<void> _acceptWork() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '의뢰 수락',
            style: TextStyle(
              color: Color(0xFF2D3E3F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('사용자가 요청한 작업을 수락하고 시작하시겠습니까?\n\n위치 추적이 시작됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '수락',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 파트너 ID 가져오기
      final partners = await _partnerService.getMyPartners(_currentUserId!);
      if (partners.isEmpty || partners.first.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파트너 정보를 찾을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final partnerId = partners.first.id!;

      // 백엔드 API 호출하여 작업 수락 처리 (CONFIRMED → CHECKED_IN)
      final success = await _reservationService.checkinReservation(
        widget.chatRoom.reservationId,
        partnerId,
      );

      if (!mounted) return;

      if (success) {
        // 위치 추적 시작 (펫시터만)
        if (widget.chatRoom.serviceType == 'SITTER') {
          try {
            await _locationService.startTracking(
              widget.chatRoom.reservationId,
              _currentUserId!,
            );
            print('📍 위치 추적 시작됨');
          } catch (e) {
            print('⚠️ 위치 추적 시작 실패: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('위치 추적 시작 실패: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('의뢰를 수락했습니다. 위치 추적이 시작되었습니다.'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Firebase에 예약 상태 업데이트 (실시간 동기화)
        try {
          final database = FirebaseDatabase.instance.ref();
          await database
              .child('chat_rooms')
              .child(widget.chatRoom.id.toString())
              .update({
            'reservationStatus': 'CHECKED_IN',
          });
          print('✅ Firebase 예약 상태 업데이트: CHECKED_IN');
        } catch (e) {
          print('⚠️ Firebase 상태 업데이트 실패: $e');
        }

        // 채팅방에서 나가지 않고 상태만 업데이트 (CONFIRMED → CHECKED_IN)
        setState(() {
          _currentReservationStatus = 'CHECKED_IN';
        });

        // 위치 추적 스트림 다시 시작
        await _checkAndStartLocationTracking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('의뢰 수락에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('의뢰 수락 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 작업 완료 처리 (CHECKED_IN → COMPLETED)
  Future<void> _completeWork() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '작업 완료',
            style: TextStyle(
              color: Color(0xFF2D3E3F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('작업을 완료하시겠습니까?\n\n위치 추적이 중지됩니다.\n완료 후 예약 관리에서 확인할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '완료',
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 파트너 ID 가져오기
      final partners = await _partnerService.getMyPartners(_currentUserId!);
      if (partners.isEmpty || partners.first.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파트너 정보를 찾을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final partnerId = partners.first.id!;

      // 위치 추적 중지 (펫시터만)
      if (widget.chatRoom.serviceType == 'SITTER') {
        try {
          await _locationService.stopTracking();
          print('🛑 위치 추적 중지됨');
        } catch (e) {
          print('⚠️ 위치 추적 중지 실패: $e');
        }
      }

      // 백엔드 API 호출하여 작업 완료 처리 (CHECKED_IN → COMPLETED)
      final success = await _reservationService.completeReservation(
        widget.chatRoom.reservationId,
        partnerId,
      );

      if (!mounted) return;

      if (success) {
        // Firebase에 예약 상태 업데이트 (실시간 동기화)
        try {
          final database = FirebaseDatabase.instance.ref();
          await database
              .child('chat_rooms')
              .child(widget.chatRoom.id.toString())
              .update({
            'reservationStatus': 'COMPLETED',
          });
          print('✅ Firebase 예약 상태 업데이트: COMPLETED');
        } catch (e) {
          print('⚠️ Firebase 상태 업데이트 실패: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업이 완료되었습니다. 위치 추적이 중지되었습니다.'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 2),
          ),
        );

        // 상태 업데이트 후 채팅방 목록으로 돌아가기 (CHECKED_IN → COMPLETED)
        setState(() {
          _currentReservationStatus = 'COMPLETED';
          _showMap = false;
        });

        // 잠시 후 채팅방 목록으로 이동
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업 완료 처리에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('작업 완료 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

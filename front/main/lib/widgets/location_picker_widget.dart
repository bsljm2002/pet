import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 지도에서 위치를 선택하는 위젯
class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late KakaoMapController _mapController;
  late double _selectedLatitude;
  late double _selectedLongitude;
  late TextEditingController _addressController;
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // 카카오 REST API 키
  static const String _kakaoRestApiKey = '98410bbff71e2c7f4f484d57b5679579';

  // 기본 위치: 서울 중심
  static const double _defaultLatitude = 37.5665;
  static const double _defaultLongitude = 126.9780;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude ?? _defaultLatitude;
    _selectedLongitude = widget.initialLongitude ?? _defaultLongitude;
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _searchController = TextEditingController();

    // 초기 주소가 있고 좌표가 없으면 자동 검색
    if (widget.initialAddress != null &&
        widget.initialAddress!.isNotEmpty &&
        widget.initialLatitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchAddress(widget.initialAddress!);
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 주소 검색
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    print('=== 주소 검색 시작: $query ===');

    try {
      // 키워드 검색 시도
      final keywordUrl = 'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}';
      print('키워드 검색 URL: $keywordUrl');

      final keywordResponse = await http.get(
        Uri.parse(keywordUrl),
        headers: {
          'Authorization': 'KakaoAK $_kakaoRestApiKey',
        },
      );

      print('키워드 검색 응답 코드: ${keywordResponse.statusCode}');
      print('키워드 검색 응답 본문: ${keywordResponse.body}');

      if (keywordResponse.statusCode == 200) {
        final data = json.decode(keywordResponse.body);
        final documents = data['documents'] as List;

        print('키워드 검색 결과 수: ${documents.length}');

        if (documents.isEmpty) {
          print('키워드 검색 결과 없음, 주소 검색 시도...');

          // 키워드 검색 결과가 없으면 주소 검색 시도
          final addressUrl = 'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(query)}';
          print('주소 검색 URL: $addressUrl');

          final addressResponse = await http.get(
            Uri.parse(addressUrl),
            headers: {
              'Authorization': 'KakaoAK $_kakaoRestApiKey',
            },
          );

          print('주소 검색 응답 코드: ${addressResponse.statusCode}');
          print('주소 검색 응답 본문: ${addressResponse.body}');

          if (addressResponse.statusCode == 200) {
            final addressData = json.decode(addressResponse.body);
            final addressDocuments = addressData['documents'] as List;

            print('주소 검색 결과 수: ${addressDocuments.length}');

            if (addressDocuments.isEmpty) {
              setState(() {
                _searchResults = [];
                _isSearching = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('검색 결과가 없습니다')),
                );
              }
            } else {
              final results = addressDocuments.map((doc) {
                return {
                  'address': doc['address_name'] ?? doc['road_address_name'] ?? '',
                  'latitude': double.parse(doc['y'] ?? '0'),
                  'longitude': double.parse(doc['x'] ?? '0'),
                };
              }).toList();

              setState(() {
                _searchResults = results;
                _isSearching = false;
              });
              print('주소 검색 결과 설정 완료');

              // 초기 주소 검색인 경우 첫 번째 결과 자동 선택
              if (widget.initialAddress != null &&
                  widget.initialAddress!.isNotEmpty &&
                  results.isNotEmpty) {
                _selectSearchResult(results.first);
              }
            }
          } else {
            print('주소 검색 API 오류: ${addressResponse.statusCode}');
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('주소 검색 오류: ${addressResponse.statusCode}')),
              );
            }
          }
        } else {
          final results = documents.map((doc) {
            print('검색 결과: ${doc['place_name']}, ${doc['address_name']}');
            return {
              'address': doc['place_name'] ?? doc['address_name'] ?? '',
              'latitude': double.parse(doc['y'] ?? '0'),
              'longitude': double.parse(doc['x'] ?? '0'),
            };
          }).toList();

          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
          print('키워드 검색 결과 설정 완료: ${_searchResults.length}개');

          // 초기 주소 검색인 경우 첫 번째 결과 자동 선택
          if (widget.initialAddress != null &&
              widget.initialAddress!.isNotEmpty &&
              results.isNotEmpty) {
            _selectSearchResult(results.first);
          }
        }
      } else {
        print('검색 API 오류: ${keywordResponse.statusCode}');
        print('응답 헤더: ${keywordResponse.headers}');
        print('응답 본문: ${keywordResponse.body}');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('검색 오류 (${keywordResponse.statusCode}): API 키를 확인해주세요')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('주소 검색 예외 발생: $e');
      print('스택 트레이스: $stackTrace');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주소 검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 검색 결과 선택
  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    setState(() {
      _selectedLatitude = result['latitude'];
      _selectedLongitude = result['longitude'];
      _addressController.text = result['address'];
      _searchResults = [];
      _searchController.clear();
    });

    // 지도 이동
    try {
      await _mapController.setCenter(LatLng(_selectedLatitude, _selectedLongitude));
      // 줌 레벨도 적절하게 설정
      await _mapController.setLevel(3);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['address']}로 이동했습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4FC59E),
          ),
        );
      }
    } catch (e) {
      print('지도 이동 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지도 이동 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 지도 중앙 위치로 좌표 업데이트
  Future<void> _updateMarkerToCenter() async {
    try {
      final center = await _mapController.getCenter();
      setState(() {
        _selectedLatitude = center.latitude;
        _selectedLongitude = center.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '위치 선택됨: ${_selectedLatitude.toStringAsFixed(6)}, ${_selectedLongitude.toStringAsFixed(6)}',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4FC59E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 선택 오류: $e')),
        );
      }
    }
  }

  /// 현재 위치 확인
  void _confirmLocation() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소를 먼저 입력해주세요')),
      );
      return;
    }

    widget.onLocationSelected(
      _selectedLatitude,
      _selectedLongitude,
      _addressController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 및 주소 입력 영역
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 주소 검색창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: '주소 검색',
                          hintText: '예: 강남역',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          _searchAddress(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching
                          ? null
                          : () {
                              if (_searchController.text.isNotEmpty) {
                                _searchAddress(_searchController.text);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC59E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('검색'),
                    ),
                  ],
                ),

                // 검색 결과 목록
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFF4FC59E),
                          ),
                          title: Text(
                            result['address'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // 선택된 주소 표시
                const Text(
                  '선택된 주소',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4FC59E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '선택된 위치: ${_selectedLatitude.toStringAsFixed(6)}, ${_selectedLongitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF003829),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 지도
          Expanded(
            child: Stack(
              children: [
                // 카카오 지도
                KakaoMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  center: LatLng(_selectedLatitude, _selectedLongitude),
                ),

                // 중앙 마커 (고정)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: const Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.red,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 위치 선택 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateMarkerToCenter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC59E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.location_on),
                    label: const Text(
                      '이 위치로 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF4FC59E),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '지도를 이동한 후 "이 위치로 선택" 버튼을 누르세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
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
    );
  }
}

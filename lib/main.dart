import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Sensor App',
      theme: ThemeData(
        primaryColor: Color(0xFF007200),
        primarySwatch: MaterialColor(0xFF007200, {
          50: Color(0xFF007200).withOpacity(0.1),
          100: Color(0xFF007200).withOpacity(0.2),
          200: Color(0xFF007200).withOpacity(0.3),
          300: Color(0xFF007200).withOpacity(0.4),
          400: Color(0xFF007200).withOpacity(0.5),
          500: Color(0xFF007200).withOpacity(0.6),
          600: Color(0xFF007200).withOpacity(0.7),
          700: Color(0xFF007200).withOpacity(0.8),
          800: Color(0xFF007200).withOpacity(0.9),
          900: Color(0xFF007200),
        }),
      ),
      home: DataScreen(),
    );
  }
}

class DataModel {
  final int suhumax;
  final int suhumin;
  final double suhurata;
  final List<NilaiSuhu> nilaiSuhuMaxHumidMax;
  final List<MonthYear> monthYearMax;

  DataModel({
    required this.suhumax,
    required this.suhumin,
    required this.suhurata,
    required this.nilaiSuhuMaxHumidMax,
    required this.monthYearMax,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    var listNilaiSuhu = json['nilai_suhu_max_humid_max'] as List;
    var listMonthYear = json['month_year_max'] as List;

    return DataModel(
      suhumax: json['suhumax'],
      suhumin: json['suhumin'],
      suhurata: double.parse(json['suhurata'].toString()),
      nilaiSuhuMaxHumidMax:
          listNilaiSuhu.map((i) => NilaiSuhu.fromJson(i)).toList(),
      monthYearMax: listMonthYear.map((i) => MonthYear.fromJson(i)).toList(),
    );
  }
}

class NilaiSuhu {
  final int idx;
  final int suhu;
  final int humid;
  final int kecerahan;
  final String timestamp;

  NilaiSuhu({
    required this.idx,
    required this.suhu,
    required this.humid,
    required this.kecerahan,
    required this.timestamp,
  });

  factory NilaiSuhu.fromJson(Map<String, dynamic> json) {
    return NilaiSuhu(
      idx: json['idx'],
      suhu: json['suhu'],
      humid: json['humid'],
      kecerahan: json['kecerahan'],
      timestamp: json['timestamp'],
    );
  }
}

class MonthYear {
  final String monthYear;

  MonthYear({required this.monthYear});

  factory MonthYear.fromJson(Map<String, dynamic> json) {
    return MonthYear(
      monthYear: json['month_year'],
    );
  }
}

class DataService {
  final String baseUrl = 'http://10.0.2.2:3000/data';

  Future<DataModel> fetchData() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return DataModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final DataService dataService = DataService();
  Timer? _timer;
  late Stream<DataModel> _dataStream;

  @override
  void initState() {
    super.initState();
    // Membuat stream untuk data realtime
    _dataStream = Stream.periodic(Duration(seconds: 5))
        .asyncMap((_) => dataService.fetchData());

    // Memulai pembaruan data otomatis
    _startDataRefresh();
  }

  void _startDataRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('UAS UTS IOT', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF007200),
        elevation: 0,
      ),
      backgroundColor: Color(0xFF004b23).withOpacity(0.05),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<DataModel>(
          stream: _dataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Terjadi Kesalahan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${snapshot.error}'.contains('SocketException')
                            ? 'Tidak dapat terhubung ke server.\nPastikan server sedang berjalan dan dapat diakses.'
                            : '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700], fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              var data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan Suhu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 39, 128, 25),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSuhuInfo('Suhu Max', '${data.suhumax}°C',
                                    Colors.red),
                                _buildSuhuInfo('Suhu Min', '${data.suhumin}°C',
                                    Colors.blue),
                                _buildSuhuInfo('Suhu Rata',
                                    '${data.suhurata}°C', Colors.green),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Detail Pengukuran',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 142, 142, 142),
                      ),
                    ),
                    SizedBox(height: 8),
                    ...data.nilaiSuhuMaxHumidMax.map((nilai) => Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: ${nilai.idx}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      nilai.timestamp,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMeasurement('Suhu', '${nilai.suhu}°C',
                                        Icons.thermostat),
                                    _buildMeasurement('Kelembaban',
                                        '${nilai.humid}%', Icons.water_drop),
                                    _buildMeasurement('Kecerahan',
                                        '${nilai.kecerahan}', Icons.wb_sunny),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                    SizedBox(height: 16),
                    Text(
                      'Periode Waktu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 132, 131, 131),
                      ),
                    ),
                    SizedBox(height: 8),
                    ...data.monthYearMax.map((monthYear) => Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.calendar_month,
                                color: const Color.fromARGB(255, 7, 104, 46)),
                            title: Text(
                              monthYear.monthYear,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }
            return Center(child: Text('Tidak ada data tersedia'));
          },
        ),
      ),
    );
  }

  Widget _buildSuhuInfo(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF006400),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurement(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF007200).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF006400), size: 28),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF004b23),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007200),
            ),
          ),
        ],
      ),
    );
  }
}

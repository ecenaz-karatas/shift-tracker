import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ManagerAnalyticsPage extends StatefulWidget {
  @override
  _ManagerAnalyticsPageState createState() => _ManagerAnalyticsPageState();
}

class _ManagerAnalyticsPageState extends State<ManagerAnalyticsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String selectedPeriod = 'week'; // 'today', 'week', 'month', 'all'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advanced Analytics"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Period Selector Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  "Performance Insights",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'today',
                      label: Text('Today'),
                      icon: Icon(Icons.today, size: 16),
                    ),
                    ButtonSegment(
                      value: 'week',
                      label: Text('Week'),
                      icon: Icon(Icons.date_range, size: 16),
                    ),
                    ButtonSegment(
                      value: 'month',
                      label: Text('Month'),
                      icon: Icon(Icons.calendar_month, size: 16),
                    ),
                    ButtonSegment(
                      value: 'all',
                      label: Text('All'),
                      icon: Icon(Icons.all_inclusive, size: 16),
                    ),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() {
                      selectedPeriod = selected.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return Colors.white.withOpacity(0.2);
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.deepPurple;
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Analytics Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildShiftsQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading data"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No shift data available",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate advanced analytics
                var shifts = snapshot.data!.docs;
                var analytics = _calculateAdvancedAnalytics(shifts);

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // Top Performers (Normalized)
                    _buildSectionHeader("Top Performers (Normalized)", Icons.emoji_events),
                    SizedBox(height: 8),
                    Text(
                      "Performance adjusted for location and weather conditions",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 12),
                    _buildNormalizedPerformers(analytics),

                    SizedBox(height: 24),

                    // Sales Performance by Location
                    _buildSectionHeader("Location Performance", Icons.location_on),
                    SizedBox(height: 12),
                    _buildLocationPerformance(analytics),

                    SizedBox(height: 24),

                    // Weather Impact Analysis
                    _buildSectionHeader("Weather Impact", Icons.wb_sunny),
                    SizedBox(height: 12),
                    _buildWeatherAnalysis(analytics),

                    SizedBox(height: 24),

                    // Efficiency Metrics
                    _buildSectionHeader("Efficiency Metrics", Icons.speed),
                    SizedBox(height: 12),
                    _buildEfficiencyMetrics(analytics),

                    SizedBox(height: 24),

                    // Consistency Scores
                    _buildSectionHeader("Worker Consistency", Icons.timeline),
                    SizedBox(height: 12),
                    _buildConsistencyScores(analytics),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build query based on selected period
  Stream<QuerySnapshot> _buildShiftsQuery() {
    Query query = firestore.collection('shifts').orderBy('savedDate', descending: true);

    DateTime now = DateTime.now();
    DateTime? startDate;

    if (selectedPeriod == 'today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (selectedPeriod == 'week') {
      startDate = now.subtract(Duration(days: 7));
    } else if (selectedPeriod == 'month') {
      startDate = now.subtract(Duration(days: 30));
    }

    if (startDate != null) {
      query = query.where('savedDate', isGreaterThan: Timestamp.fromDate(startDate));
    }

    return query.snapshots();
  }

  // Calculate advanced analytics with normalization
  Map<String, dynamic> _calculateAdvancedAnalytics(List<QueryDocumentSnapshot> shifts) {
    // Raw data
    Map<String, List<double>> workerSalesByShift = {};
    Map<String, List<double>> workerCupsByShift = {};
    Map<String, List<double>> workerEfficiency = {}; // cups per hour
    Map<String, int> workerShiftCount = {};
    Map<String, double> workerTotalSales = {};
    Map<String, double> workerTotalHours = {};

    // Location averages (for normalization)
    Map<String, List<double>> locationSales = {};
    Map<String, List<double>> locationCups = {};

    // Weather data
    Map<String, List<double>> weatherSales = {}; // weather condition -> sales
    Map<String, int> weatherShiftCount = {};

    for (var doc in shifts) {
      var data = doc.data() as Map<String, dynamic>;

      if (data['savedDate'] == null) continue;

      // Calculate sales
      int cashCups = int.tryParse(data['cashCups']?.toString() ?? '0') ?? 0;
      int ccCups = int.tryParse(data['ccCups']?.toString() ?? '0') ?? 0;
      double sale = cashCups * 7 + ccCups * 7.27;
      int cups = cashCups + ccCups;
      double hours = (data['totalHours'] ?? 0.0).toDouble();

      String worker = data['name'] ?? 'Unknown';
      String location = data['location'] ?? 'Unknown';
      String? weather = data['weatherConditionStart'] ?? data['weatherConditionEnd'];

      // Worker data
      if (!workerSalesByShift.containsKey(worker)) {
        workerSalesByShift[worker] = [];
        workerCupsByShift[worker] = [];
        workerEfficiency[worker] = [];
        workerShiftCount[worker] = 0;
        workerTotalSales[worker] = 0;
        workerTotalHours[worker] = 0;
      }

      workerSalesByShift[worker]!.add(sale);
      workerCupsByShift[worker]!.add(cups.toDouble());
      if (hours > 0) {
        workerEfficiency[worker]!.add(cups / hours);
      }
      workerShiftCount[worker] = workerShiftCount[worker]! + 1;
      workerTotalSales[worker] = workerTotalSales[worker]! + sale;
      workerTotalHours[worker] = workerTotalHours[worker]! + hours;

      // Location data
      if (!locationSales.containsKey(location)) {
        locationSales[location] = [];
        locationCups[location] = [];
      }
      locationSales[location]!.add(sale);
      locationCups[location]!.add(cups.toDouble());

      // Weather data
      if (weather != null) {
        if (!weatherSales.containsKey(weather)) {
          weatherSales[weather] = [];
          weatherShiftCount[weather] = 0;
        }
        weatherSales[weather]!.add(sale);
        weatherShiftCount[weather] = weatherShiftCount[weather]! + 1;
      }
    }

    // Calculate location averages
    Map<String, double> locationAvgSales = {};
    for (var entry in locationSales.entries) {
      locationAvgSales[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Calculate weather averages
    Map<String, double> weatherAvgSales = {};
    for (var entry in weatherSales.entries) {
      weatherAvgSales[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Calculate normalized performance scores
    Map<String, double> normalizedScores = {};
    for (var worker in workerSalesByShift.keys) {
      if (workerSalesByShift[worker]!.isEmpty) continue;

      // Get average sales per shift for this worker
      double avgSales = workerSalesByShift[worker]!.reduce((a, b) => a + b) / workerSalesByShift[worker]!.length;

      // Calculate consistency (lower standard deviation = more consistent)
      double consistency = _calculateStandardDeviation(workerSalesByShift[worker]!);
      double consistencyScore = consistency > 0 ? 100 / (1 + consistency / 50) : 100;

      // Calculate efficiency score
      double avgEfficiency = workerEfficiency[worker]!.isNotEmpty
          ? workerEfficiency[worker]!.reduce((a, b) => a + b) / workerEfficiency[worker]!.length
          : 0;

      // Normalized score: combines sales, efficiency, and consistency
      double score = (avgSales / 10) + (avgEfficiency * 5) + (consistencyScore / 5);
      normalizedScores[worker] = score;
    }

    // Sort by normalized score
    var topPerformers = normalizedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate consistency scores separately
    Map<String, double> consistencyScores = {};
    for (var worker in workerSalesByShift.keys) {
      if (workerSalesByShift[worker]!.length < 2) {
        consistencyScores[worker] = 0;
        continue;
      }
      double stdDev = _calculateStandardDeviation(workerSalesByShift[worker]!);
      double avgSales = workerSalesByShift[worker]!.reduce((a, b) => a + b) / workerSalesByShift[worker]!.length;
      // Coefficient of variation (lower is more consistent)
      double cv = avgSales > 0 ? (stdDev / avgSales) * 100 : 0;
      // Convert to score where 100 is perfect consistency
      consistencyScores[worker] = cv > 0 ? (100 / (1 + cv / 20)).clamp(0, 100) : 0;
    }

    var topConsistent = consistencyScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'topPerformers': topPerformers,
      'workerSalesByShift': workerSalesByShift,
      'workerShiftCount': workerShiftCount,
      'workerTotalSales': workerTotalSales,
      'workerTotalHours': workerTotalHours,
      'workerEfficiency': workerEfficiency,
      'locationAvgSales': locationAvgSales,
      'locationSales': locationSales,
      'weatherAvgSales': weatherAvgSales,
      'weatherShiftCount': weatherShiftCount,
      'consistencyScores': topConsistent,
    };
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return variance > 0 ? sqrt(variance) : 0;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
      ],
    );
  }

  Widget _buildNormalizedPerformers(Map<String, dynamic> analytics) {
    List<MapEntry> topPerformers = analytics['topPerformers'];
    Map<String, int> workerShiftCount = analytics['workerShiftCount'];
    Map<String, double> workerTotalSales = analytics['workerTotalSales'];
    Map<String, List<double>> workerEfficiency = analytics['workerEfficiency'];

    if (topPerformers.isEmpty) {
      return _emptyState("No performance data available");
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: topPerformers.take(5).map((entry) {
            String worker = entry.key;
            double score = entry.value;
            int shifts = workerShiftCount[worker] ?? 0;
            double totalSales = workerTotalSales[worker] ?? 0;
            double avgSales = shifts > 0 ? totalSales / shifts : 0;

            List<double> efficiencyList = workerEfficiency[worker] ?? [];
            double avgEfficiency = efficiencyList.isNotEmpty
                ? efficiencyList.reduce((a, b) => a + b) / efficiencyList.length
                : 0;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.05),
                    Colors.deepPurple.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            worker[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "$shifts shifts",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              score.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricChip(
                          icon: Icons.attach_money,
                          label: "Avg Sale",
                          value: "\$${avgSales.toStringAsFixed(0)}",
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _metricChip(
                          icon: Icons.speed,
                          label: "Cups/Hr",
                          value: avgEfficiency.toStringAsFixed(1),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLocationPerformance(Map<String, dynamic> analytics) {
    Map<String, double> locationAvgSales = analytics['locationAvgSales'];
    Map<String, List<double>> locationSales = analytics['locationSales'];

    if (locationAvgSales.isEmpty) {
      return _emptyState("No location data available");
    }

    var sortedLocations = locationAvgSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: sortedLocations.map((entry) {
            String location = entry.key;
            double avgSales = entry.value;
            int shifts = locationSales[location]?.length ?? 0;
            double totalSales = locationSales[location]?.reduce((a, b) => a + b) ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.deepPurple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            location,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "\$${avgSales.toStringAsFixed(0)}/shift",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (avgSales / (sortedLocations.first.value == 0 ? 1 : sortedLocations.first.value)).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "$shifts shifts",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (sortedLocations.indexOf(entry) < sortedLocations.length - 1)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Divider(height: 1),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeatherAnalysis(Map<String, dynamic> analytics) {
    Map<String, double> weatherAvgSales = analytics['weatherAvgSales'];
    Map<String, int> weatherShiftCount = analytics['weatherShiftCount'];

    if (weatherAvgSales.isEmpty) {
      return _emptyState("No weather data available");
    }

    var sortedWeather = weatherAvgSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Weather icons and colors
    Map<String, IconData> weatherIcons = {
      'Clear': Icons.wb_sunny,
      'Clouds': Icons.cloud,
      'Rain': Icons.water_drop,
      'Drizzle': Icons.grain,
      'Thunderstorm': Icons.thunderstorm,
      'Snow': Icons.ac_unit,
      'Mist': Icons.blur_on,
      'Fog': Icons.blur_on,
    };

    Map<String, Color> weatherColors = {
      'Clear': Colors.orange,
      'Clouds': Colors.grey,
      'Rain': Colors.blue,
      'Drizzle': Colors.lightBlue,
      'Thunderstorm': Colors.deepPurple,
      'Snow': Colors.cyan,
      'Mist': Colors.blueGrey,
      'Fog': Colors.blueGrey,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: sortedWeather.map((entry) {
            String weather = entry.key;
            double avgSales = entry.value;
            int shifts = weatherShiftCount[weather] ?? 0;

            IconData icon = weatherIcons[weather] ?? Icons.wb_cloudy;
            Color color = weatherColors[weather] ?? Colors.grey;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "$shifts shifts",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${avgSales.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        "avg/shift",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetrics(Map<String, dynamic> analytics) {
    Map<String, List<double>> workerEfficiency = analytics['workerEfficiency'];
    Map<String, int> workerShiftCount = analytics['workerShiftCount'];

    if (workerEfficiency.isEmpty) {
      return _emptyState("No efficiency data available");
    }

    // Calculate average efficiency for each worker
    Map<String, double> avgEfficiency = {};
    for (var entry in workerEfficiency.entries) {
      if (entry.value.isNotEmpty) {
        avgEfficiency[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    var sortedEfficiency = avgEfficiency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cups Served Per Hour",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            ...sortedEfficiency.take(5).map((entry) {
              String worker = entry.key;
              double efficiency = entry.value;
              int shifts = workerShiftCount[worker] ?? 0;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 18,
                      child: Text(
                        worker[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "$shifts shifts",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_cafe, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "${efficiency.toStringAsFixed(1)}/hr",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyScores(Map<String, dynamic> analytics) {
    List<MapEntry> topConsistent = analytics['consistencyScores'];
    Map<String, int> workerShiftCount = analytics['workerShiftCount'];

    if (topConsistent.isEmpty) {
      return _emptyState("No consistency data available");
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Most reliable and predictable performance",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            ...topConsistent.take(5).map((entry) {
              String worker = entry.key;
              double consistency = entry.value;
              int shifts = workerShiftCount[worker] ?? 0;

              if (shifts < 2) return SizedBox.shrink();

              Color scoreColor = consistency >= 80
                  ? Colors.green
                  : consistency >= 60
                  ? Colors.orange
                  : Colors.red;

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scoreColor.withOpacity(0.2),
                      radius: 18,
                      child: Text(
                        worker[0].toUpperCase(),
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "$shifts shifts",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: consistency / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${consistency.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class SavedDataPage extends StatefulWidget {
  const SavedDataPage({super.key});

  @override
  SavedDataPageState createState() => SavedDataPageState();
}

class SavedDataPageState extends State<SavedDataPage> {
  late Future<List<double>> _savedData;
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchSavedData();
  }

  void _fetchSavedData() {
    debugPrint("Fetching saved data...");
    setState(() {
      _savedData =
          DatabaseHelper().fetchPredictedPHValues().catchError((error) {
        debugPrint("Error fetching data: $error");
        return <double>[];
      });
    });
  }

  Future<void> _clearDatabase() async {
    bool confirmDelete = await _showDeleteConfirmation();
    if (!confirmDelete || !mounted) return;

    await DatabaseHelper().clearDatabase();
    if (!mounted) return;
    _fetchSavedData();
    debugPrint("Data saved and fetched successfully");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All saved data cleared!")),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content:
                  const Text("Are you sure you want to delete all saved data?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _exportToExcel() async {
    List<double> data = await DatabaseHelper().fetchPredictedPHValues();
    if (data.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available for export.")),
      );
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];

    final List<String> headers = ['Entry', 'Predicted pH'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
      double predictedPH = data[rowIndex];
      sheet.getRangeByIndex(rowIndex + 2, 1).setText((rowIndex + 1).toString());
      sheet.getRangeByIndex(rowIndex + 2, 2).setText(predictedPH.toString());
    }

    RenderRepaintBoundary boundary =
        _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List imageBytes = byteData!.buffer.asUint8List();

    final xlsio.Picture picture = sheet.pictures.addStream(6, 1, imageBytes);
    picture.height = 300;
    picture.width = 600;

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = "${directory.path}/Predicted_PH_Values.xlsx";
    final File file = File(filePath);
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel file with graph saved at: $filePath")),
    );

    Share.shareXFiles([XFile(filePath)],
        text: "Here are the predicted pH values with the graph.");
  }

  List<FlSpot> computeTrendLine(List<double> data) {
    int n = data.length;
    if (n == 0) return [];

    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    List<FlSpot> trendSpots = [];
    for (int i = 0; i < n; i++) {
      trendSpots.add(FlSpot(i.toDouble(), slope * i + intercept));
    }
    return trendSpots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Predicted pH Values")),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<double>>(
              future: _savedData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.isEmpty) {
                  return const Center(child: Text("No saved data yet"));
                }

                List<double> data = snapshot.data!;
                debugPrint("Graph Data: $data");

                List<ScatterSpot> scatterSpots =
                    data.asMap().entries.map((entry) {
                  return ScatterSpot(entry.key.toDouble() + 1, entry.value);
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 1,
                        maxX: data.isNotEmpty ? data.length.toDouble() : 1,
                        minY: 5,
                        maxY: 11,
                        lineBarsData: [
                          LineChartBarData(
                            spots: scatterSpots
                                .map((spot) => FlSpot(spot.x, spot.y))
                                .toList(),
                            isCurved: false,
                            color: Colors.blue,
                            barWidth: 4,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<double>>(
              future: _savedData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No saved data yet"));
                }

                List<double> data = snapshot.data!;

                final List<String> headers = ['Entry', 'Predicted pH'];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 12,
                            border:
                                TableBorder.all(width: 1.0, color: Colors.grey),
                            columns: headers.map((header) {
                              return DataColumn(
                                  label: Text(header,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)));
                            }).toList(),
                            rows: data.asMap().entries.map((entry) {
                              int index = entry.key + 1;
                              double predictedPH = entry.value;

                              return DataRow(
                                cells: [
                                  DataCell(Text(index.toString())),
                                  DataCell(Text(predictedPH.toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Clear All Data"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _clearDatabase,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text("Export"),
                  onPressed: _exportToExcel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

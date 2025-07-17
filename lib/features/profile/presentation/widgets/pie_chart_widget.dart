import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatefulWidget {
  const PieChartWidget({super.key});

  @override
  State<StatefulWidget> createState() => PieChartWidgetState();
}

class PieChartWidgetState extends State {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 28,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Indicator(
                color: Colors.blue,
                text: 'Toyota',
                isSquare: false,
                size: touchedIndex == 0 ? 18 : 16,
                textColor: touchedIndex == 0 ? Colors.blue : Colors.grey.shade600,
              ),
              Indicator(
                color: Colors.amber,
                text: 'Honda',
                isSquare: false,
                size: touchedIndex == 1 ? 18 : 16,
                textColor: touchedIndex == 1 ? Colors.amber : Colors.grey.shade600,
              ),
              Indicator(
                color: Colors.pink,
                text: 'Suzuki',
                isSquare: false,
                size: touchedIndex == 2 ? 18 : 16,
                textColor: touchedIndex == 2 ? Colors.pink : Colors.grey.shade600,
              ),
              Indicator(
                color: Colors.green,
                text: 'Audi',
                isSquare: false,
                size: touchedIndex == 3 ? 18 : 16,
                textColor: touchedIndex == 3 ? Colors.green : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  startDegreeOffset: 180,
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      4,
      (i) {
        final isTouched = i == touchedIndex;
        const color0 = Colors.blue;
        const color1 = Colors.amber;
        const color2 = Colors.pink;
        const color3 = Colors.green;

        switch (i) {
          case 0:
            return PieChartSectionData(
              color: color0,
              value: 25,
              title: 'Toyota',
              radius: 80,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? BorderSide(color: Colors.grey.shade200, width: 6)
                  : BorderSide(color: AppColors.contentColorWhite.withOpacity(0)),
            );
          case 1:
            return PieChartSectionData(
              color: color1,
              value: 25,
              title: 'Honda',
              radius: 65,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? BorderSide(color: Colors.grey.shade200, width: 6)
                  : BorderSide(color: AppColors.contentColorWhite.withOpacity(0)),
            );
          case 2:
            return PieChartSectionData(
              color: color2,
              value: 25,
              title: 'Suzuki',
              radius: 60,
              titlePositionPercentageOffset: 0.6,
              borderSide: isTouched
                  ? BorderSide(color: Colors.grey.shade200, width: 6)
                  : BorderSide(color: AppColors.contentColorWhite.withOpacity(0)),
            );
          case 3:
            return PieChartSectionData(
              color: color3,
              value: 25,
              title: 'Audi',
              radius: 70,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? BorderSide(color: Colors.grey.shade200, width: 6)
                  : BorderSide(color: AppColors.contentColorWhite.withOpacity(0)),
            );
          default:
            throw Error();
        }
      },
    );
  }
}

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}

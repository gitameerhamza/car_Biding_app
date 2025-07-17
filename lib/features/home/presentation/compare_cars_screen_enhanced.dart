import 'package:cached_network_image/cached_network_image.dart';
import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class EnhancedCompareCarsScreen extends StatefulWidget {
  final List<CarModel> cars;
  const EnhancedCompareCarsScreen({super.key, required this.cars});

  @override
  State<EnhancedCompareCarsScreen> createState() => _EnhancedCompareCarsScreenState();
}

class _EnhancedCompareCarsScreenState extends State<EnhancedCompareCarsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'Compare Cars (${widget.cars.length})',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareComparison,
            icon: const Icon(Icons.share, color: Colors.purple),
          ),
          IconButton(
            onPressed: _saveComparison,
            icon: const Icon(Icons.bookmark_border, color: Colors.purple),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.visibility, size: 20)),
            Tab(text: 'Details', icon: Icon(Icons.info, size: 20)),
            Tab(text: 'Charts', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'Pros & Cons', icon: Icon(Icons.compare_arrows, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDetailsTab(),
          _buildChartsTab(),
          _buildProsConsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Car Images Carousel
          _buildImageCarousel(),
          const SizedBox(height: 20),
          
          // Quick Comparison Cards
          _buildQuickComparisonCards(),
          const SizedBox(height: 20),
          
          // Key Specifications
          _buildKeySpecifications(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: widget.cars.length,
        itemBuilder: (context, index) {
          final car = widget.cars[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: car.imgURLs.isNotEmpty ? car.imgURLs.first : '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.car_rental, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${NumberFormat('#,###').format(car.price)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickComparisonCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Best Price',
            widget.cars.reduce((a, b) => a.price < b.price ? a : b).name,
            '\$${NumberFormat('#,###').format(widget.cars.map((e) => e.price).reduce((a, b) => a < b ? a : b))}',
            Colors.green,
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Newest',
            widget.cars.reduce((a, b) => a.year > b.year ? a : b).name,
            '${widget.cars.map((e) => e.year).reduce((a, b) => a > b ? a : b)}',
            Colors.blue,
            Icons.new_releases,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String carName, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            carName,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeySpecifications() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            children: [
              _buildTableHeader(),
              _buildTableRow('Price', widget.cars.map((car) => '\$${NumberFormat('#,###').format(car.price)}').toList()),
              _buildTableRow('Year', widget.cars.map((car) => car.year.toString()).toList()),
              _buildTableRow('Make', widget.cars.map((car) => car.make).toList()),
              _buildTableRow('Fuel Type', widget.cars.map((car) => car.fuelType).toList()),
              _buildTableRow('Mileage', widget.cars.map((car) => '${car.mileage} mpg').toList()),
              _buildTableRow('Condition', widget.cars.map((car) => car.condition).toList()),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.purple.shade50),
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Specification',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...widget.cars.map((car) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            car.name.length > 15 ? '${car.name.substring(0, 15)}...' : car.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        )),
      ],
    );
  }

  TableRow _buildTableRow(String label, List<String> values) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        ...values.map((value) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            textAlign: TextAlign.center,
          ),
        )),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.cars.map((car) => _buildDetailedCarCard(car)).toList(),
      ),
    );
  }

  Widget _buildDetailedCarCard(CarModel car) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            car.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Price', '\$${NumberFormat('#,###').format(car.price)}'),
              ),
              Expanded(
                child: _buildDetailItem('Year', car.year.toString()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Make', car.make),
              ),
              Expanded(
                child: _buildDetailItem('Fuel Type', car.fuelType),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Mileage', '${car.mileage} mpg'),
              ),
              Expanded(
                child: _buildDetailItem('Condition', car.condition),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailItem('Location', car.location),
          const SizedBox(height: 8),
          _buildDetailItem('Description', car.descripton),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPriceChart(),
          const SizedBox(height: 20),
          _buildYearChart(),
          const SizedBox(height: 20),
          _buildMileageChart(),
        ],
      ),
    );
  }

  Widget _buildPriceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: widget.cars.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.price.toDouble(),
                        color: Colors.purple,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < widget.cars.length) {
                          return Text(
                            widget.cars[value.toInt()].name.substring(0, 
                              widget.cars[value.toInt()].name.length > 8 ? 8 : widget.cars[value.toInt()].name.length),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Year Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: widget.cars.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.year.toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < widget.cars.length) {
                          return Text(
                            widget.cars[value.toInt()].name.substring(0, 
                              widget.cars[value.toInt()].name.length > 8 ? 8 : widget.cars[value.toInt()].name.length),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMileageChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mileage Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: widget.cars.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.mileage.toDouble(),
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < widget.cars.length) {
                          return Text(
                            widget.cars[value.toInt()].name.substring(0, 
                              widget.cars[value.toInt()].name.length > 8 ? 8 : widget.cars[value.toInt()].name.length),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} mpg',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.cars.map((car) => _buildProsConsCard(car)).toList(),
      ),
    );
  }

  Widget _buildProsConsCard(CarModel car) {
    final pros = _generatePros(car);
    final cons = _generateCons(car);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            car.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_up, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Pros',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...pros.map((pro) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pro,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_down, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Cons',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...cons.map((con) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.close, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              con,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _generatePros(CarModel car) {
    List<String> pros = [];
    
    // Compare with other cars to find relative advantages
    final otherCars = widget.cars.where((c) => c.id != car.id).toList();
    
    if (otherCars.isNotEmpty) {
      final avgPrice = otherCars.map((c) => c.price).reduce((a, b) => a + b) / otherCars.length;
      final avgYear = otherCars.map((c) => c.year).reduce((a, b) => a + b) / otherCars.length;
      final avgMileage = otherCars.map((c) => c.mileage).reduce((a, b) => a + b) / otherCars.length;
      
      if (car.price < avgPrice) {
        pros.add('More affordable than average');
      }
      if (car.year > avgYear) {
        pros.add('Newer than average');
      }
      if (car.mileage > avgMileage) {
        pros.add('Better fuel economy');
      }
    }
    
    // General pros based on car specifications
    if (car.condition.toLowerCase() == 'excellent') {
      pros.add('Excellent condition');
    }
    if (car.fuelType.toLowerCase() == 'hybrid' || car.fuelType.toLowerCase() == 'electric') {
      pros.add('Eco-friendly fuel type');
    }
    if (car.year >= DateTime.now().year - 3) {
      pros.add('Very recent model');
    }
    if (car.mileage > 25) {
      pros.add('Good fuel efficiency');
    }
    
    return pros.isEmpty ? ['Well-maintained vehicle'] : pros;
  }

  List<String> _generateCons(CarModel car) {
    List<String> cons = [];
    
    // Compare with other cars to find relative disadvantages
    final otherCars = widget.cars.where((c) => c.id != car.id).toList();
    
    if (otherCars.isNotEmpty) {
      final avgPrice = otherCars.map((c) => c.price).reduce((a, b) => a + b) / otherCars.length;
      final avgYear = otherCars.map((c) => c.year).reduce((a, b) => a + b) / otherCars.length;
      final avgMileage = otherCars.map((c) => c.mileage).reduce((a, b) => a + b) / otherCars.length;
      
      if (car.price > avgPrice) {
        cons.add('Higher priced than average');
      }
      if (car.year < avgYear) {
        cons.add('Older than average');
      }
      if (car.mileage < avgMileage) {
        cons.add('Lower fuel economy');
      }
    }
    
    // General cons based on car specifications
    if (car.condition.toLowerCase() == 'poor' || car.condition.toLowerCase() == 'fair') {
      cons.add('Condition needs improvement');
    }
    if (car.year < DateTime.now().year - 10) {
      cons.add('Older vehicle');
    }
    if (car.mileage < 20) {
      cons.add('Lower fuel efficiency');
    }
    
    return cons.isEmpty ? ['Limited comparison data'] : cons;
  }

  void _shareComparison() {
    // Generate comparison summary text
    String comparisonText = 'Car Comparison Summary:\n\n';
    
    for (int i = 0; i < widget.cars.length; i++) {
      final car = widget.cars[i];
      comparisonText += '${i + 1}. ${car.name}\n';
      comparisonText += '   Price: \$${NumberFormat('#,###').format(car.price)}\n';
      comparisonText += '   Year: ${car.year}\n';
      comparisonText += '   Make: ${car.make}\n';
      comparisonText += '   Mileage: ${car.mileage} mpg\n';
      comparisonText += '   Condition: ${car.condition}\n\n';
    }
    
    // Use share functionality (you'll need to add share_plus package)
    // Share.share(comparisonText);
    
    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: comparisonText));
    Get.snackbar(
      'Copied!',
      'Comparison data copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _saveComparison() {
    // This would save the comparison to user's saved comparisons
    // For now, just show a success message
    Get.snackbar(
      'Saved!',
      'Comparison saved to your favorites',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

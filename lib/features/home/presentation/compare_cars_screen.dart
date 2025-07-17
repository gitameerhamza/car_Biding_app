import 'package:cached_network_image/cached_network_image.dart';
import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:flutter/material.dart';

class CompareCarsScreen extends StatelessWidget {
  final List<CarModel> cars;
  const CompareCarsScreen({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text('Cars Comparison'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12.0),
          Row(
            children: [
              const SizedBox(width: 12.0),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CachedNetworkImage(
                      imageUrl: cars.first.imgURLs.first,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CachedNetworkImage(
                      imageUrl: cars.last.imgURLs.first,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
            ],
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey),
              children: [
                TableRow(
                  children: [
                    const SizedBox(),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.name,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.name,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Year",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.year.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.year.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Condition",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.condition,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.condition,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Fuel Type",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.fuelType,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.fuelType,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Mileage",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.mileage.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.mileage.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Make",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.make,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.make,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Price",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.price.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.price.toString(),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Location",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.location,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.location,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          "Status",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.first.status,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Text(
                          cars.last.status,
                          style: const TextStyle(fontSize: 16.0),
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

import 'package:cbazaar/features/profile/controllers/edit_profile_controller.dart';
import 'package:cbazaar/features/profile/presentation/widgets/bar_chart_widget.dart';
import 'package:cbazaar/features/profile/presentation/widgets/line_chart_widget.dart';
import 'package:cbazaar/features/profile/presentation/widgets/pie_chart_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          title: const Text('Edit Profile'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          children: [
            const SizedBox(height: 12.0),
            const Text('Name'),
            const SizedBox(height: 4.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: GetBuilder<EditProfileController>(
                init: EditProfileController(),
                builder: (_) {
                  return TextField(
                    controller: _.nameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: _.newName ?? 'Full Name',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),
            const Text('Email'),
            const SizedBox(height: 4.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: GetBuilder<EditProfileController>(
                builder: (_) {
                  return TextField(
                    controller: _.emailController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      hintText: _.newEmail ?? 'email@test.com',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
            Material(
              type: MaterialType.transparency,
              child: GetBuilder<EditProfileController>(
                init: EditProfileController(),
                builder: (_) {
                  return InkWell(
                    onTap: _.updateData,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.blue.shade700,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Car Price Trends',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const AspectRatio(
              aspectRatio: 1.25,
              child: LineChartWidget(
                isShowingMainData: false,
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Car Brand Market Share',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const AspectRatio(
              aspectRatio: 1.25,
              child: PieChartWidget(),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Car Sales Chart',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            AspectRatio(
              aspectRatio: 1.25,
              child: BarChartWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

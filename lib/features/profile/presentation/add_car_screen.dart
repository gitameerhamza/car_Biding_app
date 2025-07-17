import 'package:cbazaar/features/profile/controllers/add_car_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCarScreen extends StatelessWidget {
  const AddCarScreen({super.key});

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          title: const Text('Add Car'),
        ),
        body: GetBuilder<AddCarController>(
            init: AddCarController(),
            builder: (_) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: [
                  const SizedBox(height: 12.0),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: _buildDropdownField(
                      label: 'Make',
                      value: _.selectedMake,
                      items: _.carMakes,
                      onChanged: _.setMake,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  TextField(
                    controller: _.modelController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Model',
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  _buildDropdownField(
                    label: 'Year',
                    value: _.selectedYear,
                    items: _.years,
                    onChanged: _.setYear,
                  ),
                  const SizedBox(height: 1.0),
                  TextField(
                    controller: _.mileageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Mileage (km)',
                      suffixText: 'km',
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  TextField(
                    controller: _.priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Price',
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  _buildDropdownField(
                    label: 'Condition',
                    value: _.selectedCondition,
                    items: _.conditions,
                    onChanged: _.setCondition,
                  ),
                  const SizedBox(height: 1.0),
                  _buildDropdownField(
                    label: 'Fuel Type',
                    value: _.selectedFuelType,
                    items: _.fuelTypes,
                    onChanged: _.setFuelType,
                  ),
                  const SizedBox(height: 1.0),
                  _buildDropdownField(
                    label: 'Transmission',
                    value: _.selectedTransmission,
                    items: _.transmissionTypes,
                    onChanged: _.setTransmission,
                  ),
                  const SizedBox(height: 1.0),
                  _buildDropdownField(
                    label: 'Color',
                    value: _.selectedColor,
                    items: _.colors,
                    onChanged: _.setColor,
                  ),
                  const SizedBox(height: 1.0),
                  TextField(
                    controller: _.locationController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Location',
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  TextField(
                    controller: _.contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Contact Phone',
                      prefixIcon: Icon(Icons.phone, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12.0)),
                    child: TextField(
                      controller: _.descriptionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: _.carImage.length,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        if (index + 1 == _.carImage.length) {
                          return Column(
                            children: [
                              const SizedBox(height: 12.0),
                              InkWell(
                                onTap: () => _.addImage(index),
                                borderRadius: BorderRadius.circular(12.0),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _.carImage[index] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12.0),
                                          child: Image.file(
                                            _.carImage[index]!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Ink(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.image,
                                                  color: Colors.grey.shade700,
                                                  size: 48.0,
                                                ),
                                                const Text('Add Image'),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              InkWell(
                                onTap: _.carImage.last == null ? null : _.addAnotherImage,
                                borderRadius: BorderRadius.circular(24.0),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24.0),
                                    color: Colors.grey.shade300,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded),
                                      SizedBox(width: 8.0),
                                      Text('Add another Image'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: InkWell(
                            onTap: () => _.addImage(index),
                            borderRadius: BorderRadius.circular(12.0),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _.carImage[index] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.file(
                                        _.carImage[index]!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Ink(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              color: Colors.grey.shade700,
                                              size: 48.0,
                                            ),
                                            const Text('Add Image'),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                  const SizedBox(height: 12.0),
                  const Divider(),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: Checkbox(
                          value: _.biddingEnabled,
                          onChanged: _.toggleBidding,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Allow Bidding'),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  if (_.biddingEnabled)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Set bidding amounts'),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: TextField(
                                  controller: _.minBidController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    labelText: 'Min Bid',
                                    prefixText: '\$ ',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: TextField(
                                  controller: _.maxBidController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    labelText: 'Max Bid',
                                    prefixText: '\$ ',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Set bidding duration (in Days)'),
                            ),
                            const SizedBox(width: 12.0),
                            Flexible(
                              fit: FlexFit.loose,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: TextField(
                                  controller: _.bidDaysController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: '7',
                                    suffixText: 'days',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24.0),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: _.postAd,
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
                              'Submit',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom + 12.0,
                  ),
                ],
              );
            }),
      ),
    );
  }
}

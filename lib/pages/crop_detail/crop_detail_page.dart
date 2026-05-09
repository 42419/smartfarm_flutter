import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../models/crop.dart';
import '../../widgets/common/section_card.dart' as common;
import 'widgets/crop_sections.dart';

class CropDetailPage extends StatelessWidget {
  const CropDetailPage({
    super.key,
    required this.crop,
    required this.greenhouseIndex,
  });

  final Crop crop;
  final int greenhouseIndex;

  @override
  Widget build(BuildContext context) {
    final info = getDetailHealthInfo(context, crop.health);
    final isLarge = Responsive.isLargeScreen(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          '${greenhouseIndex + 1}号大棚 - ${crop.cropName}',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: isLarge
            ? _buildDesktopContent(context, info)
            : _buildMobileContent(context, info),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, DetailHealthInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CropHeader(crop: crop, info: info),
        const SizedBox(height: 16),
        _buildBasicInfo(),
        const SizedBox(height: 16),
        GrowthSection(crop: crop, info: info),
        const SizedBox(height: 16),
        EnvironmentSection(crop: crop, info: info),
        const SizedBox(height: 16),
        TasksSection(crop: crop),
        const SizedBox(height: 16),
        RecommendationsSection(crop: crop),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context, DetailHealthInfo info) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              CropHeader(crop: crop, info: info),
              const SizedBox(height: 16),
              _buildBasicInfo(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              GrowthSection(crop: crop, info: info),
              const SizedBox(height: 16),
              EnvironmentSection(crop: crop, info: info),
              const SizedBox(height: 16),
              TasksSection(crop: crop),
              const SizedBox(height: 16),
              RecommendationsSection(crop: crop),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return common.SectionCard(
      title: '基本信息',
      child: Column(
        children: [
          InfoRow(label: '种植日期', value: _formatDate(crop.plantDate)),
          _buildDivider(),
          InfoRow(label: '预计收获', value: _formatDate(crop.harvestDate)),
          _buildDivider(),
          InfoRow(label: '种植面积', value: '${crop.area.toStringAsFixed(1)} 亩'),
          _buildDivider(),
          InfoRow(label: '植株高度', value: crop.height ?? '--'),
          _buildDivider(),
          InfoRow(label: '叶片光强', value: crop.leafCount ?? '--'),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--';
    return dateStr;
  }
}

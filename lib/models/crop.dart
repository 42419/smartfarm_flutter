class Crop {
  const Crop({
    required this.cropName,
    this.plantDate,
    this.harvestDate,
    required this.area,
    required this.current,
    required this.total,
    this.height,
    this.leafCount,
    this.health,
    this.yieldText,
    this.environmentAnalysis1,
    this.environmentAnalysis2,
    this.environmentAnalysis3,
    this.environmentAnalysis4,
    this.environmentAnalysis5,
    this.desc1,
    this.recommendation1,
    this.desc2,
    this.recommendation2,
    this.cropImg,
    this.taskTime1,
    this.taskTime2,
    this.summary,
  });

  final String cropName;
  final String? plantDate;
  final String? harvestDate;
  final double area;
  final int current;
  final int total;
  final String? height;
  final String? leafCount;
  final String? health;
  final String? yieldText;
  final int? environmentAnalysis1;
  final int? environmentAnalysis2;
  final int? environmentAnalysis3;
  final int? environmentAnalysis4;
  final int? environmentAnalysis5;
  final String? desc1;
  final String? recommendation1;
  final String? desc2;
  final String? recommendation2;
  final String? cropImg;
  final String? taskTime1;
  final String? taskTime2;
  final String? summary;

  factory Crop.fromSupabase(Map<String, dynamic> row) {
    return Crop(
      cropName: row['crop_name']?.toString() ?? '',
      plantDate: row['plant_date']?.toString(),
      harvestDate: row['harvest_date']?.toString(),
      area: (row['area'] as num?)?.toDouble() ?? 0,
      current: (row['current'] as num?)?.toInt() ?? 0,
      total: (row['total'] as num?)?.toInt() ?? 0,
      height: row['height']?.toString(),
      leafCount: row['leaf_count']?.toString(),
      health: row['health']?.toString(),
      yieldText: row['yield_text']?.toString(),
      environmentAnalysis1: (row['environment_analysis_1'] as num?)?.toInt(),
      environmentAnalysis2: (row['environment_analysis_2'] as num?)?.toInt(),
      environmentAnalysis3: (row['environment_analysis_3'] as num?)?.toInt(),
      environmentAnalysis4: (row['environment_analysis_4'] as num?)?.toInt(),
      environmentAnalysis5: (row['environment_analysis_5'] as num?)?.toInt(),
      desc1: row['desc_1']?.toString(),
      recommendation1: row['recommendation_1']?.toString(),
      desc2: row['desc_2']?.toString(),
      recommendation2: row['recommendation_2']?.toString(),
      cropImg: row['crop_img']?.toString(),
      taskTime1: row['task_time_1']?.toString(),
      taskTime2: row['task_time_2']?.toString(),
      summary: row['summary']?.toString(),
    );
  }
}

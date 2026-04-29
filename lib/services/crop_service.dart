import 'package:flutter/foundation.dart';

import '../models/crop.dart';
import 'supabase_service.dart';

class CropService {
  CropService._();

  static final CropService instance = CropService._();

  Future<List<Crop>> fetchCrops() async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return const [];
    }

    try {
      final rows = await client
          .from('crops')
          .select('*')
          .order('crop_name');

      return rows.map((row) => Crop.fromSupabase(row)).toList();
    } catch (error) {
      debugPrint('CropService.fetchCrops failed: $error');
      return const [];
    }
  }
}

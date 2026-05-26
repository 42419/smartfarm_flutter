import 'package:flutter/foundation.dart';

import '../models/crop.dart';
import 'supabase_service.dart';

class CropService {
  CropService._();

  static final CropService instance = CropService._();

  List<Crop> _cachedCrops = const [];
  List<Crop> get cachedCrops => _cachedCrops;

  Future<List<Crop>> fetchCrops() async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return _cachedCrops;
    }

    try {
      final rows = await client
          .from('crops')
          .select('*')
          .order('crop_name');

      _cachedCrops = rows.map((row) => Crop.fromSupabase(row)).toList();
      return _cachedCrops;
    } catch (error) {
      debugPrint('CropService.fetchCrops failed: $error');
      return _cachedCrops;
    }
  }
}

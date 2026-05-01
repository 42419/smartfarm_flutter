import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.city,
    required this.weatherText,
    required this.weatherIcon,
    required this.weatherTemp,
    required this.weatherWind,
    required this.weatherHumidity,
    required this.accentColor,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String city;
  final String weatherText;
  final IconData weatherIcon;
  final String weatherTemp;
  final String weatherWind;
  final String weatherHumidity;
  final Color accentColor;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRefresh,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRefreshing ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(city,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isRefreshing
                      ? SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: accentColor,
                          ),
                        )
                      : Icon(weatherIcon,
                          key: ValueKey(weatherText),
                          size: 44,
                          color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  weatherTemp,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(weatherText,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.air, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(weatherWind,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(weatherHumidity,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

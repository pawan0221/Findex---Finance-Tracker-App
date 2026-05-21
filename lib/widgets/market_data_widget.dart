import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketDataWidget extends StatefulWidget {
  const MarketDataWidget({super.key});
  @override
  State<MarketDataWidget> createState() => _MarketDataWidgetState();
}

class _MarketDataWidgetState extends State<MarketDataWidget> {
  List<_MarketItem> _items = [];
  bool _loading = true;
  DateTime? _updated;

  // Static fallback data (real approximate values)
  final _fallback = [
    _MarketItem(symbol: 'USD/INR', name: 'US Dollar',    value: 83.42,  change: 0.12,  isPositive: false, emoji: '🇺🇸'),
    _MarketItem(symbol: 'EUR/INR', name: 'Euro',         value: 90.15,  change: 0.08,  isPositive: false, emoji: '🇪🇺'),
    _MarketItem(symbol: 'GBP/INR', name: 'Pound',        value: 105.60, change: 0.23,  isPositive: true,  emoji: '🇬🇧'),
    _MarketItem(symbol: 'AED/INR', name: 'UAE Dirham',   value: 22.71,  change: 0.03,  isPositive: false, emoji: '🇦🇪'),
    _MarketItem(symbol: 'GOLD',    name: 'Gold (10g)',   value: 72450,  change: 1.2,   isPositive: true,  emoji: '🥇'),
    _MarketItem(symbol: 'SILVER',  name: 'Silver (1kg)', value: 89200,  change: 0.8,   isPositive: false, emoji: '🥈'),
    _MarketItem(symbol: 'SENSEX',  name: 'BSE Sensex',  value: 73500,  change: 0.45,  isPositive: true,  emoji: '📈'),
    _MarketItem(symbol: 'NIFTY',   name: 'NSE Nifty',   value: 22350,  change: 0.38,  isPositive: true,  emoji: '📊'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/INR'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        final usdInr = 1 / (rates['USD'] as num).toDouble();
        final eurInr = 1 / (rates['EUR'] as num).toDouble();
        final gbpInr = 1 / (rates['GBP'] as num).toDouble();
        final aedInr = 1 / (rates['AED'] as num).toDouble();

        setState(() {
          _items = [
            _MarketItem(symbol: 'USD/INR', name: 'US Dollar',  value: usdInr,  change: 0.12, isPositive: false, emoji: '🇺🇸'),
            _MarketItem(symbol: 'EUR/INR', name: 'Euro',        value: eurInr,  change: 0.08, isPositive: true,  emoji: '🇪🇺'),
            _MarketItem(symbol: 'GBP/INR', name: 'Pound',       value: gbpInr,  change: 0.23, isPositive: true,  emoji: '🇬🇧'),
            _MarketItem(symbol: 'AED/INR', name: 'UAE Dirham',  value: aedInr,  change: 0.03, isPositive: false, emoji: '🇦🇪'),
            ..._fallback.sublist(4),
          ];
          _updated = DateTime.now();
          _loading = false;
        });
      } else {
        setState(() { _items = _fallback; _loading = false; });
      }
    } catch (_) {
      setState(() { _items = _fallback; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live Market', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            GestureDetector(
              onTap: _loadData,
              child: Row(children: [
                Icon(Icons.refresh_rounded, color: Colors.white38, size: 16),
                const SizedBox(width: 4),
                Text(_updated != null ? 'Updated ${_updated!.hour}:${_updated!.minute.toString().padLeft(2, '0')}' : 'Tap to refresh',
                    style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_loading)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 120, height: 80,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              ),
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2235),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(item.symbol, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
                      ]),
                      Text(
                        item.symbol.contains('SENSEX') || item.symbol.contains('NIFTY')
                            ? '₹${_fmt(item.value)}'
                            : item.symbol == 'GOLD' || item.symbol == 'SILVER'
                                ? '₹${_fmt(item.value)}'
                                : '₹${item.value.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(children: [
                        Icon(item.isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: item.isPositive ? Colors.greenAccent : Colors.redAccent, size: 16),
                        Text('${item.change.toStringAsFixed(2)}%',
                            style: GoogleFonts.poppins(
                                color: item.isPositive ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 11, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _MarketItem {
  final String symbol, name, emoji;
  final double value, change;
  final bool isPositive;
  const _MarketItem({required this.symbol, required this.name, required this.emoji,
      required this.value, required this.change, required this.isPositive});
}
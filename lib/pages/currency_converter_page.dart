import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final _amountController = TextEditingController(text: '1');
  String _from = 'INR';
  String _to   = 'USD';
  double? _result;
  double? _rate;
  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Popular currencies
  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'name': 'Indian Rupee',       'flag': '🇮🇳'},
    {'code': 'USD', 'name': 'US Dollar',           'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro',                'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound',       'flag': '🇬🇧'},
    {'code': 'JPY', 'name': 'Japanese Yen',        'flag': '🇯🇵'},
    {'code': 'AED', 'name': 'UAE Dirham',          'flag': '🇦🇪'},
    {'code': 'SGD', 'name': 'Singapore Dollar',    'flag': '🇸🇬'},
    {'code': 'AUD', 'name': 'Australian Dollar',   'flag': '🇦🇺'},
    {'code': 'CAD', 'name': 'Canadian Dollar',     'flag': '🇨🇦'},
    {'code': 'CHF', 'name': 'Swiss Franc',         'flag': '🇨🇭'},
    {'code': 'CNY', 'name': 'Chinese Yuan',        'flag': '🇨🇳'},
    {'code': 'SAR', 'name': 'Saudi Riyal',         'flag': '🇸🇦'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit',   'flag': '🇲🇾'},
    {'code': 'THB', 'name': 'Thai Baht',           'flag': '🇹🇭'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar',       'flag': '🇰🇼'},
  ];

  // Approximate static rates from INR base (fallback)
  final Map<String, double> _staticRates = {
    'INR': 1.0, 'USD': 0.012, 'EUR': 0.011, 'GBP': 0.0095,
    'JPY': 1.79, 'AED': 0.044, 'SGD': 0.016, 'AUD': 0.019,
    'CAD': 0.016, 'CHF': 0.011, 'CNY': 0.087, 'SAR': 0.045,
    'MYR': 0.056, 'THB': 0.43, 'KWD': 0.0037,
  };

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // Use free exchange rate API
      final url = 'https://api.exchangerate-api.com/v4/latest/$_from';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        _rate = (rates[_to] as num).toDouble();
        _lastUpdated = DateTime.now();
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }

    if (_rate != null) {
      setState(() {
        _result = amount * _rate!;
        _loading = false;
      });
    }
  }

  void _useFallback() {
    // Convert via INR base rates
    final fromRate = _staticRates[_from] ?? 1.0;
    final toRate   = _staticRates[_to]   ?? 1.0;
    _rate = toRate / fromRate;
    _error = 'Using approximate rates (offline)';
    _loading = false;
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to   = tmp;
      _result = null;
    });
    _convert();
  }

  String _flag(String code) =>
      _currencies.firstWhere((c) => c['code'] == code,
          orElse: () => {'flag': '🌐'})['flag']!;

  String _name(String code) =>
      _currencies.firstWhere((c) => c['code'] == code,
          orElse: () => {'name': code})['name']!;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Currency Converter',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main converter card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Amount input
                  Text('Amount', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: GoogleFonts.poppins(fontSize: 36, color: Colors.white30),
                    ),
                    onChanged: (_) => _convert(),
                  ),

                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // FROM currency
                  _CurrencySelector(
                    label: 'From',
                    selected: _from,
                    flag: _flag(_from),
                    name: _name(_from),
                    currencies: _currencies,
                    onChanged: (val) {
                      setState(() { _from = val; _result = null; });
                      _convert();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Swap button
                  GestureDetector(
                    onTap: _swap,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B6AFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF8B6AFF).withOpacity(0.4), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.swap_vert, color: Colors.white, size: 24),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TO currency
                  _CurrencySelector(
                    label: 'To',
                    selected: _to,
                    flag: _flag(_to),
                    name: _name(_to),
                    currencies: _currencies,
                    onChanged: (val) {
                      setState(() { _to = val; _result = null; });
                      _convert();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('${_flag(_from)} ${amount.toStringAsFixed(2)} ${_name(_from)}',
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('=', style: TextStyle(color: Colors.white38, fontSize: 20)),
                        const SizedBox(height: 4),
                        _loading
                            ? const CircularProgressIndicator(color: Color(0xFF8B6AFF))
                            : Text(
                                '${_flag(_to)} ${_result?.toStringAsFixed(4) ?? '—'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00E676)),
                              ),
                        const SizedBox(height: 4),
                        Text(_name(_to), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                        if (_rate != null) ...[
                          const SizedBox(height: 8),
                          Text('1 $_from = ${_rate!.toStringAsFixed(6)} $_to',
                              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(_error!, style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Quick reference rates
            Text('Quick Reference from $_from',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 12),

            ...(_currencies.where((c) => c['code'] != _from).take(6).map((c) {
              final code = c['code']!;
              final fromRate = _staticRates[_from] ?? 1.0;
              final toRate   = _staticRates[code] ?? 1.0;
              final rate     = toRate / fromRate;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2235),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(c['name']!,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                    ),
                    Text('1 $_from = ${rate.toStringAsFixed(4)} $code',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF8B6AFF), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            })),

            if (_lastUpdated != null) ...[
              const SizedBox(height: 8),
              Text(
                'Live rates • Updated ${_lastUpdated!.hour}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white24),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final String label, selected, flag, name;
  final List<Map<String, String>> currencies;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({
    required this.label,
    required this.selected,
    required this.flag,
    required this.name,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: const Color(0xFF1C2235),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _CurrencyPickerSheet(currencies: currencies, selected: selected),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                  Text('$selected • $name',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final String selected;
  const _CurrencyPickerSheet({required this.currencies, required this.selected});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.currencies
        .where((c) =>
            c['code']!.toLowerCase().contains(_search.toLowerCase()) ||
            c['name']!.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search currency...',
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final c = filtered[i];
              final isSelected = c['code'] == widget.selected;
              return ListTile(
                leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(c['code']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(c['name']!, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF8B6AFF)) : null,
                onTap: () => Navigator.pop(context, c['code']),
              );
            },
          ),
        ),
      ],
    );
  }
}
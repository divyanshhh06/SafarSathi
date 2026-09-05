import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../modelss/bus_route.dart';
import '../modelss/stop.dart';

/// Search bar for routes/stops + 1-Tap Vernacular Voice Search (FE-1 X-Factor).
class RouteSearchBar extends StatefulWidget {
  final List<BusRoute> routes;
  final List<BusStop> stops;
  final void Function(BusRoute route) onResultSelected;
  final String currentLang;
  final ValueChanged<String> onLanguageChanged;

  const RouteSearchBar({
    super.key,
    required this.routes,
    this.stops = const [],
    required this.onResultSelected,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  State<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<RouteSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  List<BusRoute> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (_) {}
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        String localeId = 'en_IN';
        if (widget.currentLang == 'pa') localeId = 'pa_IN';
        if (widget.currentLang == 'hi') localeId = 'hi_IN';

        _speech.listen(
          listenOptions: stt.SpeechListenOptions(localeId: localeId),
          onResult: (result) {

            setState(() {
              _controller.text = result.recognizedWords;
              _onChanged(result.recognizedWords);
              if (result.finalResult) {
                _isListening = false;
              }
            });
          },
        );
      } else {
        // Fallback simulated voice prompt dialog if mic is disabled/unavailable
        _showSimulatedVoiceSearchDialog();
      }
    }
  }

  void _showSimulatedVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.mic, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Vernacular Voice Search'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Speak bus stop or route name:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Bus Stand (ਮੋਗਾ)'),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.text = 'Bus Stand';
                      _onChanged('Bus Stand');
                    },
                  ),
                  ActionChip(
                    label: const Text('Bhugipura Chowk'),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.text = 'Bhugipura';
                      _onChanged('Bhugipura');
                    },
                  ),
                  ActionChip(
                    label: const Text('Dharamkot (ਧਰਮਕੋਟ)'),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.text = 'Dharamkot';
                      _onChanged('Dharamkot');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    final lower = query.toLowerCase().trim();
    final matches = widget.routes.where((route) {
      final routeName = route.getLocalizedName(widget.currentLang).toLowerCase();
      if (routeName.contains(lower) || route.id.toLowerCase().contains(lower)) {
        return true;
      }

      final stopMatch = route.stops.any((stop) {
        final stopName = stop.name.toLowerCase();
        final stopCity = stop.city.toLowerCase();
        return stopName.contains(lower) || stopCity.contains(lower);
      });

      return stopMatch;
    }).toList();

    setState(() {
      _results = matches;
      _showResults = true;
    });
  }

  String _getHintText() {
    if (widget.currentLang == 'pa') return 'ਰੂਟ ਜਾਂ ਸਟਾਪ ਖੋਜੋ (ਜਿਵੇਂ ਕਿ M1, ਬੱਸ ਸਟੈਂਡ)...';
    if (widget.currentLang == 'hi') return 'रूट या स्टॉप खोजें (जैसे M1, बस स्टैंड)...';
    return 'Search route or stop (e.g. M1, Bus Stand)...';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Language Toggle Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLangChip('en', 'English'),
            const SizedBox(width: 6),
            _buildLangChip('pa', 'ਪੰਜਾਬੀ'),
            const SizedBox(width: 6),
            _buildLangChip('hi', 'हिंदी'),
          ],
        ),
        const SizedBox(height: 6),
        // Search Input Bar
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
                  // 1-Tap Voice Search Mic Button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListening ? Colors.redAccent : Colors.indigo,
                    ),
                    tooltip: 'Voice Search (Punjabi / Hindi / English)',
                    onPressed: _toggleListening,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
          ),
        ),
        if (_showResults && _results.isNotEmpty)
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (context, index) => const Divider(height: 1),

                itemBuilder: (context, index) {
                  final route = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Text(
                        route.id,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      route.getLocalizedName(widget.currentLang),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${route.stops.length} stops'),
                    onTap: () {
                      _controller.text = route.getLocalizedName(widget.currentLang);
                      setState(() => _showResults = false);
                      FocusScope.of(context).unfocus();
                      widget.onResultSelected(route);
                    },
                  );
                },
              ),
            ),
          ),
        if (_showResults && _results.isEmpty)
          const Material(
            elevation: 4,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No routes or stops found', textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _buildLangChip(String code, String label) {
    final isSelected = widget.currentLang == code;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.indigo,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.indigo,
      backgroundColor: Colors.white,
      elevation: 2,
      onSelected: (selected) {
        if (selected) widget.onLanguageChanged(code);
      },
    );
  }
}

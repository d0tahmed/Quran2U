import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dua.dart';
import '../data/hisnul_muslim_db.dart';
import '../ui_v2/app_colors.dart';

const _kGold = AppColorsV2.tertiary;

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = HisnulMuslimDb.duas.map((d) => d.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  List<Dua> get _filteredDuas {
    List<Dua> filtered = HisnulMuslimDb.duas;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((d) => d.category == _selectedCategory).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((d) {
        return d.title.toLowerCase().contains(query) ||
               d.category.toLowerCase().contains(query) ||
               d.englishTranslation.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      // Fix 2: Give AppBar a solid background so scrolled content doesn't
      // bleed through and tint the title green.
      appBar: AppBar(
        backgroundColor: AppColorsV2.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: Text(
          'Hisnul Muslim',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Fix 2: Wrap the sticky header in a Container with the same
          // solid background so it never becomes see-through when scrolled.
          Container(
            color: AppColorsV2.bg,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search duas...',
                    hintStyle: GoogleFonts.manrope(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColorsV2.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 10),
                // Fix 1: Category Dropdown with menuMaxHeight so the overlay
                // list doesn't overflow the screen and bleed behind content.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColorsV2.surfaceLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      // Limit the dropdown height so it fits within the screen
                      // and does NOT bleed through background content.
                      menuMaxHeight: MediaQuery.of(context).size.height * 0.55,
                      dropdownColor: AppColorsV2.surfaceHigh,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                      items: _categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thin separator between sticky header and list
          const Divider(height: 1, thickness: 1, color: Color(0x12FFFFFF)),

          // Duas List
          Expanded(
            child: _filteredDuas.isEmpty
                ? Center(
                    child: Text(
                      'No duas found.',
                      style: GoogleFonts.manrope(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: _filteredDuas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final dua = _filteredDuas[index];
                      return _DuaCard(dua: dua);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;

  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dua.category,
                    style: GoogleFonts.manrope(
                      color: _kGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dua.title,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Arabic Text
          SizedBox(
            width: double.infinity,
            child: Text(
              dua.arabic,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: GoogleFonts.amiri().fontFamily,
                color: Colors.white,
                fontSize: 26,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transliteration
          Text(
            dua.transliteration,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          // English Translation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.g_translate_rounded, color: Colors.white30, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dua.englishTranslation,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Urdu Translation
          if (dua.urduTranslation.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.translate_rounded, color: Colors.white30, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dua.urduTranslation,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.notoNastaliqUrdu(
                      color: Colors.white,
                      fontSize: 15,
                      height: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Reference
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              dua.reference,
              style: GoogleFonts.manrope(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

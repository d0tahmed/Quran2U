import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dua.dart';
import '../data/hisnul_muslim_db.dart';
import '../ui_v2/app_colors.dart';

const _kGreen = AppColorsV2.primary;
const _kGold  = AppColorsV2.tertiary;
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories {
    final categories = HisnulMuslimDb.duas.map((d) => d.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  List<Dua> get _filteredDuas {
    if (_selectedCategory == 'All') return HisnulMuslimDb.duas;
    return HisnulMuslimDb.duas.where((d) => d.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.manrope(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _kGreen,
                    backgroundColor: AppColorsV2.surfaceLow,
                    side: BorderSide.none,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Duas List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
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

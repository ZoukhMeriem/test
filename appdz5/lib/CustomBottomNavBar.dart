import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const LinearGradient backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFA3BED8), // bleu-gris moyen clair
    Color(0xFFD1D9E6), // gris bleu clair
    Color(0xFFF0F4F8), // blanc cassé très clair
  ],
);

const Color primaryColor = Color(0xFF7986CB); // Indigo moyen (tu peux changer si tu veux une couleur assortie)
const Color cardColor = Colors.white;         // Fond des champs de texte
const Color textColor = Colors.black87;       // Texte principal
const Color subtitleColor = Colors.grey;      // Texte secondaire

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final List<IconData> icons = [Icons.home, Icons.person, Icons.chat];
    final List<String> labels = [
      loc.home,
      loc.account,
      loc.chat,
    ];

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    double getPosition() {
      if (!isRTL) {
        return selectedIndex == 0
            ? 0.13
            : selectedIndex == 1
            ? 0.45
            : 0.77;
      } else {
        // Inverse les positions en RTL
        return selectedIndex == 0
            ? 0.77
            : selectedIndex == 1
            ? 0.45
            : 0.13;
      }
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Directionality(
            textDirection: Directionality.of(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final bool isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => onItemTapped(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[index],
                        color: isSelected ? primaryColor : textColor,
                        size: isSelected ? 30 : 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? primaryColor : subtitleColor,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          left: MediaQuery.of(context).size.width * getPosition(),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.16), // bulle légère indigo clair
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

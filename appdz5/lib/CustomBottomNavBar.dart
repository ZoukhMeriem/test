import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            gradient: LinearGradient(
              colors: [
                Color(0xFFA4C6A8),
                Color(0xFFF4D9DE),
                Color(0xFFDDD7E8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                        color: isSelected ? Color(0xFF0C3243) : Color(0xFF1E1E1E),
                        size: isSelected ? 30 : 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color:
                          isSelected ? Color(0xFF0C3243) : Color(0xFF1E1E1E),
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
              color: Color(0x292799FF), // Bulle légère bleu clair
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

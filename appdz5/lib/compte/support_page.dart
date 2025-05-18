import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({Key? key}) : super(key: key);

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final Color primaryColor = const Color(0xFF998BB1FF);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool showRatingBar = false;
  double _noteDonnee = 3.0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final List<Map<String, String>> faqData = [
      {"question": loc.faq1q, "answer": loc.faq1a},
      {"question": loc.faq2q, "answer": loc.faq2a},
      {"question": loc.faq3q, "answer": loc.faq3a},
      {"question": loc.faq4q, "answer": loc.faq4a},
      {"question": loc.faq5q, "answer": loc.faq5a},
      {"question": loc.faq6q, "answer": loc.faq6a},
      {"question": loc.faq7q, "answer": loc.faq7a},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.supportTitle, style: const TextStyle(color: Colors.black)),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.faqTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...faqData.map((item) => ExpansionTile(
              title: Text(item['question']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(item['answer']!),
                )
              ],
            )),
            const Divider(height: 40),
            Text(loc.contactTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: loc.emailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value != null && value.contains('@') ? null : loc.invalidEmail,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: loc.messageLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value != null && value.isNotEmpty ? null : loc.emptyMessage,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _envoyerMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.send),
                    label: Text(loc.send),
                  ),
                  const SizedBox(height: 20),
                  Text(loc.rateUsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showRatingBar = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4D9DE),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.star_rate),
                    label: Text(loc.rateUs),
                  ),
                  if (showRatingBar) ...[
                    const SizedBox(height: 20),
                    Text(loc.giveRating, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    RatingBar.builder(
                      initialRating: _noteDonnee,
                      minRating: 0,
                      maxRating: 5,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _noteDonnee = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _envoyerNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4D9DE),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.send),
                      label: Text(loc.sendRating),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _envoyerMessage() {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.messageSent), backgroundColor: Colors.green),
      );
      _emailController.clear();
      _messageController.clear();
    }
  }

  void _envoyerNote() async {
    final loc = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance.collection('Evaluations').add({
        'note': _noteDonnee,
        'date': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.thankYou} $_noteDonnee/5')),
      );

      setState(() {
        showRatingBar = false;
        _noteDonnee = 3.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.ratingError)),
      );
    }
  }
}

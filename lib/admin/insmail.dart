import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'callbbox.dart';

class InsMailPage extends StatelessWidget {
  final ColorScheme dync;
  const InsMailPage({required this.dync, super.key});

  Uri _mailToUri({required String to, required String subject, required String body}) {
    return Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
  }

  Future<void> _openMail({
    required BuildContext context,
    required String to,
    required String subject,
    required String body,
  }) async {
    final uri = _mailToUri(to: to, subject: subject, body: body);
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open mail app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEmails = initialRequests.map((item) => item.email).join(',');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
          child: Text(
            'Mail Students',
            style: TextStyle(
              color: dync.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openMail(
                context: context,
                to: allEmails,
                subject: 'Class Update',
                body: 'Hello students,\n\nThis is a quick class update.\n\nThanks.',
              ),
              icon: const Icon(Icons.send),
              label: const Text('Mail All Students'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: initialRequests.length,
            itemBuilder: (context, index) {
              final student = initialRequests[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dync.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: dync.primary,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: TextStyle(color: dync.onPrimary),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dync.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    student.email,
                    style: TextStyle(color: dync.onPrimaryContainer.withOpacity(0.8)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.mail),
                    onPressed: () => _openMail(
                      context: context,
                      to: student.email,
                      subject: 'Hello ${student.name}',
                      body: 'Hi ${student.name},\n\nJust checking in regarding class.\n\nThanks.',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

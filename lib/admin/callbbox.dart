import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class callbox extends StatefulWidget {
  late ColorScheme dync;
  callbox({required this.dync, super.key});

  @override
  State<callbox> createState() => _callboxState();
}

class _callboxState extends State<callbox> {
  late final List<StudentRequest> _requests;
  late final String _instructorName;

  @override
  void initState() {
    super.initState();
    _requests = List<StudentRequest>.from(initialRequests);
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['name'];
    final emailPrefix = (user?.email ?? '').split('@').first;
    _instructorName = (metadataName is String && metadataName.trim().isNotEmpty)
        ? metadataName.trim()
        : (emailPrefix.isNotEmpty ? emailPrefix : 'Instructor');
  }

  void _handleAction(String action, StudentRequest request) {
    setState(() {
      _requests.remove(request);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$action: ${request.name}')));
  }

  @override
  Widget build(BuildContext context) {
    final kh = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Container(
          height: kh / 3,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(26.0),
              child: Row(
                children: [
                  Text(
                    'Hello\n$_instructorName',
                    style: TextStyle(
                      color: widget.dync.onPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            'Requested Students',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.dync.onPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Divider(
            color: widget.dync.onPrimary.withOpacity(0.4),
          ),
        ),
        SizedBox(
          height: kh / 3,
          child: _requests.isEmpty
              ? Center(
                  child: Text(
                    'No pending requests',
                    style: TextStyle(
                      color: widget.dync.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.dync.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: double.infinity,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.dync.primary,
                            child: Text(
                              request.name.isNotEmpty
                                  ? request.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: widget.dync.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: widget.dync.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                request.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.dync.onPrimaryContainer
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _handleAction('Accepted', request),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 30,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _handleAction('Declined', request),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                  child: const Text('Decline'),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}

class StudentRequest {
  final String name;
  final String email;

  const StudentRequest({required this.name, required this.email});
}

const List<StudentRequest> initialRequests = [
  StudentRequest(name: 'Tamizh Kumar', email: 'tamizh@example.com'),
  StudentRequest(name: 'Saroja Devi', email: 'saroja@example.com'),
  StudentRequest(name: 'Ahamed Ali', email: 'ahamed@example.com'),
  StudentRequest(name: 'Nivetha', email: 'nivetha@example.com'),
  StudentRequest(name: 'Kishore', email: 'kishore@example.com'),
  StudentRequest(name: 'Rihana', email: 'rihana@example.com'),
  StudentRequest(name: 'Pradeep', email: 'pradeep@example.com'),
  StudentRequest(name: 'Jenifa', email: 'jenifa@example.com'),
];

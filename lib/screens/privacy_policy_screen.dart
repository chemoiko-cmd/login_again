import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  static const routeName = '/privacy-policy';
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String _markdown = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    try {
      final data = await rootBundle.loadString('assets/privacy_policy.md');
      setState(() {
        _markdown = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _markdown = 'Unable to load privacy policy.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: _loading
          ? const Center(child: AppLoadingIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Markdown(data: _markdown),
            ),
    );
  }
}

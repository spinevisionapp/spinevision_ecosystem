import 'package:flutter/material.dart';
import 'package:spinevision_ecosystem/shared/theme/colors.dart';

class AssistVisionScreen extends StatefulWidget {
  const AssistVisionScreen({super.key});

  @override
  State<AssistVisionScreen> createState() => _AssistVisionScreenState();
}

class _AssistVisionScreenState extends State<AssistVisionScreen> {
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'text': 'Hello! I am ChatVision. How can I help you today with your book reselling business?'},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': _controller.text});
      // Simulate bot response
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({'role': 'bot', 'text': 'I am analyzing your request. Based on current Amazon trends, that book is a high-value BOLO!'});
          });
        }
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AssistVision'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat), text: 'ChatVision'),
              Tab(icon: Icon(Icons.help_center), text: 'FAQ'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatTab(),
            _buildFAQTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isBot = msg['role'] == 'bot';
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.grey[200] : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                      bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                    ),
                  ),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(color: isBot ? Colors.black87 : AppColors.primary),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask ChatVision...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQTab() {
    final faqs = [
      {'q': 'How do I upgrade my tier?', 'a': 'Go to the PromoVision screen or settings to view membership options.'},
      {'q': 'What is a BOLO alert?', 'a': 'BOLO stands for "Be On the LookOut". These are high-profit items identified by our AI.'},
      {'q': 'Can I sync with eBay?', 'a': 'Yes, NexusVision supports eBay professional account integration.'},
      {'q': 'How does ShelfVision work?', 'a': 'ShelfVision uses AI to scan multiple book spines at once and provide instant valuations.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return ExpansionTile(
          title: Text(faqs[index]['q']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(faqs[index]['a']!),
            ),
          ],
        );
      },
    );
  }
}

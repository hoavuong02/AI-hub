import 'package:flutter/material.dart';

final String name = "AI Hub";

final List<Map<String, dynamic>> aiList = [
  {
    'name': 'ChatGPT',
    'url': 'https://chatgpt.com/',
    'icon': Icons.smart_toy,
    'color': Colors.green,
    'desc': 'Versatile text assistant',
  },
  {
    'name': 'DuckDuckGo',
    'url': 'https://duck.ai',
    'icon': Icons.security,
    'color': Colors.orange,
    'desc': 'Private search engine',
  },
  {
    'name': 'Venice',
    'url': 'https://venice.ai/chat',
    'icon': Icons.palette,
    'color': Colors.blue,
    'desc': 'Creative image generator',
  },
  {
    'name': 'Grok',
    'url': 'https://grok.com/',
    'icon': Icons.emoji_people,
    'color': Colors.amber[800]!,
    'desc': 'Witty xAI assistant',
  },
  {
    'name': 'Proton',
    'url': 'https://lumo.proton.me/',
    'icon': Icons.lock,
    'color': Colors.purple,
    'desc': 'Privacy-focused AI',
  },
  {
    'name': 'Deepseek',
    'url': 'https://chat.deepseek.com/',
    'icon': Icons.code,
    'color': Colors.teal,
    'desc': 'Coding specialist AI',
  },
  {
    'name': 'Gemini',
    'url': 'https://gemini.google.com/',
    'icon': Icons.auto_awesome,
    'color': Colors.blueAccent,
    'desc': 'Google AI assistant',
  },
  {
    'name': 'Claude',
    'url': 'https://claude.ai/chat',
    'icon': Icons.psychology,
    'color': Colors.deepPurple,
    'desc': 'Thoughtful conversation AI',
  },
  {
    'name': 'Perplexity',
    'url': 'https://www.perplexity.ai/',
    'icon': Icons.search,
    'color': Colors.indigo,
    'desc': 'AI search engine',
  },
  {
    "name": "Qwen",
    "url": "https://chat.qwen.ai/",
    "icon": Icons.record_voice_over,
    "color": Colors.lightGreen,
    "desc": "Alibaba's AI assistant",
  },
  {
    "name": "Mistral",
    "url": "https://chat.mistral.ai/",
    "icon": Icons.ac_unit,
    "color": Colors.cyan,
    "desc": "European AI model",
  },
  {
    "name": "Blackbox",
    "url": "https://www.blackbox.ai/",
    "icon": Icons.terminal,
    "color": Colors.blueGrey,
    "desc": "AI code generator",
  },
];

final Map<String, int> fontSizes = {
  'x-small': 14,
  'small': 15,
  'medium': 16,
  'large': 17,
  'x-large': 18,
};

final userAgent =
    "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36";

final String shareOverrideJS = """
(function() {
  // Store original share function if it exists
  const originalShare = navigator.share;
  
  // Override navigator.share
  navigator.share = function(shareData) {
    console.log('Share intercepted:', shareData);
    
    // Send share data to Flutter
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('shareHandler', shareData);
    }
    
    // Return a promise that resolves (simulating successful share)
    return Promise.resolve();
  };
  
  // Also handle click events on share buttons (as fallback)
  document.addEventListener('click', function(e) {
    const target = e.target;
    const isShareButton = target.closest('[class*="share"], [id*="share"]') ||
                          target.closest('button[onclick*="share"]');
    
    if (isShareButton) {
      e.preventDefault();
      e.stopPropagation();
      
      // Try to extract share data from common patterns
      const title = document.title;
      const url = window.location.href;
      const shareData = { title: title, url: url, text: title };
      
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('shareHandler', shareData);
      }
    }
  }, true);
})();
""";

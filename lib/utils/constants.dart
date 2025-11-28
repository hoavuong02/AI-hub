import 'package:flutter/material.dart';

final String name = "AI Hub";
final List<Map<String, dynamic>> aiList = [
  {
    'name': 'ChatGPT',
    'url': 'https://chatgpt.com/',
    'icon': Icons.smart_toy,
    'color': Colors.green,
    'desc': 'Versatile text assistant',
    'detailedDesc':
        'OpenAI\'s flagship AI assistant capable of natural conversations, code generation, creative writing, problem-solving, and knowledge integration across diverse topics with advanced reasoning capabilities.',
  },
  {
    'name': 'Duck AI',
    'url': 'https://duckduckgo.com/?q=DuckDuckGo+AI+Chat&ia=chat&duckai=1',
    'icon': Icons.security,
    'color': Colors.orange,
    'desc': 'Private search engine',
    'detailedDesc':
        'Privacy-focused search engine that doesn\'t track your searches or create filter bubbles. Features AI-assisted search capabilities while maintaining strict privacy protections and anonymous searching.',
  },
  {
    'name': 'Venice',
    'url': 'https://venice.ai/chat',
    'icon': Icons.palette,
    'color': Colors.blue,
    'desc': 'Creative image generator',
    'detailedDesc':
        'Advanced AI image generation platform that creates stunning visual art, digital illustrations, and creative designs from text descriptions with various artistic styles and customization options.',
  },
  {
    'name': 'Grok',
    'url': 'https://grok.com/',
    'icon': Icons.emoji_people,
    'color': Colors.amber[800]!,
    'desc': 'Witty xAI assistant',
    'detailedDesc':
        'xAI\'s AI assistant known for its witty personality, real-time knowledge access, and rebellious tone. Features a "fun mode" for entertaining conversations while maintaining strong reasoning capabilities.',
  },
  {
    'name': 'Lumo',
    'url': 'https://lumo.proton.me/',
    'icon': Icons.lock,
    'color': Colors.purple,
    'desc': 'Privacy-focused AI',
    'detailedDesc':
        'Swiss-based privacy-first AI assistant from the creators of Proton Mail. Emphasizes data protection, encrypted interactions, and ethical AI use without compromising on performance.',
  },
  {
    'name': 'Deepseek',
    'url': 'https://chat.deepseek.com/',
    'icon': Icons.code,
    'color': Colors.teal,
    'desc': 'Coding specialist AI',
    'detailedDesc':
        'Specialized AI model optimized for programming tasks, code explanation, debugging, and software development. Supports multiple programming languages and offers technical problem-solving capabilities.',
  },
  {
    'name': 'Gemini',
    'url': 'https://gemini.google.com/',
    'icon': Icons.auto_awesome,
    'color': Colors.blueAccent,
    'desc': 'Google AI assistant',
    'detailedDesc':
        'Google\'s multimodal AI assistant that can process text, images, audio, and video. Integrates with Google ecosystem and offers real-time information, creative collaboration, and advanced reasoning.',
  },
  {
    'name': 'Claude',
    'url': 'https://claude.ai/chat',
    'icon': Icons.psychology,
    'color': Colors.deepPurple,
    'desc': 'Thoughtful conversation AI',
    'detailedDesc':
        'Anthropic\'s AI assistant focused on safe, nuanced conversations with strong reasoning abilities. Excels at document analysis, creative writing, and maintaining coherent, context-aware dialogues.',
  },
  {
    'name': 'Perplexity',
    'url': 'https://www.perplexity.ai/',
    'icon': Icons.search,
    'color': Colors.indigo,
    'desc': 'AI search engine',
    'detailedDesc':
        'Conversational search engine that combines AI-powered answers with real-time web sources. Provides citations, follow-up questions, and comprehensive research capabilities for accurate information discovery.',
  },
  {
    "name": "Qwen",
    "url": "https://chat.qwen.ai/",
    "icon": Icons.record_voice_over,
    "color": Colors.lightGreen,
    "desc": "Alibaba's AI assistant",
    "detailedDesc":
        "Alibaba Cloud's multilingual AI model supporting Chinese and English with strong capabilities in dialogue, creative writing, and knowledge tasks. Features extensive context handling and coding assistance.",
  },
  {
    "name": "Mistral",
    "url": "https://chat.mistral.ai/",
    "icon": Icons.ac_unit,
    "color": Colors.cyan,
    "desc": "European AI model",
    "detailedDesc":
        "French AI company's sophisticated language model known for efficient reasoning, strong coding abilities, and nuanced understanding. Offers balanced performance across various tasks with European data focus.",
  },
  {
    "name": "Blackbox",
    "url": "https://www.blackbox.ai/",
    "icon": Icons.terminal,
    "color": Colors.blueGrey,
    "desc": "AI code generator",
    "detailedDesc":
        "Specialized AI tool focused on code generation, explanation, and optimization. Supports multiple programming languages, provides code suggestions, and helps developers write better code faster with intelligent autocomplete.",
  },
];

List<String> allowedDomains = [
  // ChatGPT
  "cdn.auth0.com",
  "auth.openai.com",
  "chatgpt.com",
  "openai.com",
  "fileserviceuploadsperm.blob.core.windows.net",
  "cdn.oaistatic.com",
  "oaiusercontent.com",

  // DuckDuckGo
  "duckduckgo.com",

  // Venice
  "venice.ai",

  // Grok
  "grok.com",

  // Lumo
  "account.proton.me",
  "lumo.proton.me",

  // Deepseek
  "chat.deepseek.com",
  "cdn.deepseek.com",
  "static.deepseek.com",

  // Gemini
  "gemini.google.com",
  "fonts.gstatic.com",
  "www.gstatic.com",

  // Claude
  "claude.ai",

  // Perplexity
  "www.perplexity.ai",
  "pplx-next-static-public.perplexity.ai",

  // Qwen
  "chat.qwen.ai",
  "cdnjs.cloudflare.com",
  "assets.alicdn.com",
  "img.alicdn.com",
  "at.alicdn.com",
  "d.alicdn.com",
  "o.alicdn.com",
  "g.alicdn.com",

  // Mistral
  "cdn.auth0.com",
  "chat.mistral.ai",
  "mistral.ai",
  "api.mistral.ai",
  "console.mistral.ai",
  "mistralcdn.net",

  // Blackbox
  "www.blackbox.ai",
  "js.stripe.com",
  "m.stripe.network",
];

final Map<String, String> aisDomains = Map.fromEntries(
  aiList.map((ai) => MapEntry(Uri.parse(ai['url']).host, ai['name'])),
);

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
  
  const originalShare = navigator.share;
  
  
  navigator.share = function(shareData) {
    console.log('Share intercepted:', shareData);
    
    
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('shareHandler', shareData);
    }
    
    
    return Promise.resolve();
  };
  
  
  document.addEventListener('click', function(e) {
    const target = e.target;
    const isShareButton = target.closest('[class*="share"], [id*="share"]') ||
                          target.closest('button[onclick*="share"]');
    
    if (isShareButton) {
      e.preventDefault();
      e.stopPropagation();
      
      
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

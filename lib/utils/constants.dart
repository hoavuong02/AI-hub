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
    'url': 'https://duck.ai/',
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
    "url": "https://app.blackbox.ai/",
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
  "duck.ai",
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
  "chat.mistral.ai",
  "mistral.ai",
  "api.mistral.ai",
  "console.mistral.ai",
  "mistralcdn.net",

  // Blackbox
  "app.blackbox.ai",
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

final iconSvgCode =
    """<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 411 512.455"><path d="M248.96 337.22v17.853a19.44 19.44 0 018.169 4.885c.273.272.527.557.763.851 3.041 3.42 4.902 7.89 4.93 12.755h25.009c43.316 0 78.72 35.404 78.72 78.72v49.752c0 5.754-4.665 10.419-10.419 10.419H57.101c-5.754 0-10.419-4.665-10.419-10.419v-49.752c0-43.316 35.404-78.72 78.72-78.72h24.062c.03-5.257 2.203-10.057 5.693-13.566l.064-.063a19.599 19.599 0 018.105-4.851V337.22h-54.737c-35.913 0-65.579-27.915-68.391-63.132-10.704-.736-20.364-5.409-27.525-12.571C4.854 253.697 0 242.902 0 231.019v-40.881c0-11.883 4.854-22.679 12.673-30.497 7.172-7.173 16.849-11.848 27.571-12.574 3.064-34.969 32.61-62.609 68.345-62.609h87.316V61.51a31.667 31.667 0 01-11.948-7.508c-5.724-5.725-9.266-13.634-9.266-22.368 0-8.734 3.542-16.643 9.266-22.368C189.682 3.542 197.591 0 206.324 0c8.735 0 16.644 3.542 22.367 9.267 5.725 5.723 9.267 13.632 9.267 22.367 0 8.734-3.542 16.643-9.267 22.367a31.641 31.641 0 01-11.948 7.509v22.948h86.955c35.771 0 65.342 27.695 68.353 62.716 10.207 1 19.395 5.584 26.276 12.467 7.82 7.818 12.673 18.614 12.673 30.497v40.881c0 11.883-4.853 22.678-12.673 30.498-6.871 6.872-16.042 11.453-26.228 12.463-2.76 35.269-32.451 63.24-68.401 63.24H248.96zM137.618 159.185c11.493 0 21.9 4.66 29.431 12.192 7.532 7.531 12.192 17.938 12.192 29.431 0 11.492-4.66 21.898-12.192 29.431-7.531 7.531-17.938 12.191-29.431 12.191-11.491 0-21.898-4.66-29.43-12.191-7.532-7.533-12.192-17.94-12.192-29.431 0-11.493 4.66-21.9 12.192-29.431 7.532-7.532 17.938-12.192 29.43-12.192zm53.748-45.081a6.69 6.69 0 110 13.38 6.69 6.69 0 010-13.38zm29.651 0a6.69 6.69 0 110 13.381 6.69 6.69 0 010-13.381zm54.65 45.081c11.492 0 21.899 4.66 29.431 12.192 7.531 7.531 12.192 17.938 12.192 29.431 0 11.492-4.661 21.898-12.192 29.431-7.532 7.531-17.939 12.191-29.431 12.191-11.491 0-21.899-4.66-29.431-12.191-7.531-7.533-12.191-17.94-12.191-29.431 0-11.493 4.66-21.9 12.191-29.431 7.532-7.532 17.939-12.192 29.431-12.192zm0 17.55c13.296 0 24.073 10.777 24.073 24.073 0 13.295-10.777 24.072-24.073 24.072-13.295 0-24.073-10.777-24.073-24.072 0-13.296 10.778-24.073 24.073-24.073zm0-11.298c19.535 0 35.371 15.836 35.371 35.371 0 19.534-15.836 35.37-35.371 35.37-19.534 0-35.371-15.836-35.371-35.37 0-19.535 15.837-35.371 35.371-35.371zm-37.925 99.668a6.252 6.252 0 010 12.504h-63.198a6.252 6.252 0 110-12.504h63.198zm-100.124-88.37c13.296 0 24.074 10.777 24.074 24.073 0 13.295-10.778 24.072-24.074 24.072-13.295 0-24.072-10.777-24.072-24.072 0-13.296 10.777-24.073 24.072-24.073zm0-11.298c19.536 0 35.371 15.836 35.371 35.371 0 19.534-15.835 35.37-35.371 35.37-19.534 0-35.37-15.836-35.37-35.37 0-19.535 15.836-35.371 35.37-35.371zm68.706-155.018c11.717 0 21.215 9.498 21.215 21.215s-9.498 21.215-21.215 21.215c-11.716 0-21.214-9.498-21.214-21.215s9.498-21.215 21.214-21.215zm-97.735 84.518h195.109c31.973 0 58.132 26.159 58.132 58.133v115.539c0 31.973-26.159 58.133-58.132 58.133H108.589c-31.974 0-58.133-26.16-58.133-58.133V153.07c0-31.974 26.159-58.133 58.133-58.133zm263.72 168.525c15.915-2.202 28.273-15.948 28.273-32.443v-40.881c0-16.495-12.358-30.24-28.273-32.442v105.766zm-332.332.153c-16.53-1.619-29.558-15.659-29.558-32.596v-40.881c0-16.937 13.028-30.976 29.558-32.594v106.071zm212.425 109.949c-.058-4.895-4.079-8.881-8.988-8.881h-74.543c-4.907 0-8.929 3.986-8.987 8.881h92.518zm-90.363 34.642h89.154c12.956 0 23.565 10.617 23.565 23.565v24.569c0 12.922-10.643 23.565-23.565 23.565h-89.154c-12.96 0-23.565-10.618-23.565-23.565v-24.569c0-12.931 10.634-23.565 23.565-23.565zm78.973 29.077a6.773 6.773 0 110 13.546 6.773 6.773 0 010-13.546zm-68.792 0a6.772 6.772 0 11.001 13.545 6.772 6.772 0 01-.001-13.545zm-10.181-18.659h89.154c7.231 0 13.146 5.919 13.146 13.147v24.569c0 7.227-5.918 13.146-13.146 13.146h-89.154c-7.228 0-13.146-5.916-13.146-13.146v-24.569c0-7.231 5.915-13.147 13.146-13.147zm193.874 53.808l.219.006v-20.154c0-36.048-28.303-65.801-63.784-68.147 2.463 2.684 4.736 5.532 6.829 8.428 3.499 4.843 6.471 9.773 8.956 14.272 4.581 8.287 7.094 15.156 8.47 22.243 1.362 7.015 1.576 14.033 1.576 22.787v20.565h37.734zm.219 8.33l-.219.006h-37.734v21.097l-.004.171h37.957v-21.274zm-46.285 21.274l-.004-.171v-49.998c0-8.325-.192-14.939-1.412-21.225-1.207-6.214-3.457-12.322-7.591-19.801-2.376-4.302-5.181-8.965-8.403-13.425-3.197-4.423-6.831-8.698-10.912-12.302a4.12 4.12 0 01-.9-1.131H132.26c-.226.416-.526.8-.9 1.131-4.081 3.604-7.716 7.879-10.912 12.302-3.222 4.46-6.026 9.123-8.404 13.425-4.133 7.478-6.384 13.586-7.591 19.801-1.22 6.286-1.412 12.9-1.412 21.225v49.998l-.004.171h206.81zM94.705 480.768H57.287l-.186-.005v21.273h37.608l-.004-.171v-21.097zm-37.604-8.331l.186-.005h37.418v-20.565c0-8.754.214-15.772 1.576-22.787 1.376-7.087 3.89-13.956 8.471-22.243 2.486-4.5 5.456-9.429 8.956-14.272 2.087-2.887 4.354-5.727 6.808-8.404-35.308 2.527-63.415 32.2-63.415 68.123v20.153zm181.44-135.217v17.044h-64.796V337.22h64.796z"/></svg>""";

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

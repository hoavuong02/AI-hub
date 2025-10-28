import 'package:aihub/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class AiHome extends StatefulWidget {
  const AiHome({super.key});
  @override
  State<AiHome> createState() => _AiHomeState();
}

class _AiHomeState extends State<AiHome> {
  int _selectedIndex = 0;
  final List<InAppWebViewController?> _controllers = [];
  final List<String> _currentUrls = [];
  final List<bool> _isLoadingList = [];
  final List<bool> _hasBeenLoadedList = [];
  final List<String?> _errorMessages = [];
  final List<bool> _canGoBackList = [];
  String _currentDomain = 'AI Hub';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadLastAiIndex();
  }

  void _initializeData() {
    for (int i = 0; i < aiList.length; i++) {
      _controllers.add(null);
      _currentUrls.add(aiList[i]['url']);
      _isLoadingList.add(false);
      _hasBeenLoadedList.add(false);
      _errorMessages.add(null);
      _canGoBackList.add(false);
    }
  }

  Widget _buildPlaceholder(int index) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Tap to load ${aiList[index]['name']}',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadLastAiIndex() async {
    try {
      final lastIndex = await SharedPrefs.getLastAiIndex();
      setState(() {
        _selectedIndex = lastIndex;
        _currentDomain = _getDomainFromUrl(aiList[lastIndex]['url']);
      });
      _createWebViewForTab(lastIndex);
    } catch (e) {
      debugPrint('Error loading last AI index: $e');
    }
  }

  String _getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'AI Hub';
    }
  }

  void _onItemTapped(int index) {
    SharedPrefs.saveLastAiIndex(index);

    if (!_hasBeenLoadedList[index]) {
      _createWebViewForTab(index);
    } else {
      setState(() {
        _currentDomain = _getDomainFromUrl(_currentUrls[index]);
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _createWebViewForTab(int index) {
    setState(() {
      _hasBeenLoadedList[index] = true;
      _isLoadingList[index] = true;
    });
  }

  String get _themeScript {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return '''
      (function() {
        document.documentElement.setAttribute('data-theme', '${isDark ? 'dark' : 'light'}');
        if (window.location.host.includes('chat.openai.com')) {
          document.body.classList.add('${isDark ? 'dark' : 'light'}');
        }
        if (window.location.host.includes('duck.ai')) {
          document.documentElement.style.colorScheme = '${isDark ? 'dark' : 'light'}';
        }
      })();
    ''';
  }

  void _retryLoading(int index) {
    if (_controllers[index] == null) return;
    setState(() {
      _errorMessages[index] = null;
      _isLoadingList[index] = true;
    });
    _controllers[index]?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentUrls[index])),
    );
  }

  void _reloadPage(int index) {
    if (_controllers[index] == null) return;
    setState(() {
      _errorMessages[index] = null;
      _isLoadingList[index] = true;
    });
    _controllers[index]?.reload();
  }

  Widget _buildWebView(int index) {
    return InAppWebView(
      key: Key('webview_$index'),
      initialUrlRequest: URLRequest(url: WebUri(aiList[index]['url'])),
      initialSettings: InAppWebViewSettings(
        forceDark: ForceDark.AUTO,
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        transparentBackground: true,
        disableVerticalScroll: false,
        disableHorizontalScroll: false,
        supportZoom: false,
        userAgent:
            "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36",
      ),
      onWebViewCreated: (controller) {
        _controllers[index] = controller;
        controller.addUserScript(
          userScript: UserScript(
            source: _themeScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        );
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoadingList[index] = true;
          _errorMessages[index] = null;
        });
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? 'AI Hub';
          });
        }
      },
      onLoadStop: (controller, url) async {
        final canGoBack = await controller.canGoBack();
        setState(() {
          _isLoadingList[index] = false;
          _currentUrls[index] = url?.toString() ?? aiList[index]['url'];
          _canGoBackList[index] = canGoBack;
        });
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? 'AI Hub';
          });
        }
      },
      onLoadError: (controller, url, code, message) {
        setState(() {
          _isLoadingList[index] = false;
          _errorMessages[index] = 'Failed to load page. Error: $message';
        });
      },
      onLoadHttpError: (controller, url, statusCode, description) {
        if (500 <= statusCode && statusCode < 600) return;
        setState(() {
          _isLoadingList[index] = false;
          _errorMessages[index] = 'HTTP Error $statusCode: $description';
        });
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        final canGoBack = await controller.canGoBack();
        setState(() {
          _canGoBackList[index] = canGoBack;
          _currentUrls[index] = url?.toString() ?? aiList[index]['url'];
        });
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? 'AI Hub';
          });
        }
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Future<bool> _onWillPop() async {
    final currentController = _controllers[_selectedIndex];

    if (currentController != null && _canGoBackList[_selectedIndex]) {
      final currentUrl = await currentController.getUrl();
      final initialUrl = aiList[_selectedIndex]['url'];

      if (currentUrl != null && currentUrl.toString() != initialUrl) {
        await currentController.goBack();
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Hub',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    Text(
                      _currentDomain,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingList[_selectedIndex])
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Loading',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessages[_selectedIndex] != null &&
                  !_isLoadingList[_selectedIndex])
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 12,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          leading: Builder(
            builder: (context) => Container(
              margin: EdgeInsets.all(8),
              child: FloatingActionButton.small(
                onPressed: () => Scaffold.of(context).openDrawer(),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 1,
                child: Icon(Icons.menu_rounded),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    MediaQuery.of(context).size.width,
                    kToolbarHeight,
                    0,
                    0,
                  ),
                  items: [
                    if (_hasBeenLoadedList[_selectedIndex] &&
                        !_isLoadingList[_selectedIndex])
                      PopupMenuItem(
                        value: 'reload',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              'Reload',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    if (_canGoBackList[_selectedIndex] &&
                        _hasBeenLoadedList[_selectedIndex])
                      PopupMenuItem(
                        value: 'back',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              'Go back',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.deepPurple),
                          SizedBox(width: 10),
                          Text('Settings'),
                        ],
                      ),
                    ),
                  ],
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                ).then((value) async {
                  if (value == 'reload') {
                    _reloadPage(_selectedIndex);
                  } else if (value == 'back') {
                    await _controllers[_selectedIndex]?.goBack();
                  } else if (value == 'settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                    setState(() {});
                  }
                });
              },
              icon: Icon(Icons.more_vert_rounded),
              tooltip: "More options",
            ),
          ],
        ),

        body: SafeArea(
          child: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: List.generate(
                  aiList.length,
                  (index) => _hasBeenLoadedList[index]
                      ? _buildWebView(index)
                      : _buildPlaceholder(index),
                ),
              ),
              if (_isLoadingList[_selectedIndex] &&
                  _errorMessages[_selectedIndex] == null)
                Positioned.fill(
                  child: LoadingWidget(
                    aiName: aiList[_selectedIndex]['name'],
                    domain: _currentDomain,
                  ),
                ),
              if (_errorMessages[_selectedIndex] != null &&
                  !_isLoadingList[_selectedIndex])
                Positioned.fill(
                  child: CustomErrorWidget(
                    errorMessage: _errorMessages[_selectedIndex],
                    onRetry: () => _retryLoading(_selectedIndex),
                  ),
                ),
            ],
          ),
        ),

        drawer: CustomDrawer(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          isLoadingList: _isLoadingList,
          hasBeenLoadedList: _hasBeenLoadedList,
          errorMessages: _errorMessages,
        ),
      ),
    );
  }
}

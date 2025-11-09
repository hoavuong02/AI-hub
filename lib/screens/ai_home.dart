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
  String _currentDomain = name;
  List<Map<String, dynamic>> _enabledAiList = [];
  int _defaultFontSize = 16;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadEnabledAiList();
    _loadLastAiIndex();
  }

  Future<void> _loadEnabledAiList() async {
    _enabledAiList = [];
    for (var ai in aiList) {
      final isEnabled = await SharedPrefs.getAiStatus(ai['name']);
      if (isEnabled) {
        _enabledAiList.add(ai);
      }
    }

    if (_enabledAiList.isEmpty) {
      _enabledAiList = List.from(aiList);
      for (var ai in aiList) {
        await SharedPrefs.setAiStatus(ai['name'], true);
      }
    }

    for (int i = 0; i < _enabledAiList.length; i++) {
      if (i >= _controllers.length) _controllers.add(null);
      if (i >= _currentUrls.length) _currentUrls.add(_enabledAiList[i]['url']);
      if (i >= _isLoadingList.length) _isLoadingList.add(false);
      if (i >= _hasBeenLoadedList.length) _hasBeenLoadedList.add(false);
      if (i >= _errorMessages.length) _errorMessages.add(null);
      if (i >= _canGoBackList.length) _canGoBackList.add(false);
    }

    if (_controllers.length > _enabledAiList.length) {
      _controllers.removeRange(_enabledAiList.length, _controllers.length);
    }
    if (_currentUrls.length > _enabledAiList.length) {
      _currentUrls.removeRange(_enabledAiList.length, _currentUrls.length);
    }
    if (_isLoadingList.length > _enabledAiList.length) {
      _isLoadingList.removeRange(_enabledAiList.length, _isLoadingList.length);
    }
    if (_hasBeenLoadedList.length > _enabledAiList.length) {
      _hasBeenLoadedList.removeRange(
        _enabledAiList.length,
        _hasBeenLoadedList.length,
      );
    }
    if (_errorMessages.length > _enabledAiList.length) {
      _errorMessages.removeRange(_enabledAiList.length, _errorMessages.length);
    }
    if (_canGoBackList.length > _enabledAiList.length) {
      _canGoBackList.removeRange(_enabledAiList.length, _canGoBackList.length);
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
            const SizedBox(height: 16),
            Text(
              'Tap to load ${_enabledAiList[index]['name']}',
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
      final shouldLoadLast = await SharedPrefs.getLoadLastOpenedAi();
      int lastIndex;

      if (shouldLoadLast) {
        final lastAiName = await SharedPrefs.getLastAiName();
        lastIndex = _enabledAiList.indexWhere((ai) => ai['name'] == lastAiName);
        if (lastIndex == -1) lastIndex = 0;
      } else {
        final defaultAiName = await SharedPrefs.getDefaultAiName();
        lastIndex = _enabledAiList.indexWhere(
          (ai) => ai['name'] == defaultAiName,
        );
        if (lastIndex == -1) lastIndex = 0;
      }

      if (lastIndex >= _enabledAiList.length) {
        lastIndex = 0;
      }

      setState(() {
        _selectedIndex = lastIndex;
        _currentDomain = _getDomainFromUrl(_enabledAiList[lastIndex]['url']);
      });
      _createWebViewForTab(lastIndex);
    } catch (e) {
      debugPrint('Error loading last AI index: $e');

      if (_enabledAiList.isNotEmpty) {
        setState(() {
          _selectedIndex = 0;
          _currentDomain = _getDomainFromUrl(_enabledAiList[0]['url']);
        });
        _createWebViewForTab(0);
      }
    }
  }

  String _getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return name;
    }
  }

  void _onItemTapped(int index) {
    if (index < 0 || index >= _enabledAiList.length) return;

    SharedPrefs.saveLastAiName(_enabledAiList[index]['name']);

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
    if (index < 0 || index >= _enabledAiList.length) return;

    setState(() {
      _hasBeenLoadedList[index] = true;
      _isLoadingList[index] = true;
    });
  }

  void _retryLoading(int index) {
    if (index < 0 ||
        index >= _controllers.length ||
        _controllers[index] == null) {
      return;
    }
    setState(() {
      _errorMessages[index] = null;
      _isLoadingList[index] = true;
    });
    _controllers[index]?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentUrls[index])),
    );
  }

  void _reloadPage(int index) {
    if (index < 0 ||
        index >= _controllers.length ||
        _controllers[index] == null) {
      return;
    }
    setState(() {
      _errorMessages[index] = null;
      _isLoadingList[index] = true;
    });
    _controllers[index]?.reload();
  }

  String? _sameSiteToString(HTTPCookieSameSitePolicy? policy) {
    if (policy == null) return null;
    switch (policy) {
      case HTTPCookieSameSitePolicy.LAX:
        return 'LAX';
      case HTTPCookieSameSitePolicy.STRICT:
        return 'STRICT';
      case HTTPCookieSameSitePolicy.NONE:
        return 'NONE';
      default:
        return null;
    }
  }

  HTTPCookieSameSitePolicy? _stringToSameSite(String? str) {
    if (str == null) return null;
    return switch (str) {
      'LAX' => HTTPCookieSameSitePolicy.LAX,
      'STRICT' => HTTPCookieSameSitePolicy.STRICT,
      'NONE' => HTTPCookieSameSitePolicy.NONE,
      _ => null,
    };
  }

  Widget _buildWebView(int index) {
    if (index < 0 || index >= _enabledAiList.length) {
      return _buildPlaceholder(0);
    }

    SharedPrefs.getFontSize().then((font) {
      return _defaultFontSize = fontSizes[font] ?? 16;
    });

    return InAppWebView(
      key: Key('webview_$index'),
      initialUrlRequest: URLRequest(url: WebUri(_enabledAiList[index]['url'])),
      initialSettings: InAppWebViewSettings(
        forceDark: ForceDark.AUTO,
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        transparentBackground: true,
        disableVerticalScroll: false,
        disableHorizontalScroll: false,
        supportZoom: false,
        userAgent: userAgent,
      ),
      onWebViewCreated: (controller) async {
        if (index < _controllers.length) {
          _controllers[index] = controller;
        }

        // RESTORE COOKIES FOR THIS DOMAIN
        final domain = Uri.parse(_enabledAiList[index]['url']).host;
        final savedCookies = await SharedPrefs.getWebViewCookies();
        final cookiesForDomain = savedCookies?[domain];

        if (cookiesForDomain != null) {
          final uri = WebUri(_enabledAiList[index]['url']);
          for (var data in cookiesForDomain) {
            await CookieManager.instance().setCookie(
              url: uri,
              name: data['name'],
              value: data['value'],
              domain: data['domain'],
              path: data['path'] ?? '/',
              expiresDate: data['expiresDate'],
              isSecure: data['isSecure'] ?? false,
              isHttpOnly: data['isHttpOnly'] ?? false,
              sameSite: _stringToSameSite(data['sameSite']),
            );
          }
        }
      },
      onLoadStart: (controller, url) {
        if (index < _isLoadingList.length) {
          setState(() {
            _isLoadingList[index] = true;
            _errorMessages[index] = null;
          });
        }
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? name;
          });
        }
      },
      onLoadStop: (controller, url) async {
        controller.setSettings(
          settings: InAppWebViewSettings(defaultFontSize: _defaultFontSize),
        );
        final canGoBack = await controller.canGoBack();
        if (index < _isLoadingList.length) {
          setState(() {
            _isLoadingList[index] = false;
            if (url != null) _currentUrls[index] = url.toString();
            _canGoBackList[index] = canGoBack;
          });
        }
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? name;
          });
        }

        final domain = Uri.parse(_enabledAiList[index]['url']).host;
        final allCookies = await CookieManager.instance().getCookies(
          url: WebUri(url.toString()),
        );

        final cookieMaps = allCookies
            .map(
              (c) => {
                'name': c.name,
                'value': c.value,
                'domain': c.domain,
                'path': c.path,
                'expiresDate': c.expiresDate,
                'isSecure': c.isSecure,
                'isHttpOnly': c.isHttpOnly,
                'sameSite': _sameSiteToString(c.sameSite),
              },
            )
            .toList();

        final currentCookies = await SharedPrefs.getWebViewCookies() ?? {};
        currentCookies[domain] = cookieMaps;
        await SharedPrefs.saveWebViewCookies(currentCookies);
      },
      onLoadError: (controller, url, code, message) {
        if (index < _isLoadingList.length) {
          setState(() {
            _isLoadingList[index] = false;
            _errorMessages[index] = 'Failed to load page. Error: $message';
          });
        }
      },
      onLoadHttpError: (controller, url, statusCode, description) {
        if (500 <= statusCode && statusCode < 600) return;
        if (index < _isLoadingList.length) {
          setState(() {
            _isLoadingList[index] = false;
            _errorMessages[index] = 'HTTP Error $statusCode: $description';
          });
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        final canGoBack = await controller.canGoBack();
        if (index < _canGoBackList.length) {
          setState(() {
            _canGoBackList[index] = canGoBack;
            if (url != null) _currentUrls[index] = url.toString();
          });
        }
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = url?.host ?? name;
          });
        }
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex >= _controllers.length ||
        _selectedIndex >= _controllers.length) {
      return true;
    }

    final currentController = _controllers[_selectedIndex];

    if (currentController == null ||
        _selectedIndex >= _canGoBackList.length ||
        !_canGoBackList[_selectedIndex]) {
      return true;
    }

    try {
      final currentUrl = await currentController.getUrl();
      final initialUrl = _enabledAiList[_selectedIndex]['url'];

      if (currentUrl != null && currentUrl != initialUrl) {
        await currentController.goBack();
        return false;
      }
    } catch (e) {
      debugPrint('Error in _onWillPop: $e');
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

  Future<void> _handleSettingsReturn() async {
    await _loadEnabledAiList();

    if (_selectedIndex >= _enabledAiList.length) {
      _selectedIndex = 0;
    }

    if (_selectedIndex < _hasBeenLoadedList.length &&
        _hasBeenLoadedList[_selectedIndex]) {
      setState(() {
        _currentDomain = _getDomainFromUrl(
          _enabledAiList[_selectedIndex]['url'],
        );
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_enabledAiList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(name), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No AI assistants enabled',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable at least one AI in Settings',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      )
                      .then((_) => _handleSettingsReturn());
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        } else {
          debugPrint('Pop occurred with result: $result');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedIndex < _isLoadingList.length &&
                  _isLoadingList[_selectedIndex])
                Container(
                  padding: const EdgeInsets.all(6),
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
                      const SizedBox(width: 6),
                      const Text(
                        'Loading',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectedIndex < _errorMessages.length &&
                  _errorMessages[_selectedIndex] != null &&
                  !_isLoadingList[_selectedIndex])
                Container(
                  padding: const EdgeInsets.all(6),
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
                      const SizedBox(width: 6),
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
              margin: const EdgeInsets.all(8),
              child: FloatingActionButton.small(
                onPressed: () => Scaffold.of(context).openDrawer(),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 1,
                child: const Icon(Icons.menu_rounded),
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
                    if (_selectedIndex < _hasBeenLoadedList.length &&
                        _hasBeenLoadedList[_selectedIndex] &&
                        !_isLoadingList[_selectedIndex])
                      const PopupMenuItem(
                        value: 'reload',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 10),
                            Text(
                              'Reload',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    if (_selectedIndex < _canGoBackList.length &&
                        _canGoBackList[_selectedIndex] &&
                        _hasBeenLoadedList[_selectedIndex])
                      const PopupMenuItem(
                        value: 'back',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios),
                            SizedBox(width: 10),
                            Text(
                              'Go back',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 10),
                          Text('Settings'),
                        ],
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ).then((value) async {
                  if (value == 'reload') {
                    _reloadPage(_selectedIndex);
                  } else if (value == 'back') {
                    await _controllers[_selectedIndex]?.goBack();
                  } else if (value == 'settings') {
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        )
                        .then((_) => _handleSettingsReturn());
                  }
                });
              },
              icon: const Icon(Icons.more_vert_rounded),
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
                  _enabledAiList.length,
                  (index) =>
                      index < _hasBeenLoadedList.length &&
                          _hasBeenLoadedList[index]
                      ? _buildWebView(index)
                      : _buildPlaceholder(index),
                ),
              ),
              if (_selectedIndex < _isLoadingList.length &&
                  _isLoadingList[_selectedIndex] &&
                  _selectedIndex < _errorMessages.length &&
                  _errorMessages[_selectedIndex] == null)
                Positioned.fill(
                  child: LoadingWidget(
                    aiName: _enabledAiList[_selectedIndex]['name'],
                    domain: _currentDomain,
                  ),
                ),
              if (_selectedIndex < _errorMessages.length &&
                  _errorMessages[_selectedIndex] != null &&
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
          enabledAiList: _enabledAiList,
        ),
      ),
    );
  }
}

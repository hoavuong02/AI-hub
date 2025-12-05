import 'package:aihub/screens/settings.dart';
import 'package:aihub/utils/common.dart';
import 'package:aihub/utils/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:share_plus/share_plus.dart';
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
  final List<InAppWebViewController?> _controllers = [];
  final List<String> _currentUrls = [];
  final List<bool> _isLoadingList = [];
  final List<bool> _hasBeenLoadedList = [];
  final List<String?> _errorMessages = [];
  final List<bool> _canGoBackList = [];
  List<Map<String, dynamic>> _enabledAiList = [];
  final DownloadManager _downloadManager = DownloadManager();
  String _currentDomain = name;
  int _defaultFontSize = 16;
  int _selectedIndex = 0;

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
              size: 40,
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
      if (mounted) {
        showSnackBar(
          context,
          Text("Failed to load last opened AI"),
          SnackbarType.error,
        );
      }

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
        _currentDomain = _getBestDomainName(_currentUrls[index]);
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  String _getBestDomainName(String url) {
    final currentDomain = Uri.parse(url).host;
    final aiName = aisDomains[currentDomain];
    return aiName ?? currentDomain;
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
    return switch (policy) {
      HTTPCookieSameSitePolicy.LAX => 'LAX',
      HTTPCookieSameSitePolicy.STRICT => 'STRICT',
      HTTPCookieSameSitePolicy.NONE => 'NONE',
      _ => null,
    };
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

  bool _allowConnectivity(String url) {
    if (url == "about:blank") {
      return true;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    final host = uri.host;
    if (!url.startsWith("https://")) {
      return false;
    }

    bool allowed = false;
    for (String domain in allowedDomains) {
      if (host.endsWith(domain)) {
        allowed = true;
        break;
      }
    }

    if (!allowed) {
      if (host == "login.microsoftonline.com" ||
          host == "accounts.google.com" ||
          host == "appleid.apple.com") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resetChat();
        });
      }
      return false;
    }
    return true;
  }

  void _resetChat() async {
    if (_selectedIndex < _controllers.length &&
        _controllers[_selectedIndex] != null) {
      final controller = _controllers[_selectedIndex]!;

      await InAppWebViewController.clearAllCache();
      await controller.clearHistory();
      await CookieManager.instance().deleteAllCookies();

      final originalUrl = _enabledAiList[_selectedIndex]['url'];
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(originalUrl)),
      );
    }
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
        disableContextMenu: true,
        disableLongPressContextMenuOnLinks: true,
        allowContentAccess: false,
        allowFileAccess: false,
        databaseEnabled: false,
        saveFormData: false,
        geolocationEnabled: false,
        allowFileAccessFromFileURLs: false,
        allowUniversalAccessFromFileURLs: false,
        thirdPartyCookiesEnabled: false,
      ),
      onWebViewCreated: (controller) async {
        controller.addJavaScriptHandler(
          handlerName: 'shareHandler',
          callback: (args) {
            _handleShareData(args[0]);
          },
        );

        if (index < _controllers.length) {
          _controllers[index] = controller;
        }

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
      onLoadStart: (controller, url) async {
        if (index < _isLoadingList.length) {
          setState(() {
            _isLoadingList[index] = true;
            _errorMessages[index] = null;
          });
        }
        if (index == _selectedIndex) {
          setState(() {
            _currentDomain = _getBestDomainName(url.toString());
          });
        }
      },
      onLoadStop: (controller, url) async {
        if (!url.toString().contains('lumo.proton.me')) {
          await controller.evaluateJavascript(source: shareOverrideJS);
        }

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
            _currentDomain = _getBestDomainName(url.toString());
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
            _currentDomain = _getBestDomainName(url.toString());
          });
        }
      },

      shouldInterceptRequest: (controller, request) async {
        final url = request.url.toString();

        final allowed = _allowConnectivity(url);
        if (!allowed) {
          return WebResourceResponse(
            contentType: "text/javascript",
            data: Uint8List(0),
            statusCode: 403,
            reasonPhrase: "Forbidden",
          );
        }

        return null;
      },

      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url.toString();
        final allowed = _allowConnectivity(url);

        if (!allowed) {
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onDownloadStartRequest: (controller, downloadStartRequest) async {
        final url = downloadStartRequest.url.toString();
        bool showNotification = true;
        final fileName =
            downloadStartRequest.suggestedFilename ?? url.split('/').last;

        bool hasPermission = await AwesomeNotifications()
            .isNotificationAllowed();
        if (mounted) {
          if (!hasPermission) {
            showNotification = false;
          }
          await _downloadManager.downloadFile(
            context,
            url,
            fileName,
            showNotification: showNotification,
          );
        }
      },
      onLongPressHitTestResult: (controller, hitTestResult) async {
        if (hitTestResult.type ==
            InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE) {
          final linkUrl = hitTestResult.extra;

          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Open Link",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (linkUrl == null) return;
                      launchLink(
                        Uri.parse(linkUrl),
                        context,
                        Theme.of(context),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Copy Link",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: linkUrl!));
                      showSnackBar(
                        context,
                        Text("Link copied"),
                        SnackbarType.info,
                        icon: Icons.copy_rounded,
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Share Link",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      SharePlus.instance.share(
                        ShareParams(text: linkUrl, title: "Share Link"),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text("Close"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  void _handleBackNavigation() async {
    if (_selectedIndex >= _controllers.length ||
        _controllers[_selectedIndex] == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final canGoBack = await _controllers[_selectedIndex]!.canGoBack();
      if (canGoBack) {
        _controllers[_selectedIndex]!.goBack();
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _handleShareData(dynamic shareData) {
    try {
      String shareText = '';

      if (shareData is Map) {
        final title = shareData['title']?.toString() ?? '';
        final text = shareData['text']?.toString() ?? '';
        final url = shareData['url']?.toString() ?? '';

        if (text.isNotEmpty && url.isNotEmpty) {
          shareText = '$text\n$url';
        } else if (text.isNotEmpty) {
          shareText = text;
        } else if (title.isNotEmpty && url.isNotEmpty) {
          shareText = '$title\n$url';
        } else if (url.isNotEmpty) {
          shareText = url;
        } else {
          shareText = title;
        }
      } else if (shareData is String) {
        shareText = shareData;
      }

      if (shareText.trim().isNotEmpty) {
        SharePlus.instance.share(ShareParams(text: shareText));
      } else {
        if (mounted) {
          showSnackBar(context, Text("No data to share"), SnackbarType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, Text("No data to share"), SnackbarType.error);
      }
    }
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
    int? fontSize = fontSizes[await SharedPrefs.getFontSize()];
    if (fontSize != _defaultFontSize) {
      for (var controller in _controllers) {
        if (controller == null) continue;
        controller.setSettings(
          settings: InAppWebViewSettings(defaultFontSize: fontSize),
        );
      }
    }

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
      canPop:
          _canGoBackList.isNotEmpty && _selectedIndex < _canGoBackList.length
          ? !_canGoBackList[_selectedIndex]
          : true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBackNavigation();
        } else {
          if (mounted) {
            showSnackBar(
              context,
              Text("Press back again to exit"),
              SnackbarType.warning,
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 65,
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 0,
          scrolledUnderElevation: 3,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentDomain,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              if (_selectedIndex < _isLoadingList.length &&
                  _isLoadingList[_selectedIndex])
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedIndex < _errorMessages.length &&
                  _errorMessages[_selectedIndex] != null &&
                  !_isLoadingList[_selectedIndex])
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.error.withValues(alpha: 0.15),
                        theme.colorScheme.error.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Error',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          leading: Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary,
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              style: IconButton.styleFrom(
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.transparent),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                onPressed: () {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      MediaQuery.of(context).size.width - 50,
                      kToolbarHeight + 20,
                      0,
                      0,
                    ),
                    items: [
                      if (_selectedIndex < _hasBeenLoadedList.length &&
                          _hasBeenLoadedList[_selectedIndex] &&
                          !_isLoadingList[_selectedIndex])
                        PopupMenuItem(
                          value: 'reload',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Reload',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_selectedIndex < _canGoBackList.length &&
                          _canGoBackList[_selectedIndex] &&
                          _hasBeenLoadedList[_selectedIndex])
                        PopupMenuItem(
                          value: 'back',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: theme.colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Go Back',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: theme.colorScheme.tertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Settings',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
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
                  child: ExpressiveLoadingWidget(
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

import 'package:flutter/material.dart';

import '../auth/auth_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const green = Color(0xFF00BF4F);
  static const navy = Color(0xFF002C4D);
  static const bodyText = Color(0xFF7D89AA);

  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      imagePath: 'assets/images/1.png',
      title: 'Trouvez les bornes',
      highlightedTitle: 'près de vous',
      description:
          'Repérez rapidement les stations disponibles autour de vous, '
          'comparez la distance et choisissez la meilleure borne pour votre trajet.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/4.png',
      title: 'Réservez votre borne',
      highlightedTitle: 'à l’avance',
      description:
          'Choisissez la borne, sélectionnez un créneau et confirmez votre '
          'réservation en quelques secondes.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/2.png',
      title: 'Suivez votre recharge',
      highlightedTitle: 'en temps réel',
      description:
          'Consultez l’énergie, le coût, la durée et obtenez de l’aide '
          'instantanément directement dans l’application.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await _finishAndNavigate(AuthRoutes.welcome);
  }

  Future<void> _openLogin() async {
    await _finishAndNavigate(AuthRoutes.login);
  }

  Future<void> _finishAndNavigate(String routeName) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await widget.onFinished();
    if (!mounted) return;

    await Navigator.of(context).pushReplacementNamed(routeName);
  }

  Future<void> _nextPage() async {
    if (_currentPage == _pages.length - 1) {
      await _completeOnboarding();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;

            return Padding(
              padding: EdgeInsets.fromLTRB(24, compact ? 4 : 10, 24, 14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 76 : 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: compact ? 122 : 150,
                          height: compact ? 76 : 96,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          right: 0,
                          top: 10,
                          child: TextButton(
                            onPressed: _isFinishing
                                ? null
                                : _completeOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: green,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Passer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemBuilder: (context, index) {
                        return _OnboardingPage(
                          data: _pages[index],
                          compact: compact,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  _PageIndicator(
                    pageCount: _pages.length,
                    currentPage: _currentPage,
                    activeColor: green,
                  ),
                  SizedBox(height: compact ? 14 : 22),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 54 : 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B846), Color(0xFF00CD58)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300BF4F),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _isFinishing ? null : _nextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isFinishing)
                              const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            else ...[
                              Text(
                                _currentPage == _pages.length - 1
                                    ? 'Commencer'
                                    : 'Suivant',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 27,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  TextButton(
                    onPressed: _isFinishing ? null : _openLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: bodyText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Déjà un compte ? ',
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.compact});

  final _OnboardingPageData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 4,
              vertical: compact ? 0 : 4,
            ),
            child: Image.asset(
              data.imagePath,
              width: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 10),
        Text.rich(
          TextSpan(
            text: '${data.title}\n',
            children: [
              TextSpan(
                text: data.highlightedTitle,
                style: const TextStyle(color: _OnboardingScreenState.green),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _OnboardingScreenState.navy,
            fontSize: compact ? 28 : 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            data.description,
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _OnboardingScreenState.bodyText,
              fontSize: compact ? 14 : 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
    required this.activeColor,
  });

  final int pageCount;
  final int currentPage;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final active = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 42 : 28,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFFE7EEF0),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.highlightedTitle,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String highlightedTitle;
  final String description;
}

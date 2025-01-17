import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/core/core.dart';
import 'package:harpy/harpy_widgets/harpy_widgets.dart';
import 'package:harpy/misc/misc.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

/// The [SetupScreen] is shown when a user logged into the app for the first
/// time.
class SetupScreen extends StatefulWidget {
  const SetupScreen();

  static const String route = 'setup';

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final GlobalKey<SlideAnimationState> _slideSetupKey =
      GlobalKey<SlideAnimationState>();

  Future<void> _continue() async {
    unawaited(HapticFeedback.lightImpact());

    // setup completed
    await _slideSetupKey.currentState!.forward();

    app<SetupPreferences>().performedSetup = true;

    app<HarpyNavigator>().pushReplacementNamed(
      HomeScreen.route,
      type: RouteType.fade,
    );
  }

  Widget _buildText() {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: SecondaryHeadline('welcome'),
    );
  }

  Widget _buildUsername(String name) {
    return Center(
      child: PrimaryHeadline(
        name,
        delay: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildThemeSelection(ThemeData theme) {
    return FadeAnimation(
      curve: Curves.easeInOut,
      duration: const Duration(seconds: 1),
      delay: const Duration(milliseconds: 3000),
      child: SlideInAnimation(
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
        offset: const Offset(0, 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('select your theme', style: theme.textTheme.headline4),
            const SizedBox(height: 16),
            const ThemeSelectionCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BounceInAnimation(
        delay: const Duration(milliseconds: 4000),
        child: HarpyButton.flat(
          text: const Text('continue'),
          onTap: _continue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    final authCubit = context.watch<AuthenticationCubit>();

    // the max height constraints for the welcome text and the user name
    final maxTextHeight = mediaQuery.orientation == Orientation.portrait
        ? mediaQuery.size.height / 4
        : mediaQuery.size.height / 6;

    return HarpyBackground(
      child: SlideAnimation(
        key: _slideSetupKey,
        endPosition: Offset(0, -mediaQuery.size.height),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: mediaQuery.padding.top),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxTextHeight),
                      child: _buildText(),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxTextHeight),
                      child: _buildUsername(authCubit.state.user!.name),
                    ),
                    const SizedBox(height: 32),
                    _buildThemeSelection(theme),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
            SizedBox(height: mediaQuery.padding.bottom),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:harpy/components/components.dart';
import 'package:harpy/core/core.dart';
import 'package:harpy/harpy.dart';
import 'package:harpy/harpy_widgets/harpy_widgets.dart';
import 'package:harpy/misc/misc.dart';
import 'package:provider/provider.dart';

/// Used for editing existing custom themes and creating new custom themes.
class CustomThemeScreen extends StatelessWidget {
  const CustomThemeScreen({
    required this.themeData,
    required this.themeId,
  });

  /// The [HarpyThemeData] for the theme customization.
  ///
  /// When creating a new custom theme, this will be initialized with the
  /// currently active theme.
  /// When editing an existing custom theme, this will be set to the custom
  /// theme data.
  final HarpyThemeData themeData;

  /// The id of this custom theme, starting at 10 for the first custom theme.
  ///
  /// When creating a new custom theme, this will be the next available id.
  /// When editing an existing custom theme, this will be the id of the custom
  /// theme.
  final int themeId;

  static const String route = 'custom_theme_screen';

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigCubit>().state;

    return BlocProvider<CustomThemeCubit>(
      create: (_) => CustomThemeCubit(
        initialThemeData: themeData,
        themeId: themeId,
        config: config,
      ),
      child: const _WillPopCustomTheme(
        child: _CustomThemeContent(),
      ),
    );
  }
}

class _CustomThemeContent extends StatelessWidget {
  const _CustomThemeContent();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final config = context.watch<ConfigCubit>().state;
    final cubit = context.watch<CustomThemeCubit>();

    return GestureDetector(
      onTap: () => removeFocus(context),
      child: Theme(
        data: cubit.harpyTheme.themeData,
        child: HarpyScaffold(
          title: 'theme customization',
          backgroundColors: cubit.state.backgroundColors
              .map((color) => Color(color))
              .toList(),
          actions: const [_SaveThemeAction()],
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: config.edgeInsetsSymmetric(vertical: true),
                  children: [
                    if (Harpy.isFree) ...[
                      const CustomThemeProCard(),
                      defaultVerticalSpacer,
                    ],
                    const CustomThemeName(),
                    defaultVerticalSpacer,
                    const CustomThemePrimaryColor(),
                    defaultVerticalSpacer,
                    const CustomThemeSecondaryColor(),
                    defaultVerticalSpacer,
                    const CustomThemeCardColor(),
                    defaultVerticalSpacer,
                    const CustomThemeStatusBarColor(),
                    defaultVerticalSpacer,
                    const CustomThemeNavBarColor(),
                    defaultVerticalSpacer,
                    const CustomThemeBackgroundColors(),
                    SizedBox(height: mediaQuery.padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WillPopCustomTheme extends StatelessWidget {
  const _WillPopCustomTheme({
    required this.child,
  });

  final Widget child;

  Future<bool> _onWillPop(
    BuildContext context, {
    required HarpyTheme harpyTheme,
    required CustomThemeCubit cubit,
  }) async {
    var pop = true;

    if (cubit.modifiedTheme) {
      // ask to discard changes before exiting customization
      final discard = await showDialog<bool>(
        context: context,
        builder: (_) => const HarpyDialog(
          title: Text('discard changes?'),
          actions: [
            DialogAction(
              result: false,
              text: 'cancel',
            ),
            DialogAction(
              result: true,
              text: 'discard',
            ),
          ],
        ),
      );

      pop = discard != null && discard;
    }

    if (pop) {
      updateSystemUi(harpyTheme);
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final harpyTheme = context.watch<HarpyTheme>();
    final cubit = context.watch<CustomThemeCubit>();

    return WillPopScope(
      onWillPop: () => _onWillPop(
        context,
        harpyTheme: harpyTheme,
        cubit: cubit,
      ),
      child: child,
    );
  }
}

class _SaveThemeAction extends StatelessWidget {
  const _SaveThemeAction();

  @override
  Widget build(BuildContext context) {
    final systemBrightness = context.watch<Brightness>();
    final themeBloc = context.watch<ThemeBloc>();
    final cubit = context.watch<CustomThemeCubit>();

    final lightThemeId = app<ThemePreferences>().lightThemeId;
    final darkThemeId = app<ThemePreferences>().darkThemeId;

    final onTap = cubit.canSaveTheme
        ? () {
            themeBloc.add(AddCustomTheme(
              themeData: cubit.state,
              themeId: cubit.themeId,
              changeLightThemeSelection: systemBrightness == Brightness.light ||
                  lightThemeId == darkThemeId,
              changeDarkThemeSelection: systemBrightness == Brightness.dark ||
                  lightThemeId == darkThemeId,
            ));

            Navigator.of(context).pop();
          }
        : null;

    return HarpyButton.flat(
      padding: const EdgeInsets.all(16),
      icon: const Icon(FeatherIcons.check),
      onTap: onTap,
    );
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:loader_overlay/loader_overlay.dart';

wrapFluent({required Widget child}){
  return FluentApp(
    debugShowCheckedModeBanner: false,
    title: 'Pocket Data Desktop Client',
    //themeMode: ThemeMode.dark,
    //darkTheme: FluentThemeData.dark(),
    //theme: FluentThemeData.light(),
    home: FluentTheme(
        data: FluentThemeData(
          brightness: Brightness.light
        ),
        child: LoaderOverlay(
            overlayWidgetBuilder: (_) {
              return ProgressRing();
            },
            overlayWholeScreen: true,
            overlayColor: Colors.grey[200],
            child: child
        )
    ),
  );

}
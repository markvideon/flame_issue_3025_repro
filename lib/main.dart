import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameRoute {
  home,
  play;

  Route get route {
    switch (this) {
      case GameRoute.home:
        return Route(HomePage.new, maintainState: true);
      case GameRoute.play:
        return Route(PlayPage.new, maintainState: true);
    }
  }
}

class RefExampleGame extends FlameGame with RiverpodGameMixin {
  late RouterComponent _router;
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RiverpodAwareTextComponent()..position = Vector2(0, 100));

    final buttonSize = 0.3 * size.x;

    for (final route in GameRoute.values) {
      final idx = GameRoute.values.indexOf(route);

      add(ButtonComponent(
        position: Vector2(idx * (buttonSize + 20), 0),
        onPressed: () {
          _router.pushReplacementNamed(route.name);
        },
        button: RectangleComponent(
            size: Vector2(buttonSize, 100),
            paint: Paint()..color = Colors.red,
            children: [
              TextComponent(
                text: 'Nav to: ${route.name}')
            ]
        ),
      ));
    }

    world.add(
      _router = RouterComponent(
        routes: Map.fromEntries(GameRoute.values.map((e) {
          return MapEntry(e.name, e.route);
        })),
        initialRoute: GameRoute.values.first.name,
      ),
    );
  }
}

class HomePage extends Component
    with HasGameReference<RefExampleGame>, RiverpodComponentMixin {
}

class PlayPage extends Component
    with HasGameReference<RefExampleGame>, RiverpodComponentMixin {
}

// Misc boilerplate from example past this point
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: RiverpodAwareGameWidget(
        key: gameWidgetKey,
        game: gameInstance,
      ),
    );
  }
}

final countingStreamProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (inc) => inc);
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final gameInstance = RefExampleGame();
final GlobalKey<RiverpodAwareGameWidgetState> gameWidgetKey =
GlobalKey<RiverpodAwareGameWidgetState>();

class RiverpodAwareTextComponent extends PositionComponent
    with RiverpodComponentMixin {
  late TextComponent textComponent;
  int currentValue = 0;

  /// [onMount] should be used over [onLoad] to initialize subscriptions,
  /// which is only called if the [Component] was mounted.
  /// Cancellation is handled for the user automatically inside [onRemove].
  ///
  /// [RiverpodComponentMixin.addToGameWidgetBuild] **must** be invoked in
  /// your Component **before** [RiverpodComponentMixin.onMount] in order to
  /// have the provided function invoked on
  /// [RiverpodAwareGameWidgetState.build].
  ///
  /// From `flame_riverpod` 5.0.0, [WidgetRef.watch], is also accessible from
  /// components.
  @override
  void onMount() {
    addToGameWidgetBuild(() {
      ref.listen(countingStreamProvider, (p0, p1) {
        if (p1.hasValue) {
          currentValue = p1.value!;
          textComponent.text = '$currentValue';
        }
      });
    });
    super.onMount();
    add(textComponent = TextComponent(position: position + Vector2(0, 27)));
  }
}

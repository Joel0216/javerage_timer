import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:javerage_timer/features/timer/application/timer_bloc.dart';

/// The `ActionsButtons` class in Dart is a stateless widget that displays different action buttons
/// based on the state of a `TimerBloc` in a Flutter application.
class ActionsButtons extends StatelessWidget {
  const ActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      buildWhen: (prev, state) => prev.runtimeType != state.runtimeType,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...switch (state) {
              TimerInitial() => [
                  FloatingActionButton(
                    onPressed: () => context.read<TimerBloc>().add(
                          TimerStarted(duration: state.duration),
                        ),
                    child: const Icon(Icons.play_arrow),
                  ),
                ],
              TimerTicking() => [
                  FloatingActionButton(
                    onPressed: () =>
                        context.read<TimerBloc>().add(const TimerPaused()),
                    child: const Icon(Icons.pause),
                  ),
                  FloatingActionButton(
                    onPressed: () =>
                        context.read<TimerBloc>().add(const TimerReset()),
                    child: const Icon(Icons.replay),
                  ),
                ],
              TimerFinished() => [
                  FloatingActionButton(
                    onPressed: () =>
                        context.read<TimerBloc>().add(const TimerReset()),
                    child: const Icon(Icons.replay),
                  ),
                ],
            },
          ],
        );
      },
    );
  }
}
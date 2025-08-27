import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum DriverSearchStatus { idle, loading, searching, found, error }

class DriverSearchState {
  final DriverSearchStatus status;
  DriverSearchState({required this.status});
}

class DriverSearchNotifier extends StateNotifier<DriverSearchState> {
  DriverSearchNotifier()
      : super(DriverSearchState(status: DriverSearchStatus.idle));

  Future<void> beginSearch() async {
    // Step 1: loading state
    state = DriverSearchState(status: DriverSearchStatus.loading);

    // Step 2: delay for 2 sec before showing search UI
    await Future.delayed(const Duration(seconds: 2));
    state = DriverSearchState(status: DriverSearchStatus.searching);

    // Step 3: simulate driver search (4 sec)
    await Future.delayed(const Duration(seconds: 4));
    state = DriverSearchState(status: DriverSearchStatus.found);
  }

  void cancelSearch() {
    state = DriverSearchState(status: DriverSearchStatus.idle);
  }
}

final driverSearchProvider =
    StateNotifierProvider<DriverSearchNotifier, DriverSearchState>(
  (ref) => DriverSearchNotifier(),
);

class DriverSearchingScreen extends ConsumerStatefulWidget {
  const DriverSearchingScreen({super.key});

  @override
  ConsumerState<DriverSearchingScreen> createState() =>
      _DriverSearchingScreenState();
}

class _DriverSearchingScreenState
    extends ConsumerState<DriverSearchingScreen> {
  @override
  void initState() {
    super.initState();
    // Begin search on init
    Future.microtask(() {
      ref.read(driverSearchProvider.notifier).beginSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverSearchProvider);
    final notifier = ref.read(driverSearchProvider.notifier);

    // Navigate when driver found
    if (state.status == DriverSearchStatus.found) {
      Future.microtask(() {
        context.go('/tracking'); // update as needed
      });
    }

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: switch (state.status) {
              DriverSearchStatus.loading => Column(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Preparing your ride...",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

              DriverSearchStatus.searching => Column(
                  key: const ValueKey('searching'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 160,
                      width: 160,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple.shade100,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Searching for nearby drivers...",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Hang tight! Finding your best driver...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        notifier.cancelSearch();
                        context.pop();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Cancel Ride"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

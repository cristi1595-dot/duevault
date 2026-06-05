import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import 'home/home_header.dart';
import 'home/financial_bento_card.dart';
import 'home/home_upcoming_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab changes to reset scroll position and show nav bar
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 0) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        ref.read(navBarVisibleProvider.notifier).state = true;
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeHeader(),
            const FinancialBentoCard(),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final delta = notification.scrollDelta ?? 0;
                    if (delta > 2) {
                      // Scrolling down → hide
                      ref.read(navBarVisibleProvider.notifier).state = false;
                    } else if (delta < -2) {
                      // Scrolling up → show
                      ref.read(navBarVisibleProvider.notifier).state = true;
                    }
                  }
                  if (notification is ScrollEndNotification) {
                    // Always show nav bar when user lifts finger
                    ref.read(navBarVisibleProvider.notifier).state = true;
                  }
                  return false;
                },
                child: HomeUpcomingList(scrollController: _scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


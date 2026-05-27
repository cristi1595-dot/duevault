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
    // Listen for tab changes to reset scroll position
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
              child: HomeUpcomingList(scrollController: _scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

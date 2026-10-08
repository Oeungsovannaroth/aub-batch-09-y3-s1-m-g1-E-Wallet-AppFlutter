import 'package:flutter/material.dart';
import 'simulation_screen.dart';

class DepositSimulationScreen extends StatelessWidget {
  const DepositSimulationScreen({super.key});

  @override
  Widget build(BuildContext context) => const SimulationScreen(
    title: 'Cash In',
    button: 'Proceed to Cash In (KHQR)',
    positive: true,
  );
}

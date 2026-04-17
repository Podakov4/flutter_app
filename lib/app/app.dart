import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'router.dart';

class FreethApp extends StatefulWidget {
  const FreethApp({super.key});

  @override
  State<FreethApp> createState() => _FreethAppState();
}

class _FreethAppState extends State<FreethApp> {
  @override
  void initState() {
    super.initState();
    sessionController.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Freeth',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
    );
  }
}
